using HTTP
using Sockets
using Logging

global_logger(NullLogger()) # Shut off logging

const HOST = "127.0.0.1"
const PORT = 8080
const STATIC_DIR = "./static/"

function file_server()
    web_server = HTTP.Servers.Server(handler, ratelimit=1000000//1)
    @async HTTP.Servers.serve(web_server, HOST, PORT, false)
end

function handler(req::HTTP.Request)
    (req.method != "GET") && return HTTP.Response(404, "Method $(req.method) not supported!")
    try
        return HTTP.Response(get_file(req))
    catch e
        return HTTP.Response(404, "Error: $e")
    end
end

function get_file(req::HTTP.Request) :: Vector{UInt8}
    t = (req.target == "/") ? "/index.html" : req.target
    read(STATIC_DIR * t)
end

# An alternate implementation
function __start()
    n::Int64 = 0
    errors::Int64 = 0
    @async begin
        HTTP.listen(pipeline_limit = 1000000) do request::HTTP.Request
            n += 1
            try
                @info "$n requests with $errors failures."
                return HTTP.Response("Hello There!")
            catch e
                errors += 1
                @info "$n requests with $errors failures."
                return HTTP.Response(404, "Error: $e")
            end
        end
    end
end
