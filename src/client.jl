using Base.Threads

struct MQTTException <: Exception
    msg::AbstractString
end

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

    last_id::UInt16
    in_flight::Dict{UInt16, Future}
    queue::Channel{Tuple{Packet, Future}}
    io::IO
    last_sent::Atomic{Float64}
    last_received::Atomic{Float64}
    ping_outstanding::Atomic{UInt16}
    connect_packet::Connect
    keep_alive_timer::Timer
    disconnecting::Atomic{UInt8}

    Client(on_msg::Function, on_disconnect::Function, ping_timeout::Int64) = new(
    on_msg,
    on_disconnect,
    ping_timeout,
    0x0000,
    Dict{UInt16, Future}(),
    Channel{Tuple{Packet, Future}}(60),
    TCPSocket(),
    Atomic{Float64}(),
    Atomic{Float64}(),
    Atomic{UInt16}(),
    Connect(),
    Timer(0, 0),
    Atomic{UInt8}(0x00))
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

function get(future)
    r = fetch(future)
    if typeof(r) <: Exception
        throw(r)
    end
    return r
end

function send_packet(c::Client, packet::Packet)
    future = Future()
    put!(c.queue, (packet, future))
    return future
end

function connect(c::Client)
    c.in_flight = Dict{UInt16, Future}()
    c.queue = Channel{Tuple{Packet, Future}}(c.queue.sz_max)
    @schedule out_loop(c)
    @schedule in_loop(c)
    if c.connect_packet.keep_alive > 0x0000
        c.keep_alive_timer = keep_alive_timer(c)
    end
    get(send_packet(c, c.connect_packet))
end

function disconnect(c::Client, reason=nothing)
    # ignore errors while disconnecting
    if c.disconnecting[] == 0x00
        atomic_xchg!(c.disconnecting, 0x01)
        close(c.keep_alive_timer)
        if !(typeof(reason) <: Exception)
            get(send_packet(c, Disconnect()))
        end
        close(c.queue)
        close(c.io)
        c.on_disconnect(reason)
    end
end

function in_loop(c::Client)
    println("in loop started")
    try
        while true
            packet = read_packet(c.io)
            atomic_xchg!(c.last_received, time())
            println("<- ", packet)
            handle(c, packet)
        end
    catch e
        if isa(e, EOFError)
            e = MQTTException("connection lost")
        end
        disconnect(c, e)
    end
    println("in loop stopped")
end

function out_loop(c::Client)
    println("out loop started")
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
            println("-> ", packet)
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
    println("out loop stopped")
end

function keep_alive_timer(c::Client)
    check_interval = (c.connect_packet.keep_alive > 10) ? 5 : c.connect_packet.keep_alive / 2
    t = Timer(0, check_interval)
    waiter = Task(function()
    println("keep alive loop started")
    while isopen(t)
        keep_alive(c)
        try
            wait(t)
        catch e
            isa(e, EOFError) || rethrow(exc)
        end
    end
    println("keep alive loop stopped")
end)
yield(waiter)
return t
end

function keep_alive(c::Client)
    keep_alive = c.connect_packet.keep_alive
    now = time()
    if c.ping_outstanding[] == 0x00
        if now - c.last_sent[] >= keep_alive || now - c.last_received[] >= keep_alive
            get(send_packet(c, Pingreq()))
            atomic_add!(c.ping_outstanding, 0x0001)
        end
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
        send_packet(c, Puback(packet.id))
    elseif packet.message.qos == EXACTLY_ONCE
        send_packet(c, Pubrec(packet.id))
    end
    @schedule c.on_msg(packet.message.topic, packet.message.payload)
end

function handle(c::Client, packet::Pubrec)
    send_packet(c, Pubrel(packet.id))
end

function handle(c::Client, packet::Pubrel)
    send_packet(c, Pubcomp(packet.id))
end

function handle(c::Client, packet::Pingresp)
    atomic_sub!(c.ping_outstanding, 0x0001)
end

function connect_async(c::Client, host::AbstractString, port::Integer=1883;
    io::IO=connect(host, port),
    clean_session::Bool=true,
    keep_alive::UInt16=0x0000,
    client_id::String="",
    will::Nullable{Message}=Nullable{Message}(),
    username::Nullable{String}=Nullable{String}(),
    password::Nullable{Array{UInt8}}=Nullable{Array{UInt8}}())
    c.io = io
    c.connect_packet = Connect(clean_session, keep_alive, client_id, will, username, password)
    connect(c)
end

function connect(c::Client, host::AbstractString, port::Integer=1883;
    io::IO=connect(host, port),
    clean_session::Bool=true,
    keep_alive::UInt16=0x0000,
    client_id::String="",
    will::Nullable{Message}=Nullable{Message}(),
    username::Nullable{String}=Nullable{String}(),
    password::Nullable{Array{UInt8}}=Nullable{Array{UInt8}}())
    get(connect_async(c, host, port, io=io, clean_session=clean_session,
    keep_alive=keep_alive, client_id=client_id, will=will, username=username, password=password))
end

subscribe_async(c::Client, topics::Topic...) = send_packet(c, Subscribe(collect(topics)))
subscribe(c::Client, topics::Topic...) = get(subscribe_async(c, topics...))

unsubscribe_async(c::Client, topics::String...) = send_packet(c, Unsubscribe(collect(topics)))
unsubscribe(c::Client, topics::String...) = get(unsubscribe_async(c, topics...))

publish_async(c::Client, topic::String, payload::Array{UInt8};
qos::QOS=AT_MOST_ONCE, retain::Bool=false) = send_packet(c, Publish(Message(false, qos, retain, topic, payload)))
publish(c::Client, topic::String, payload::Array{UInt8};
qos::QOS=AT_MOST_ONCE, retain::Bool=false) = get(publish_async(c, topic, payload, qos=qos, retain=retain))
