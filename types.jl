#=This is a class returned from Client.publish() and can be used to find
out the mid of the message that was published, and to determine whether the
message has been published, and/or wait until it is published.
=#
mutable struct MQTTMessageInfo
  mid::UInt16 # message id
  published::Bool
  rc  # result of the publishing

  function MQTTMessageInfo(mid)
    published = false
    rc = 0
    new(mid, published, rc)
  end
end

#= This is a class that describes an incoming or outgoing message. It is
passed to the on_message callback as the message parameter.
=#
mutable struct MQTTMessage
  timestamp::DateTime
  state
  dup::Bool # duplicate flag. Meaningful when receiving QoS1 messages
  mid::UInt16 # message id
  topic::String # WARNING: this arrives in UTF-8 (I think) so might need to be decoded
  payload
  qos::UInt8 # Quality of Service
  retain::Bool # behaviour depends if msg is being sent or received
  info::MQTTMessageInfo
end

#=MQTT version 3.1/3.1.1 client class.

  This is the main class for use communicating with an MQTT broker.

  General usage flow:

  * Use connect()/connect_async() to connect to a broker
  * Call loop() frequently to maintain network traffic flow with the broker
  * Or use loop_start() to set a thread running to call loop() for you.
  * Or use loop_forever() to handle calling loop() for you in a blocking
  * function.
  * Use subscribe() to subscribe to a topic and receive messages
  * Use publish() to send messages
  * Use disconnect() to disconnect from the broker

  Data returned from the broker is made available with the use of callback
  functions as described below.

  Callbacks
  =========

  A number of callback functions are available to receive data back from the
  broker. To use a callback, define a function and then assign it to the
  client:

  def on_connect(client, userdata, flags, rc):
      print("Connection returned " + str(rc))

  client.on_connect = on_connect

  All of the callbacks as described below have a "client" and an "userdata"
  argument. "client" is the Client instance that is calling the callback.
  "userdata" is user data of any type and can be set when creating a new client
  instance or with user_data_set(userdata).

  The callbacks:

  on_connect(client, userdata, flags, rc): called when the broker responds to our connection
    request.
    flags is a dict that contains response flags from the broker:
      flags['session present'] - this flag is useful for clients that are
          using clean session set to 0 only. If a client with clean
          session=0, that reconnects to a broker that it has previously
          connected to, this flag indicates whether the broker still has the
          session information for the client. If 1, the session still exists.
    The value of rc determines success or not:
      0: Connection successful
      1: Connection refused - incorrect protocol version
      2: Connection refused - invalid client identifier
      3: Connection refused - server unavailable
      4: Connection refused - bad username or password
      5: Connection refused - not authorised
      6-255: Currently unused.

  on_disconnect(client, userdata, rc): called when the client disconnects from the broker.
    The rc parameter indicates the disconnection state. If MQTT_ERR_SUCCESS
    (0), the callback was called in response to a disconnect() call. If any
    other value the disconnection was unexpected, such as might be caused by
    a network error.

  on_message(client, userdata, message): called when a message has been received on a
    topic that the client subscribes to. The message variable is a
    MQTTMessage that describes all of the message parameters.

  on_publish(client, userdata, mid): called when a message that was to be sent using the
    publish() call has completed transmission to the broker. For messages
    with QoS levels 1 and 2, this means that the appropriate handshakes have
    completed. For QoS 0, this simply means that the message has left the
    client. The mid variable matches the mid variable returned from the
    corresponding publish() call, to allow outgoing messages to be tracked.
    This callback is important because even if the publish() call returns
    success, it does not always mean that the message has been sent.

  on_subscribe(client, userdata, mid, granted_qos): called when the broker responds to a
    subscribe request. The mid variable matches the mid variable returned
    from the corresponding subscribe() call. The granted_qos variable is a
    list of integers that give the QoS level the broker has granted for each
    of the different subscription requests.

  on_unsubscribe(client, userdata, mid): called when the broker responds to an unsubscribe
    request. The mid variable matches the mid variable returned from the
    corresponding unsubscribe() call.

  on_log(client, userdata, level, buf): called when the client has log information. Define
    to allow debugging. The level variable gives the severity of the message
    and will be one of MQTT_LOG_INFO, MQTT_LOG_NOTICE, MQTT_LOG_WARNING,
    MQTT_LOG_ERR, and MQTT_LOG_DEBUG. The message itself is in buf.

  =#
mutable struct Client
  transport # standard tcp, needed if additional transport methods are added (for example websockets)
  protocol # MQTT protocol version, useful for some level of backwards compatibility
  userdata # the data that will be handed to the callback function every time
  sock # the socket used for communication
  keepalive::Bool
  message_retry
  last_retry_check #TODO is this a a timestamp?
  clean_session::Bool
  username::String
  password::String
  in_packet
  out_packets
  current_out_pack
  last_msg_in # time of the last incoming msg
  last_msg_out
  reconnect_min_delay
  reconnect_max_delay
  reconnect_delay
  pingt_t #TODO ?
  last_mid  # the message id of the last msg (TODO sent or received?)
  state # the state of the client TODO ?
  out_messages  # Collection TODO when do these get deleted? when are they kept?
  in_messages # Collection
  max_inflight_messages
  max_queued_messages
  has_will::Bool
  will::MQTTWill
  host::String #TODO is there a more efficient type?
  port::UInt32
  bind_address #TODO ?

  # TODO think of which mutexes we need
  #=in_callback
  callback_mutex
  out_packet_mutex
  current_out_packet_mutex
  msgtime_mutex
  out_message_mutex
  in_message_mutex
  reconnect_delay_mutex=#

  ssl
  ssl_context
  tls_insecure
  logger
  websocket_path  # just for for completion, no way we are implementing this
  websocket_extra_headers  # same

  on_log::Function
  on_connect::Function
  on_subscribe::Function
  on_message::Function
  on_publish::Function
  on_unsubscribe::Function
  on_disconnect::Function

  on_message_filtered::Function #TODO ??

  # maybe a socket pair is needed to break out of select
end

mutable struct MQTTPacket
  command # the MQTT command read from the packet
  have_remaining # indicates wether remaining_count has been read from packet
  remaining_count # the bytes of remaining length
  remaining_mult  # the multiplier used in calculating remaining_length
  remaining_length  # the actual remaining_length transmitted
  packet  # actual packet payload
  to_process  # the amount of bytes that still need to be processed after remai has been read
  pos # position in the current packet
  info::MQTTMessageInfo # the message info object tied to this packet
end

mutable struct MQTTWill
  topic::String
  payload
  qos::UInt8
  retain::Bool
end
