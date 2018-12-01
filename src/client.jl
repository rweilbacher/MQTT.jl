using Base.Threads

struct MQTTException <: Exception
    msg::AbstractString
end

"""
    ConnectOpts(host, port=1883)
Create a `ConnectOpts` using the given broker and default options.
"""
mutable struct ConnectOpts
    clean_session::Bool
    keep_alive::UInt16
    client_id::String
    will::Nullable{Message}
    username::Nullable{String}
    password::Nullable{Array{UInt8}}
    get_io::Function
end
ConnectOpts(get_io::Function) = ConnectOpts(true, 0x0000, "", Nullable{Message}(), Nullable{String}(), Nullable{Array{UInt8}}(), get_io)
ConnectOpts(host::AbstractString, port::Integer=1883) = ConnectOpts(() -> connect(host, port))
ConnectOpts() = ConnectOpts(() -> TCPSocket())

const CONNACK_ERRORS = [
"connection refused unacceptable protocol version",
"connection refused identifier rejected",
"connection refused server unavailable",
"connection refused bad user name or password",
"connection refused not authorized"]

mutable struct Client
    on_msg::Function
    on_disconnect::Function
    ping_timeout::Int64
    opts::ConnectOpts
    last_id::UInt16
    in_flight::Dict{UInt16, Future}
    queue::Channel{Tuple{Packet, Future}}
    disconnecting::Atomic{UInt8}
    last_sent::Atomic{Float64}
    last_received::Atomic{Float64}
    ping_outstanding::Atomic{UInt16}
    keep_alive_timer::Timer
    io::IO

    Client(on_msg::Function, on_disconnect::Function, ping_timeout::Int64) = new(
    on_msg,
    on_disconnect,
    ping_timeout,
    ConnectOpts(),
    0x0000,
    Dict{UInt16, Future}(),
    Channel{Tuple{Packet, Future}}(60),
    Atomic{UInt8}(0x00),
    Atomic{Float64}(),
    Atomic{Float64}(),
    Atomic{UInt16}(),
    Timer(0, 0),
    TCPSocket())
end

function packet_id(c::Client)
    if c.last_id == typemax(UInt16)
        c.last_id = 0
    end
    c.last_id += 1
    return c.last_id
end

function complete(c::Client, id::UInt16, value=nothing)
    if haskey(c.in_flight, id)
        future = c.in_flight[id]
        put!(future, value)
        delete!(c.in_flight, id)
    else
        disconnect(c, MQTTException("protocol error"))
    end
end

"""
    get(future)

Connects the `Client` instance using the given options.
"""
function get(future::Future)
    r = fetch(future)
    if typeof(r) <: Exception
        throw(r)
    end
    return r
end

function send_packet(c::Client, packet::Packet, async::Bool=false)
    future = Future()
    put!(c.queue, (packet, future))
    if async
        return future
    else
        get(future)
    end
end

function in_loop(c::Client)
    println("in started")
    try
        while true
            packet = read_packet(c.io)
            atomic_xchg!(c.last_received, time())
            println("in ", packet)
            handle(c, packet)
        end
    catch e
        if isa(e, EOFError)
            e = MQTTException("connection lost")
        end
        disconnect(c, e)
    end
    println("in stopped")
end

function out_loop(c::Client)
    println("out started")
    try
        while true
            packet, future = take!(c.queue)
            # generate ids for packets that need one
            if needs_id(packet)
                id = packet_id(c)
                packet = typeof(packet)(packet, id)
            end
            # add the futures of packets that need acknowledgment to in flight
            if has_id(packet)
                c.in_flight[packet.id] = future
            end
            atomic_xchg!(c.last_sent, time())
            write_packet(c.io, packet)
            println("out ", packet)
            # complete the futures of packets that don't need acknowledgment
            if !has_id(packet)
                put!(future, 0)
            end
        end
    catch e
        if isa(e, ArgumentError)
            e = MQTTException("connection lost")
        end
        disconnect(c, e)
    end
    println("out stopped")
end

