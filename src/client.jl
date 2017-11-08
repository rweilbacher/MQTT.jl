import Base.connect

# commands
const CONNECT = 0x10
const CONNACK = 0x20
const PUBLISH = 0x30
const PUBACK = 0x40
const PUBREC = 0x50
const PUBREL = 0x60
const PUBCOMP = 0x70
const SUBSCRIBE = 0x80
const SUBACK = 0x90
const UNSUBSCRIBE = 0xA0
const UNSUBACK = 0xB0
const PINGREQ = 0xC0
const PINGRESP = 0xD0
const DISCONNECT = 0xE0

# connect return code
const CONNECTION_ACCEPTED = 0x00
const CONNECTION_REFUSED_UNACCEPTABLE_PROTOCOL_VERSION = 0x01
const CONNECTION_REFUSED_IDENTIFIER_REJECTED = 0x02
const CONNECTION_REFUSED_SERVER_UNAVAILABLE = 0x03
const CONNECTION_REFUSED_BAD_USER_NAME_OR_PASSWORD = 0x04
const CONNECTION_REFUSED_NOT_AUTHORIZED = 0x05

struct MQTTException <: Exception
    msg::AbstractString
end

struct Packet
    cmd::UInt8
    data::Any
end

mutable struct Client
    on_msg::Function
    keep_alive::UInt16

    # TODO mutex?
    last_id::UInt16
    in_flight::Dict{UInt16, Future}

    write_packets::Channel{Packet}
    socket

    Client(on_msg) = new(
    on_msg,
    0x0000,
    0x0000,
    Dict{UInt16, Future}(),
    Channel{Packet}(60),
    TCPSocket())
end

const CONNACK_STRINGS = [
"connection refused unacceptable protocol version",
"connection refused identifier rejected",
"connection refused server unavailable",
"connection refused bad user name or password",
"connection refused not authorized",
]

function handle_connack(client::Client, s::IO, cmd::UInt8, flags::UInt8)
    session_present = read(s, UInt8)
    return_code = read(s, UInt8)

    future = client.in_flight[0x0000]
    if return_code == CONNECTION_ACCEPTED
        put!(future, session_present)
    else
        try
            put!(future, MQTTException(CONNACK_STRINGS[return_code]))
        catch e
            if isa(e, BoundsError)
                put!(future, MQTTException("unkown return code [" + return_code + "]"))
                # TODO close connection
            else
                rethrow()
            end
        end
    end
end

function handle_publish(client::Client, s::IO, cmd::UInt8, flags::UInt8)
    dup = (flags & 0x08) >> 3
    qos = (flags & 0x06) >> 1
    retain = (flags & 0x01)

    topic = mqtt_read(s, String)

    if qos == 0x01
        id = mqtt_read(s, UInt16)
        write_packet(client, PUBACK, id)
    end

    if qos == 0x02
        id = mqtt_read(s, UInt16)
        write_packet(client, PUBREC, id)
    end

    payload = take!(s)
    @schedule client.on_msg(topic, payload)
end

function handle_ack(client::Client, s::IO, cmd::UInt8, flags::UInt8)
    id = mqtt_read(s, UInt16)
    put!(client.in_flight[id], nothing)
end

function handle_pubrecrel(client::Client, s::IO, cmd::UInt8, flags::UInt8)
    id = mqtt_read(s, UInt16)
    write_packet(client, cmd + 1, id)
end

function handle_suback(client::Client, s::IO, cmd::UInt8, flags::UInt8)
    id = mqtt_read(s, UInt16)
    return_codes = take!(s)
    put!(client.in_flight[id], return_codes)
end

function handle_pingreq(client::Client, s::IO, cmd::UInt8, flags::UInt8)
    # TODO
end

function handle_pingresp(client::Client, s::IO, cmd::UInt8, flags::UInt8)
    # TODO
end

const handlers = Dict{UInt8, Function}(
CONNACK => handle_connack,
PUBLISH => handle_publish,
PUBACK => handle_ack,
PUBREC => handle_pubrecrel,
PUBREL => handle_pubrecrel,
PUBCOMP => handle_ack,
SUBACK => handle_suback,
UNSUBACK => handle_ack,
PINGREQ => handle_pingreq,
PINGRESP => handle_pingresp
)

# TODO needs mutex
function packet_id(client)
    if client.last_id == typemax(UInt16)
        client.last_id = 0
    end
    client.last_id += 1
    return client.last_id
end

function write_loop(client)
    try
        while true
            packet = take!(client.write_packets)
            buffer = PipeBuffer()
            for i in packet.data
                mqtt_write(buffer, i)
            end
            data = take!(buffer)
            write(client.socket, packet.cmd)
            write_len(client.socket, length(data))
            write(client.socket, data)
        end
    catch e
        if isa(e, InvalidStateException)
            info("write loop stopped '", e.msg, "'")
        else
            rethrow()
        end
    end
