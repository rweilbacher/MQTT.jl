using MQTT

broker = "test.mosquitto.org"

#Define the callback for receiving messages.
function on_msg(topic, payload)
    info("Received message topic: [", topic, "] payload: [", String(payload), "]")
end

#Instantiate a client.
client = Client(on_msg)
connect(client, broker)

#Set retain to true so we can receive a message from the broker once we subscribe
#to this topic.
publish(client, "jlExample", "Hello World!", retain=true)

#Subscribe to the topic we sent a retained message to.
subscribe(client, ("jlExample", QOS_1))

#Unsubscribe from the topic
unsubscribe(client, "jlExample")

#Disconnect from the broker. Not strictly needed as the broker will also
#disconnect us if the socket is closed. But this is considered good form
#and needed if you want to resume this session later.
disconnect(client)