function keep_alive_timer(c::Client)
    check_interval = (c.opts.keep_alive > 10) ? 5 : c.opts.keep_alive / 2
    t = Timer(0, check_interval)
    waiter = Task(function()
    println("keep alive started")
    while isopen(t)
        keep_alive(c)
        try
            wait(t)
        catch e
            isa(e, EOFError) || rethrow(exc)
        end
    end
    println("keep alive stopped")
end)
yield(waiter)
return t
end

function keep_alive(c::Client)
    keep_alive = c.opts.keep_alive
    now = time()
    if c.ping_outstanding[] == 0x00
        if now - c.last_sent[] >= keep_alive || now - c.last_received[] >= keep_alive
            send_packet(c, Pingreq())
            atomic_add!(c.ping_outstanding, 0x0001)
        end
    elseif c.ping_outstanding[] < 0x00
        disconnect(c, MQTTException("protocol error"))
    else
        if now - c.last_received[] >= c.ping_timeout
            disconnect(c, MQTTException("ping timed out"))
        end
    end
end

function handle(c::Client, packet::Ack)
    complete(c, packet.id)
end

function handle(c::Client, packet::Connack)
    r = packet.session_present
    if packet.return_code != 0
        r = ErrorException(CONNACK_ERRORS[packet.return_code])
    end
    complete(c, 0x0000, r)
end

function handle(c::Client, packet::Publish)
    if packet.message.qos == AT_LEAST_ONCE
        send_packet(c, Puback(packet.id), true)
    elseif packet.message.qos == EXACTLY_ONCE
        send_packet(c, Pubrec(packet.id), true)
    end
    @schedule c.on_msg(packet.message.topic, packet.message.payload)
end

function handle(c::Client, packet::Pubrec)
    send_packet(c, Pubrel(packet.id), true)
end

function handle(c::Client, packet::Pubrel)
    send_packet(c, Pubcomp(packet.id), true)
end

function handle(c::Client, packet::Pingresp)
    atomic_sub!(c.ping_outstanding, 0x0001)
end

"""
    connect(client, opts, [async=false])

Connects to a broker using the specified options.

If `async` is `true` a `Future` is returned. Otherwise the function blocks till the operation is completed.

See also [`get`](@ref).
"""
function connect(client::Client, opts::ConnectOpts; async::Bool=false)
    client.opts = opts
    client.io = opts.get_io()

    client.in_flight = Dict{UInt16, Future}()
    client.queue = Channel{Tuple{Packet, Future}}(client.queue.sz_max)
    atomic_xchg!(client.disconnecting, 0x00)

    @schedule out_loop(client)
    @schedule in_loop(client)
    if client.opts.keep_alive > 0x0000
        client.keep_alive_timer = keep_alive_timer(client)
    end

    send_packet(client, Connect(opts.clean_session, opts.keep_alive, opts.client_id, opts.will, opts.username, opts.password), async)
end

function disconnect(client::Client, reason::Union{Exception,Void}=nothing)
    # ignore errors while disconnecting
    if client.disconnecting[] == 0x00
        atomic_xchg!(client.disconnecting, 0x01)
        close(client.keep_alive_timer)
        if !(typeof(reason) <: Exception)
            send_packet(client, Disconnect())
        end
        close(client.queue)
        close(client.io)
        client.on_disconnect(reason)
    end
end

function subscribe(client::Client, topics::Topic...; async::Bool=false)
    send_packet(client, Subscribe(collect(topics)), async)
end

function unsubscribe(client::Client, topics::String...; async::Bool=false)
    send_packet(client, Unsubscribe(collect(topics)), async)
end

function publish(client::Client, topic::String, payload::Array{UInt8};
    async::Bool=false, qos::QOS=AT_MOST_ONCE, retain::Bool=false)
    send_packet(client, Publish(Message(false, qos, retain, topic, payload)), async)
end

publish(client::Client, topic::String, payload::String;
    async::Bool=false,
    qos::QOS=AT_MOST_ONCE,
    retain::Bool=false) = publish(client, topic, convert(Array{UInt8}, payload), async=async, qos=qos, retain=retain)
