import Base: read, write

@enum(PacketType::UInt8,
CONNECT = 0x10,
CONNACK = 0x20,
PUBLISH = 0x30,
PUBACK = 0x40,
PUBREC = 0x50,
PUBREL = 0x60,
PUBCOMP = 0x70,
SUBSCRIBE = 0x80,
SUBACK = 0x90,
UNSUBSCRIBE = 0xA0,
UNSUBACK = 0xB0,
PINGREQ = 0xC0,
PINGRESP = 0xD0,
DISCONNECT = 0xE0
)

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

include("packets/connect.jl")
include("packets/connack.jl")
include("packets/publish.jl")
include("packets/puback.jl")
include("packets/subscribe.jl")
include("packets/unsubscribe.jl")
include("packets/disconnect.jl")

const PACKET_TYPES = Dict{PacketType, Type}(
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
    # TODO seperate
    packet = read(buffer, flags, PACKET_TYPES[convert(PacketType, packet_type)])
    println("<- ", packet)
    return packet
end

function write_packet(s::IO, packet::Packet)
    buffer = PipeBuffer()
    write(buffer, packet)
    data = take!(buffer)
    write(s, packet.header)
    write_len(s, length(data))
    write(s, data)
    println("-> ", packet)
end
