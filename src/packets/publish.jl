struct Publish <: Packet
    header::UInt8
    id::UInt16
    message::Message

    Publish(id, message) = new(PUBLISH | ((message.dup & 0x1) << 3) | (message.qos << 1) | message.retain, id, message)
end

function read(s::IO, flags::UInt8, ::Type{Publish})
    dup = (flags & 0x08) >> 3
    qos = (flags & 0x06) >> 1
    retain = (flags & 0x01)
    topic = mqtt_read(s, String)
    if qos != 0x00
        id = mqtt_read(s, UInt16)
    end
    payload = take!(s)
    return Publish(id, Message(dup, qos, retain, topic, payload))
end

function write(s::IO, packet::Publish)
    mqtt_write(s, packet.message.topic)
    if message.qos != 0x00
        mqtt_write(s, id)
    end
    write(s, packet.message.payload)
end

Base.show(io::IO, x::Publish) = print(io, "PUBLISH[]")
