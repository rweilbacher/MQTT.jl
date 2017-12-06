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
Use the library by "using" it.

Samples are available in the `examples` directory.
```julia
using MQTT
```

## Getting started
TODO

## Client
The client struct is used to store state for an MQTT connection. All callbacks, apart from on_message, can't be set through the constructor and have to be set manually after instantiating the client struct.

Fields in the Client that are relevant for the library user:
* ping_timeout: Time, in seconds, the Client waits for the PINGRESP after sending a PINGREQ before he disconnects ; default = 60 seconds
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

## Publish

## Subscribe

```julia
```