import Base.connect
include("consts.jl")

struct Client
  keep_alive::UInt16
  on_msg::Function
  socket::TCPSocket
end

function write_msg(client, cmd, payload...)
  buffer = PipeBuffer()
  for i in payload
    if typeof(i) === String
      write(buffer, hton(convert(UInt16, length(i))))
    end
    write(buffer, i)
  end
  data = take!(buffer)
  len = hton(convert(UInt8, length(data)))
  write(client.socket, cmd, len, data)
end

function read_msg(client)
  cmd = read(client.socket, UInt8)
  len = read(client.socket, UInt8)

  if cmd === CONNACK
    rc = read(client.socket, UInt16)
    println(rc)
  end
end

function connect(host::AbstractString, port::Int, on_msg::Function)
  client = Client(0, on_msg, connect(host, port))
  protocol = "MQTT"
  protocol_version = 0x04
  flags = 0x02 # clean session
  client_id = "julia"
  write_msg(client, CONNECT, protocol, protocol_version, flags, client.keep_alive, client_id)
  println("connected to ", host, ":", port)

  read_msg(client)

  client
end

function disconnect(client)
  write_msg(client, DISCONNECT)
  close(client.socket)
  println("disconnected")
end

function subscribe(client, topics...)
end

function publish(client, topic, bytes)
end
