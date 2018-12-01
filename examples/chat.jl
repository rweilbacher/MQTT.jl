using Pages, MQTT

struct Message
    user::String
    text::String
end

function on_msg(topic, payload)
    msg = deserialize(PipeBuffer(payload))
    Pages.broadcast("script", "onMessage('$topic', '$(msg.user)', '$(msg.text)')")
end

client = Client(on_msg)
connect(client, "test.mosquitto.org")
subscribe(client, "test_msgs", 0x00)

Endpoint("/") do request::Request
    return open(readstring, "index.html")
end

Endpoint("/chat.js") do request::Request
    return open(readstring, "chat.js")
end

Callback("add") do args
  subscribe(client, args[1], 0x00)
end

Callback("send") do args
    msg = Message(args[2], args[3])
    buffer = PipeBuffer()
    serialize(buffer, msg)
    publish(client, args[1], take!(buffer), qos=0x00)
end

println(Pages.pages)
f = Pages.start()
wait(f)
