import Base: connect, read, write, close

mutable struct TestFileHandler <: IO
    out_channel::Channel{UInt8}
    in_channel::Channel{UInt8}
    closenotify::Condition
    new_input::Condition
    closed::Bool
end

function read(fh::TestFileHandler, t)
    return take!(fh.in_channel)
end

function read(fh::TestFileHandler, t::Type{UInt8})
    return take!(fh.in_channel)
end

function read(fh::TestFileHandler, length::Integer)
    data = Vector{UInt8}()
    for i = 1:length
        append!(data, take!(fh.in_channel))
    end
    return data
end

function close(fh::TestFileHandler)
    fh.closed = true
    notify(fh.closenotify)
end

function write(fh::TestFileHandler, data::UInt8)
    put!(fh.out_channel, data)
end

function put(fh::TestFileHandler, data::Array{UInt8})
    for i in data
        put!(fh.in_channel, i)
    end
end

function put_from_file(fh::TestFileHandler, filename)
    put(fh, read_all_to_arr(filename))
end

function read_all_to_arr(filename)
    file = open(filename, "r")
    data = Vector{UInt8}()
    while !eof(file)
        append!(data, read(file, UInt8))
    end
    close(file)
    return data
end

function connect(host::AbstractString, port::Integer)
    th = TestFileHandler(Channel{UInt8}(256), Channel{UInt8}(256), Condition(), Condition(), false)
    put_from_file(th, "data/input/connack.dat")
    return th
end
