struct Unsubscribe <: Packet
    header::UInt8

    Unsubscribe() = new(UNSUBSCRIBE)
end

function write(s::IO, packet::Unsubscribe)
end

Base.show(io::IO, x::Unsubscribe) = print(io, "UNSUBSCRIBE[]")

struct Unsuback <: Ack
    header::UInt8
    id::UInt16

    Unsuback(id) = new(UNSUBACK, id)
end

Base.show(io::IO, x::Unsuback) = print(io, "UNSUBACK[id: ", x.id, "]")
