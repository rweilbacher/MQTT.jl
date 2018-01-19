struct Pingreq <: Packet
    header::UInt8

    Pingreq() = new(PINGREQ)
end

Base.show(io::IO, x::Pingreq) = print(io, "PINGREQ")

struct Pingresp <: Packet
    header::UInt8

    Pingresp() = new(PINGRESP)
end

Base.show(io::IO, x::Pingresp) = print(io, "PINGRESP")
