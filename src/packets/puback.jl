struct Puback <: Ack
    header::UInt8
    id::UInt16

    Puback(id) = new(PUBACK, id)
end

Base.show(io::IO, x::Puback) = print(io, "PUBACK[id: ", x.id, "]")

struct Pubrec <: Ack
    header::UInt8
    id::UInt16

    Pubrec(id) = new(PUBREC, id)
end

Base.show(io::IO, x::Pubrec) = print(io, "PUBREC[id: ", x.id, "]")

struct Pubrel <: Ack
    header::UInt8
    id::UInt16

    Pubrel(id) = new(PUBREL, id)
end

Base.show(io::IO, x::Pubrel) = print(io, "PUBREL[id: ", x.id, "]")

struct Pubcomp <: Ack
    header::UInt8
    id::UInt16

    Pubcomp(id) = new(PUBCOMP, id)
end

Base.show(io::IO, x::Pubcomp) = print(io, "PUBCOMP[id: ", x.id, "]")
