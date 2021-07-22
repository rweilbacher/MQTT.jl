struct Unsubscribe <: HasId
    header::UInt8
    id::UInt16
    topics::Array{String}
end
Unsubscribe(topics::Array{String}) = Unsubscribe(convert(UInt8, UNSUBSCRIBE) | 0x02, 0x0000, topics)
Unsubscribe(packet::Unsubscribe, id::UInt16) = Unsubscribe(packet.header, id, packet.topics)

function write(s::IO, packet::Unsubscribe)
    mqtt_write(s, packet.id)
    for topic in packet.topics
        mqtt_write(s, topic)
    end
end

Base.show(io::IO, x::Unsubscribe) = print(io, "unsubscribe[id: ", x.id, ", topics: ", join(x.topics, ", "), "]")

struct Unsuback <: Ack
    header::UInt8
    id::UInt16
end
Unsuback(id) = Unsuback(UNSUBACK, id)
Base.show(io::IO, x::Unsuback) = print(io, "unsuback[id: ", x.id, "]")
