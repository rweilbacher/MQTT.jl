using MQTT
using Base.Test
import MQTT: Message
import MQTT: User

info("Running smoke tests")

condition = Condition()
topic = "foo"
payload = randstring(20)

function on_msg(t, p)
    info("Received message topic: [", t, "] payload: [", String(p), "]")
    @test t == topic
    @test String(p)== payload

    notify(condition)
end

client = Client(on_msg)

info("Testing reconnect")
connect(client, "test.mosquitto.org")
disconnect(client)
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

info("Testing connect will")
disconnect(client)
connect(client, "test.mosquitto.org", will=Message(false, 0x00, false, topic, payload))

info("Testing connect with user name an pasword")
disconnect(client)
connect(client, "test.mosquitto.org", user=User("user", "1234"))


disconnect(client)
