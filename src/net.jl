const PACKETS = Dict{PacketType, Type}(
CONNACK => Connack,
PUBLISH => Publish,
PUBACK => Puback,
PUBREC => Pubrec,
PUBREL => Pubrel,
PUBCOMP => Pubcomp,
SUBACK => Suback,
UNSUBACK => Unsuback,
PINGRESP => Pingresp)

function read_packet(s::IO)
    header = read(s, UInt8)
    len = read_len(s)
    # read variable header and payload into buffer
    buffer = PipeBuffer(read(s, len))
    packet_type = convert(PacketType,header & 0xF0)
    flags = header & 0x0F
    packet = read(buffer, flags, PACKETS[packet_type])
    return packet
end

function write_packet(s::IO, packet::Packet)
    buffer = PipeBuffer()
    write(buffer, packet)
    data = take!(buffer)
    write(s, packet.header)
    write_len(s, length(data))
    write(s, data)
end
