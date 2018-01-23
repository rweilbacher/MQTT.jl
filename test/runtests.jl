using Base.Test, MQTT

import Base: connect, read, write, close
import MQTT: read_len, Message


include("smoke.jl")
include("mocksocket.jl")
include("packet.jl")
include("unittests.jl")
