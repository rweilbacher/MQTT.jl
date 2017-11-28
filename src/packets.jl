import Base: read, write

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

abstract type Packet end

abstract type Ack <: Packet end

function write(s::IO, packet::Packet) end

function write(s::IO, packet::Ack)
    mqtt_write(s, packet.id)
end

function read(s::IO, flags::UInt8, t::Type{Ack})
    id = mqtt_read(s, UInt16)
    return t(0x00, id)
end

struct Message
    dup::Bool
    qos::UInt8
    retain::Bool
    topic::String
    payload::Array{UInt8}
end

include("utils.jl")
include("packets/connect.jl")
include("packets/connack.jl")
include("packets/publish.jl")
include("packets/puback.jl")
include("packets/subscribe.jl")
include("packets/unsubscribe.jl")
include("packets/disconnect.jl")

const PACKET_TYPES = Dict{UInt8, Type}(
CONNACK => Connack,
PUBLISH => Publish,
PUBACK => Puback,
PUBREC => Pubrec,
PUBREL => Pubrel,
PUBCOMP => Pubcomp,
SUBACK => Suback,
UNSUBACK => Unsuback,
#PINGRESP => Pingresp
)

function read_packet(s::IO)
    header = read(s, UInt8)
    len = read_len(s)
    # read variable header and payload into buffer
    buffer = PipeBuffer(read(s, len))
    packet_type = header & 0xF0
    flags = header & 0x0F
    packet = read(buffer, flags, PACKET_TYPES[packet_type])
    println("<- ", packet)
    return packet
end

function write_packet(s::IO, packet::Packet)
    buffer = PipeBuffer()
    write(buffer, packet)
    data = take!(buffer)
    write(socket, packet.header)
    write_len(socket, length(data))
    write(socket, data)
    println("-> ", packet)
end
