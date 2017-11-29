import Base: setindex!, delete!

abstract type Store end

struct MemoryStore <: Store
    packets::Dict{UInt16, String}
    MemoryStore() = new(Dict{UInt16, String}())
end

setindex!(s::MemoryStore, value::String, key::UInt16) = s.packets[key] = value

delete!(s::MemoryStore, key::UInt16) = delete!(s.packets, key)

packets(s::MemoryStore) = collect(values(s.packets))

struct FileStore <: Store
    dir::String
    function FileStore(dir::String)
        mkpath(dir)
        return new(dir)
    end
end

function path(s::FileStore, key::String)
    return joinpath(s.dir, key)
end

path(s::FileStore, key::UInt16) = path(s, string(key))

function setindex!(s::FileStore, value::String, key::UInt16)
    file = open(path(s, key), "w")
    serialize(file, value)
    close(file)
end

function delete!(s::FileStore, key::UInt16)
    rm(path(s, key))
end

function packets(s::FileStore)
    packets = Vector{String}()
    for f in readdir(s.dir)
        file = open(path(s, f))
        packet = deserialize(file)
        push!(packets, packet)
    end
    return packets
end
