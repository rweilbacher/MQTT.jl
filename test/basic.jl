using MQTT
using Base.Test

info("Basic Test")

condition = Condition()
topic = randstring(20)
payload = randstring(20)

function on_msg(t, p)
    info("Received message topic: [", topic, "] payload: [", String(payload), "]")
    @test t == topic
    @test String(p)== payload

    notify(condition)
end

client = Client(on_msg)
connect(client, "test.mosquitto.org")
subscribe(client, topic, 0x00)
publish(client, topic, payload)

wait(condition)

disconnect(client)

info("Basic Finished")
