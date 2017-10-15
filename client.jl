# Public methods

# TODO rework method arguments, some get the entire client but only need a couple elements. Maybe it's better to only give them those specifically
# Private methods
function send_puback(client, mid)
end

function send_pubcomp(client, mid)
end

# Pack the remaining length field in the packet appropriately
function pack_remaining_length(packet, remaining_length)
end

# Pack 2 bytes of length-prefixed data into header.
function pack_str16(packet, data)
  # Strings need to be UTF-8
end

function send_publish(client, mid, topic, payload, qos, retain=false, dup=false, info)
  # Assumes topic and payload are properly encoded
end

function send_pubrec(client)
end

function send_pubrel(client)
end

# For PUBACK, PUBCOMP, PUBREC, and PUBREL
function send_command_with_mid(client, command, mid, dup)
end

# For DISCONNECT, PINGREQ and PINGRESP
function send_simple_command(client, command)
end

function send_connect(client, keepalive, clean_session)
end

function send_disconnect(client)
end

function send_subscribe(client, topic, dup)
end

function send_unsubscribe(client, topic, dup)
end

# Checks the state of each message and retries accordingly
function message_retry_check_actual(client, messages, mutex)
end

# Calls message_retry_check_actual for in- and outbound messages
function message_retry_check(client)
end

# Resets all outbound messages on reconnect TODO ?
function messages_reconnect_reset_out(client)
end

# Resets all inbound messages on reconnect TODO ?
function messages_reconnect_reset_in(client)
end

# Calls messages_reconnect_reset_in and messages_reconnect_reset_out
function messages_reconnect_reset(client)
end

# Queue a new packet and break out of select if in threaded mode TODO ?
function packet_queue(client, command, packet, mid, qos, info)
end

function handle_packet(packet)
end

function handle_pingreq(client)
end

function handle_pingresp(client)
end

function handle_connack(client)
end

function handle_suback(client)
end

function handle_publish(client)
end

function handle_pubrel(client)
end

function handle_pubrec(client)
end

function handle_unsuback(client)
end

function handle_pubackcomp(client)
end

# TODO ?
function handle_on_message(client)
end

function update_inflight(client)
end

# Reduces inflight_messages and calls update_inflight() if inflight_messages is bigger than max_inflight_messages (Refer to Python implementation for details)
function do_on_publish(client, idx, mid)
end

#TODO this calls loop_forever this might need to get reworked for Julia
function thread_main()
end

# Waits the appropriate time for reconnectiong and adjust reconnect time
function reconnect_wait(client)
end

# Websocket methods
function do_handshake(client, extra_headers)
end

function create_frame(client, opcode, data, do_masking=1)
end

function buffered_read(client, length)
end

function recv_impl(client, length)
end

function send_impl(client, data)
end

function close(client)
end

#TODO ?!
function fileno(client)
end

function pending(client)
end

function set_blocking(client, flag)
end

# These are all helper methods that call send_impl and recv_impl accordingly
function recv(client, length)
end

function read(client, length)
end

function send(client, data)
end

function write(client, data)
end

'''struct Client
  keep_alive::UInt16
  on_msg::Function
  socket::TCPSocket
end

function write_msg(client, cmd, payload...)
  # TODO rewrite method
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
  #TODO rewrite method
  cmd = read(client.socket, UInt8)
  len = read(client.socket, UInt8)

  if cmd === CONNACK
    rc = read(client.socket, UInt16)
    println(rc)
  end
end

function connect(host::AbstractString, port::Int, on_msg::Function)
  #TODO rewrite method
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
  #TODO rewrite method
  write_msg(client, DISCONNECT)
  close(client.socket)
  println("disconnected")
end

function subscribe(client, topics...)
end

function publish(client, topic, bytes)
end'''
