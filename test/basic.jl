using MQTT
using Base.Test

info("Running basic tests")

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

info("Testing publish qos 0")
publish(client, topic, payload, qos=0x00)
wait(condition)

info("Testing publish qos 1")
publish(client, topic, payload, qos=0x01)
wait(condition)

info("Testing publish qos 2")
publish(client, topic, payload, qos=0x02)
wait(condition)

disconnect(client)

info("Basic tests finished")
