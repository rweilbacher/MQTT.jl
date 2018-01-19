module MQTT

import Base: connect, read, write, get

include("utils.jl")
include("packet.jl")
include("packets/connect.jl")
include("packets/publish.jl")
include("packets/subscribe.jl")
include("packets/unsubscribe.jl")
include("packets/disconnect.jl")
include("packets/ping.jl")
include("net.jl")
include("client.jl")

export Client

function on_msg(t, p)
    # info("Received message topic: [", t, "] payload: [", String(p), "]")
end

function on_disconnect(reason)
    println(reason)
end

c = Client(on_msg, on_disconnect, 60)
connect(c, "localhost")
subscribe(c, ("test15", AT_MOST_ONCE), ("test16", AT_LEAST_ONCE))
unsubscribe(c, "test15")
publish(c, "test16", convert(Array{UInt8}, "test-qos0"), qos=AT_MOST_ONCE)
publish(c, "test16", convert(Array{UInt8}, "test-qos1"), qos=AT_LEAST_ONCE)
publish(c, "test16", convert(Array{UInt8}, "test-qos2"), qos=EXACTLY_ONCE)
disconnect(c)

end
