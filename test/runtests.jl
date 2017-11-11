include("testlib.jl")

using MQTT
import MQTT.Message
using Base.Test

# because of the way julia handles null its easier to link a client instance with one tcp connection
# this could create problems in the future if you want to implement some reconnection for example

function on_msg(topic, payload)
    info("Received message topic: [", topic, "] payload: [", String(payload), "]")
    @test topic == "abc"
    @test String(payload) == "qwerty"
end

function is_out_correct(filename_expected::AbstractString, actual::Channel{UInt8})
    file = open(filename_expected, "r")
    correct = true
    while !eof(file)
        if read(file, UInt8) != take!(actual)
            correct = false
            break
        end
    end
    if isready(actual)
        # There is still data in the output but no more in the file
        #correct = false # TODO maybe correct has to be false?
    end
    return correct
end

function consume_output(channel::Channel{UInt8})
  while isready(channel)
    take!(channel)
  end
end

function test()
    client = Client(on_msg)

    info("Testing connect")
    connect(client, "test.mosquitto.org", client_id="TestID")
    tfh::TestFileHandler = client.socket
    @test is_out_correct("data/output/connect.dat", tfh.out_channel)
    # CONNACK is automatically being sent in connect call

    info("Testing subscribe")
    subscribe_async(client, "abc", 0x01, "cba", 0x00)
    put_from_file(tfh, "data/input/suback.dat")
    @test is_out_correct("data/output/subreq.dat", tfh.out_channel)

    info("Testing publish")
    put_from_file(tfh, "data/input/publish.dat")

    publish_async(client, "test1", "QOS_0", qos=0x00)
    @test is_out_correct("data/output/qos0pub.dat", tfh.out_channel)

    publish_async(client, "test2", "QOS_1", qos=0x01)
    put_from_file(tfh, "data/input/puback.dat")
    @test is_out_correct("data/output/qos1pub.dat", tfh.out_channel)

    info("Testing unsubscribe")
    unsubscribe_async(client, "abc", "cba")
    put_from_file(tfh, "data/input/unsuback.dat")
    @test is_out_correct("data/output/unsubreq.dat", tfh.out_channel)

    info("Testing disconnect")
    disconnect(client)
    @test is_out_correct("data/output/disco.dat", tfh.out_channel)

    #TODO currently a reconnect just fails if the client isn't newly instantiated

    #This has to be in it's own connect flow to not interfere with other messages
    info("Testing keep alive with response")
    client = Client(on_msg)
    connect(client, "test.mosquitto.org", client_id="TestID", keep_alive=0x0001)
    tfh = client.socket
    @test is_out_correct("data/output/connect_keep_alive1s.dat", tfh.out_channel) # Consume output
    @test is_out_correct("data/output/pingreq.dat", tfh.out_channel)
    put_from_file(tfh, "data/input/pingresp.dat")

    info("Testing keep alive without response")
    sleep(2)
    @test is_out_correct("data/output/pingreq.dat", tfh.out_channel)
    @test is_out_correct("data/output/disco.dat", tfh.out_channel)

    info("Testing unwanted pingresp")
    client = Client(on_msg)
    connect(client, "test.mosquitto.org", client_id="TestID", keep_alive=0x000F)
    tfh = client.socket
    @test is_out_correct("data/output/connect_keep_alive15s.dat", tfh.out_channel) # Consume output
    @test is_out_correct("data/output/pingreq.dat", tfh.out_channel)
    put_from_file(tfh, "data/input/pingresp.dat")
    put_from_file(tfh, "data/input/pingresp.dat")
    sleep(0.1)
    @test is_out_correct("data/output/disco.dat", tfh.out_channel)
end

test()
