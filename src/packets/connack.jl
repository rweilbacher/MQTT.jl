struct Connack <: Packet
    header::UInt8
    session_present::Bool
    return_code::UInt8

    Connack(session_present::Bool, return_code::UInt8) = new(CONNACK, session_present, return_code)
end

function read(s::IO, flags::UInt8, ::Type{Connack})
    session_present = read(s, UInt8)
    return_code = read(s, UInt8)
    return Connack(convert(Bool, session_present), return_code)
end

function handle(packet::Connack)
end

Base.show(io::IO, x::Connack) = print(io, "CONNACK[session_present: ", x.session_present, ", return_code: ", x.return_code ,"]")
