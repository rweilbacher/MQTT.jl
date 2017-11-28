struct Connect <: Packet
    header::UInt8
    protocol_name::String
    protocol_level::UInt8
    clean_session::Bool
    keep_alive::UInt16
    client_id::String
    will::Nullable{Message}
    username::Nullable{String}
    password::Nullable{Array{UInt8}}

    Connect(clean_session::Bool, keep_alive::UInt16, client_id::String, will::Nullable{Message}, username::Nullable{String}, password::Nullable{Array{UInt8}}) = new(CONNECT, "MQTT", 0x04, clean_session, keep_alive, client_id, will, username, password)
end

function write(s::IO, packet::Connect)
    mqtt_write(s, packet.protocol_name)
    mqtt_write(s, packet.protocol_level)
    clean_session_flag = convert(UInt8, packet.clean_session) << 1
    will_flag = convert(UInt8, !isnull(packet.will)) << 2
    will_qos = (isnull(packet.will) ? 0x00 : get(packet.will).qos) << 3
    will_retain = (isnull(packet.will) ? 0x00 : convert(UInt8, get(packet.will).retain)) << 5
    username_flag = convert(UInt8, !isnull(packet.username)) << 6
    password_flag = convert(UInt8, !isnull(packet.password)) << 7
    connect_flags = clean_session_flag | will_flag | will_qos | will_retain | username_flag | password_flag
    mqtt_write(s, connect_flags)
    mqtt_write(s, packet.keep_alive)
    mqtt_write(s, packet.client_id)
    if !isnull(packet.will)
        mqtt_write(s, packet.will.topic)
        mqtt_write(s, convert(UInt16, packet.will.payload)) # TODO
        write(s, packet.will.payload)
    end
    if !isnull(packet.username)
        mqtt_write(s, get(packet.username))
    end
    if !isnull(packet.password)
        mqtt_write(s, convert(UInt16, get(packet.password))) # TODO
        write(s, get(packet.password))
    end
end

Base.show(io::IO, x::Connect) = print(io, "CONNECT[protocol_name: '", x.protocol_name, "'",
", protocol_level: ", x.protocol_level,
", clean_session: ", x.clean_session,
", keep_alive: ", x.keep_alive,
", client_id: '", x.client_id, "'",
", will: ", get(x.will, "none"),
", username: ", get(x.username, "none"),
", password: ", get(x.password, "none"), "]")
