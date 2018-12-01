@enum(QOS::UInt8,
AT_MOST_ONCE = 0x00,
AT_LEAST_ONCE = 0x01,
EXACTLY_ONCE = 0x02)

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
DISCONNECT = 0xE0)

abstract type Packet end
function write(s::IO, packet::Packet) end
read(s::IO, flags::UInt8, t::Type{<: Packet}) = t()
has_id(packet::Packet) = false
needs_id(packet::Packet) = false

abstract type HasId <: Packet end
has_id(packet::HasId) = true
needs_id(packet::HasId) = true

abstract type Ack <: HasId end
write(s::IO, packet::Ack) = mqtt_write(s, packet.id)
read(s::IO, flags::UInt8, t::Type{<: Ack}) = t(mqtt_read(s, UInt16))
needs_id(packet::Ack) = false

struct Message
    dup::Bool
    qos::QOS
    retain::Bool
    topic::String
    payload::Array{UInt8}
end
Base.show(io::IO, x::Message) = print(io, "[dup: ", x.dup,
    ", qos: ", x.qos, ", retain: ", x.retain, ", topic: ", x.topic, "]")
