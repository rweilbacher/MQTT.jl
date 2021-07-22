Topic = Tuple{String, QOS}
Base.show(io::IO, x::Topic) = print(io, "(", join(x, ", "), ")")

struct Subscribe <: HasId
    header::UInt8
    id::UInt16
    topics::Array{Topic}
end
Subscribe(topics::Array{Topic}) = Subscribe(convert(UInt8, SUBSCRIBE) | 0x02, 0x0000, topics)
Subscribe(packet::Subscribe, id::UInt16) = Subscribe(packet.header, id, packet.topics)

function write(s::IO, packet::Subscribe)
    mqtt_write(s, packet.id)
    for topic in packet.topics
        for i in topic
            mqtt_write(s, i)
        end
    end
end

Base.show(io::IO, x::Subscribe) = print(io, "subscribe[id: ", x.id, ", topics: ", join(x.topics, ", "), "]")

struct Suback <: Ack
    header::UInt8
    id::UInt16
end
Suback(id) = Suback(SUBACK, id)
Base.show(io::IO, x::Suback) = print(io, "suback[id: ", x.id, "]")
