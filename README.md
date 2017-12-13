# MQTT.jl

[![Build Status](https://travis-ci.org/rweilbacher/MQTT.jl.svg?branch=master)](https://travis-ci.org/rweilbacher/MQTT.jl)
[![Coverage Status](https://coveralls.io/repos/github/kivaari/MQTT.jl/badge.svg?branch=master)](https://coveralls.io/github/kivaari/MQTT.jl?branch=master)

MQTT Client Library

This code builds a library which enables applications to connect to an MQTT broker to publish messages, and to subscribe to topics and receive published messages.

This library supports: fully asynchronous operation, file persistence

Contents
--------
 TODO

Installation
------------
```julia
Pkg.clone("https://github.com/rweilbacher/MQTT.jl.git")
```
Testing
-------
```julia
Pkg.test("MQTT")
```
Usage
-----
Import the library with the `using` keyword.

Samples are available in the `examples` directory.
```julia
using MQTT
```

## Getting started
TODO

## Client
The client struct is used to store state for an MQTT connection. All callbacks, apart from on_message, can't be set through the constructor and have to be set manually after instantiating the client struct.

**Fields in the Client that are relevant for the library user:**
* ping_timeout: Time, in seconds, the Client waits for the PINGRESP after sending a PINGREQ before he disconnects ; **default = 60 seconds**
* on_message: This function gets called upon receiving a publish message from the broker.
* on_disconnect:
* on_connect: 
* on_subscribe:
* on_unsubscribe: 

##### Constructors
All constructors take the on_message callback as an argument.

```julia
Client(on_msg::Function)
```

Specify a custom ping_timeout
```julia
Client(on_msg::Function, ping_timeout::UInt64)
```

## Connect

###### Example arguments

#### Synchronous connect

#### Asynchronous connect

## Publish
[MQTT v3.1.1 Doc](http://docs.oasis-open.org/mqtt/mqtt/v3.1.1/os/mqtt-v3.1.1-os.html#_Toc398718037)
Publishes a message to the broker connected to the `Client` instance provided as a parameter. There is a synchronous and an asynchronous version available. Both versions take the same arguments.

**Required arguments:**
* client: The connected client to send the message over.
* topic: The topic to send the publish to. Normal rules for publish topics apply so / are allowed but no wildcards.
* payload...: Can be several parameters with potentially different types. Can also be empty. TODO phrasing?

**Optional arguments:**
* dup: Tells the broker that the message is a duplicate. This should not be used under normal circumstances as the library handles this. ; **default = false**
* qos: The MQTT quality of service to use for the message. This has to be a QOS constant (QOS_0, QOS_1, QOS_2). ; **default = QOS_0**
* retain: Wether or not the message should be retained by the broker. This means the broker sends it to all clients who subscribe to this topic ; **default = false**

###### Example arguments
These are valid payload... examples.
```julia
publish(c, "hello/world")
publish(c, "hello/world", "Test", 6, 4.2)
```

This is a valid use of the optional arguments.
```julia
publish(c, "hello/world", "Test", 6, 4.2, qos=QOS_1, retain=true)
```

#### Synchronous publish
This method waits until the publish message has been processed completely and successfully. So in case of QOS 2 it waits until the PUBCOMP has been received.

```julia
publish(client::Client, topic::String, payload...;
    dup::Bool=false,
    qos::UInt8=0x00,
    retain::Bool=false) 
```

#### Asynchronous publish
This method doesn't wait and returns a `Future` object. You may choose to wait on this object. This future completes once the publish message has been processed completely and successfully. So in case of QOS 2 it waits until the PUBCOMP has been received.

```julia
publish_async(client::Client, topic::String, payload...;
    dup::Bool=false,
    qos::UInt8=0x00,
    retain::Bool=false)
```

## Subscribe
[MQTT v3.1.1 Doc](http://docs.oasis-open.org/mqtt/mqtt/v3.1.1/os/mqtt-v3.1.1-os.html#_Toc398718063)
Subscribes the `Client` instance, provided as a parameter, to the specified topics. The client has to already be connected to a broker.

**Required arguments:**
* client: The connected client to subscribe on. TODO phrasing?
* topics...: A variable amount of tuples that each have a String and a QOS constant.

###### Example arguments
This example subscribes to the topic "test" with QOS_2 and "test2" with QOS_0.
```julia
subscribe(c, ("test", QOS_2), ("test2", QOS_0))
```

#### Synchronous subscribe
This method waits until the subscribe message has been successfully sent and acknowledged.

```julia
function subscribe(client, topics::Tuple{String, QOS}...)
```

#### Asynchronous subscribe
This method doesn't wait and returns a `Future` object. You may choose to wait on this object. This future completes once the subscribe message has been successfully sent and acknowledged.

```julia
function subscribe_async(client, topics::Tuple{String, QOS}...)
```

## Unsubscribe

###### Example arguments

#### Synchronous unsubscribe

#### Asynchronous unsubscribe

## Disconnect


```julia
```