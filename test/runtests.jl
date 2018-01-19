using Base.Test, MQTT

function on_msg(topic, payload)
    # println("Received message topic: [", t, "] payload: [", String(p), "]")
end

function on_disconnect(reason)
    # println(reason)
end

c = Client(on_msg, on_disconnect, 60)
opts = ConnectOpts("localhost")
connect(c, opts)
subscribe(c, ("test15", AT_MOST_ONCE), ("test16", AT_LEAST_ONCE))
unsubscribe(c, "test15")
publish(c, "test16", convert(Array{UInt8}, "test-qos0"), qos=AT_MOST_ONCE)
publish(c, "test16", convert(Array{UInt8}, "test-qos1"), qos=AT_LEAST_ONCE)
publish(c, "test16", convert(Array{UInt8}, "test-qos2"), qos=EXACTLY_ONCE)
disconnect(c)
