info("Running smoke tests")

condition = Condition()
expected_topic = randstring(20)
expected_payload = convert(Array{UInt8}, randstring(20))

function on_msg(topic, payload)
    @test topic == expected_topic
    @test payload == expected_payload
    notify(condition)
end

function on_disconnect(reason)
    @test reason == nothing
end

client = Client(on_msg, on_disconnect, 60)
opts = ConnectOpts("test.mosquitto.org")
opts.keep_alive = 0x0006

info("Testing reconnect")
connect(client, opts)
disconnect(client)
connect(client, opts)

future = subscribe(client, (expected_topic, AT_MOST_ONCE), async=true)
get(future)

info("Testing publish qos 0")
publish(client, expected_topic, expected_payload, qos=AT_MOST_ONCE)
wait(condition)

info("Testing publish qos 1")
publish(client, expected_topic, expected_payload, qos=AT_LEAST_ONCE)
wait(condition)

info("Testing publish qos 2")
publish(client, expected_topic, expected_payload, qos=EXACTLY_ONCE)
wait(condition)

sleep(10)

disconnect(client)
