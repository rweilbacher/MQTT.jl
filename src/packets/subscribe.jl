struct Subscribe <: Packet
    header::UInt8

    Subscribe() = new(SUBSCRIBE)
end

function write(s::IO, packet::Subscribe)
end

Base.show(io::IO, x::Subscribe) = print(io, "SUBSCRIBE[]")

struct Suback <: Ack
    header::UInt8
    id::UInt16

    Suback(id) = new(SUBACK, id)
end

Base.show(io::IO, x::Suback) = print(io, "SUBACK[id: ", x.id, "]")
