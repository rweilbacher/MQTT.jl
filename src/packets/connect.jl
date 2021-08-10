struct Connect <: Packet
    header::UInt8
    protocol_name::String
    protocol_level::UInt8
    clean_session::Bool
    keep_alive::UInt16
    client_id::String
    will::Union{Message,Nothing}
    username::Union{String,Nothing}
    password::Union{Array{UInt8},Nothing}
    id::UInt16
end
Connect(clean_session::Bool, keep_alive::UInt16, client_id::String, will::Union{Message,Nothing}, username::Union{String,Nothing}, password::Union{Array{UInt8},Nothing}) = Connect(CONNECT, "MQTT", 0x04, clean_session, keep_alive, client_id, will, username, password, 0)

function write(s::IO, packet::Connect)
    mqtt_write(s, packet.protocol_name)
    mqtt_write(s, packet.protocol_level)
    clean_session_flag = UInt8(packet.clean_session) << 1
    will = packet.will
    will_flag = UInt8(!isnothing(will)) << 2
    will_qos = (isnothing(will) ? 0x00 : UInt8(will.qos)) << 3
    will_retain = (isnothing(will) ? 0x00 : UInt8(will.retain)) << 5
    username_flag = UInt8(!isnothing(packet.username)) << 6
    password_flag = UInt8(!isnothing(packet.password)) << 7
    connect_flags = clean_session_flag | will_flag | will_qos | will_retain | username_flag | password_flag
    mqtt_write(s, connect_flags)
    mqtt_write(s, packet.keep_alive)
    mqtt_write(s, packet.client_id)
    if !isnothing(packet.will)
        mqtt_write(s, will.topic)
        mqtt_write(s, will.payload)
    end
    if !isnothing(packet.username)
        mqtt_write(s, packet.username)
    end
    if !isnothing(packet.password)
        mqtt_write(s, packet.password)
    end
end

has_id(packet::Connect) = true

Base.show(io::IO, x::Connect) = print(io, "connect[protocol_name: '", x.protocol_name, "'",
", protocol_level: ", x.protocol_level,
", clean_session: ", x.clean_session,
", keep_alive: ", x.keep_alive,
", client_id: '", x.client_id, "'",
", will: ", ifelse(isnothing(x.will), "(none)", x.will),
", username: ", ifelse(isnothing(x.username), "(none)", x.username),
", password: ", ifelse(isnothing(x.password), "(none)", x.password), "]")

struct Connack <: Packet
    header::UInt8
    session_present::Bool
    return_code::UInt8
end
Connack(session_present::Bool, return_code::UInt8) = Connack(CONNACK, session_present, return_code)

function read(s::IO, flags::UInt8, ::Type{Connack})
    session_present = read(s, UInt8)
    return_code = read(s, UInt8)
    return Connack(Bool(session_present), return_code)
end

Base.show(io::IO, x::Connack) = print(io, "connack[session_present: ", x.session_present, ", return_code: ", x.return_code ,"]")
