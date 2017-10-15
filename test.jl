#=function on_msg(topic, msg)
end

client = connect("127.0.0.1", 1883, on_msg)
disconnect(client)=#
a = MQTTMessageInfo(6)
println(a.mid)
println(a.published)
println(a.rc)
