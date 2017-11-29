using Base.Test, MQTT

import MQTT: Packet, FileStore, path, packets, write_packet, read_packet, Connect, Disconnect, Message

socket = connect("broker.mqttdashboard.com", 1883)
write_packet(socket, Connect(true, 0x0000, "", Nullable{Message}(), Nullable{String}(), Nullable{Array{UInt8}}()))
read_packet(socket)
write_packet(socket, Disconnect())
close(socket)

s = FileStore("mqtt_persist")
s[0x0005] = "5"
@test isfile(path(s, 0x0005))
delete!(s, 0x0005)
@test !isfile(path(s, 0x0005))
s[0x0001] = "1"
s[0x0002] = "2"
@test length(packets(s)) == 2
rm(s.dir, recursive=true)

function compare(expected::Array{UInt8}, packet::Packet)
    buffer = PipeBuffer()
    write_packet(buffer, packet)
    actual = take!(buffer)
    info("Testing: $packet\n\texpected: $expected\n\tactual:   $actual")
    return expected == actual
end

@test compare(
    b"\x10\x0c\x00\x04MQTT\x04\x02\x00\x00\x00\x00",
    Connect(true, 0x0000, "", Nullable{Message}(), Nullable{String}(), Nullable{Array{UInt8}}())
)

@test compare(
    b"\x10\x0f\x00\x04MQTT\x04\x02\x00\x00\x00\x03foo",
    Connect(true, 0x0000, "foo", Nullable{Message}(), Nullable{String}(), Nullable{Array{UInt8}}())
)
