struct Disconnect <: Packet
    header::UInt8

    Disconnect() = new(DISCONNECT)
end

Base.show(io::IO, x::Disconnect) = print(io, "DISCONNECT")