end

function read_loop(client)
    try
        while true
            cmd_flags = read(client.socket, UInt8)
            len = read_len(client.socket)
            data = read(client.socket, len)
            buffer = PipeBuffer(data)
            cmd = cmd_flags & 0xF0
            flags = cmd_flags & 0x0F
            # TODO check contains
            # TODO handle errors
            handlers[cmd](client, buffer, cmd, flags)
        end
    catch e
        if isa(e, EOFError)
            info("read loop stopped")
        else
            rethrow()
        end
    end
end

function ping_loop(client::Client)
    while true
        # sleep(client.keep_alive)
        # TODO ping
    end
end

function write_packet(client::Client, cmd::UInt8, data...)
    put!(client.write_packets, Packet(cmd, data))
end

# the docs make it sound like fetch would alrdy work in this way
# check julia sources
function get(future)
    r = fetch(future)
    if typeof(r) <: Exception
        throw(r)
    end
    return r
end

struct User
    name::String
    password::String
end

function connect(client::Client, host::AbstractString, port::Integer=1883;
    keep_alive::UInt16=0x0000,
    client_id::String=randstring(8),
    user::User=User("", ""),
    will::Tuple{String, Array{UInt8}, UInt8, Bool}=("", Array{UInt8}(), 0x00, false),
    clean_session::Bool=true)

    client.socket = connect(host, port)
    @schedule write_loop(client)
    @schedule read_loop(client)

    protocol_name = "MQTT"
    protocol_level = 0x04
    connect_flags = 0x02 # clean session

    optional = ()

    if length(will[1]) > 0
        # TODO
    end

    future = Future()
    client.in_flight[0x0000] = future

    write_packet(client, CONNECT,
    protocol_name,
    protocol_level,
    connect_flags,
    client.keep_alive,
    client_id,
    optional...)

    get(future)

    info("connected to ", host, ":", port)
end

function disconnect_async(client)
    write_packet(client, DISCONNECT)

    close(client.write_packets)

    #TODO maybe close socketß
end

function disconnect(client)
    disconnect_async(client)

    wait(client.socket.closenotify)
    # TODO maybe close ourselves after timeout?
    close(client.socket)
    info("disconnected")
end

function subscribe_async(client, topics...)
    future = Future()
    id = packet_id(client)
    client.in_flight[id] = future

    write_packet(client, SUBSCRIBE | 0x02, id, topics...)

    return future
end

# TODO change topics to Tuple{String, UInt8}
function subscribe(client, topics...)
    future = subscribe_async(client, topics...)

    granted = get(future)

    result = collect(topics)
    for (i, v) in enumerate(granted)
        if i % 2 == 0
            result[i * 2] = v
        end
    end

    info("subscribed to ", result)
end

function unsubscribe_async(client, topics...)
    future = Future()
    id = packet_id(client)
    client.in_flight[id] = future

    write_packet(client, UNSUBSCRIBE | 0x02, id, topics...)

    return future
end

function unsubscribe(client, topics...)
    future = unsubscribe_async(client, topics...)

    get(future)

    info("unsubscribed from ", topics)
end

#TODO make parameters easier to use. For example no b"QOS_1"
function publish(client::Client, topic::String, payload...;
    dup::Bool=false,
    qos::UInt8=0x00,
    retain::Bool=false)

    buffer = PipeBuffer()
    for i in payload
        write(buffer, i)
    end
    encoded_payload = take!(buffer)

    future = publish(client, topic, encoded_payload, dup, qos, retain)

    get(future)
end

#TODO make parameters easier to use. For example no b"QOS_1"
function publish_async(client::Client, topic::String, payload...;
    dup::Bool=false,
    qos::UInt8=0x00,
    retain::Bool=false)

    buffer = PipeBuffer()
    for i in payload
        write(buffer, i)
    end
    encoded_payload = take!(buffer)

    publish(client, topic, encoded_payload, dup, qos, retain)
end

function publish(client::Client, topic::String, payload::Array{UInt8},
    dup::Bool, qos::UInt8, retain::Bool)

    future = Future()
    optional = ()
    if qos == 0x00
        put!(future, nothing)
    elseif qos == 0x01 || qos == 0x02
        future = Future()
        id = packet_id(client)
        client.in_flight[id] = future
        optional = (id)
    else
        throw(MQTTException("invalid qos"))
    end
    cmd = PUBLISH | ((dup & 0x1) << 3) | (qos << 1) | retain
    write_packet(client, cmd, topic, optional..., payload)
    return future
end
