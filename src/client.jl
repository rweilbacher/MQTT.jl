mutable struct Client
    on_msg::Function
    keep_alive::UInt16

    lock::ReentrantLock
    last_id::UInt16
    in_flight::Dict{UInt16, Tuple{Packet, Future}}
end

function packet_id(c::Client)
    lock(c.lock)
    if c.last_id == typemax(UInt16)
        c.last_id = 0
    end
    c.last_id += 1
    unlock(c.lock)
    return c.last_id
end

function complete(c::Client, id::UInt16, value=nothing)
    lock(c.lock)
    if haskey(c.in_flight, id)
        future = c.in_flight[id]
        put!(future, value)
        delete!(client.in_flight, id)
    else
        # TODO unexpected ack protocol error
    end
    unlock(c.lock)
end
