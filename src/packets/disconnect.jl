struct Disconnect <: Packet
    header::UInt8
end
Disconnect() = Disconnect(DISCONNECT)
Base.show(io::IO, x::Disconnect) = print(io, "disconnect")
