# C10k

*Evaluation of a Julia web server for 10k concurrent connections*

## Introduction
While the [Julia](https://julialang.org) language is popular for
scientific computing there aren't many examples of it being used
for general purpose applications. Here we compare a simple http
based file server written in Julia with other alternatives. We
run the popular C10k test to see how a Julia based web server
handles 10k simultaneous connections.

No attempt is made to tune any of the alternatives. The goal is to
see how a solution that is quickly put together will perform.

## The Contenders

### Julia
1. [Julia](https://github.com/JuliaLang/julia) v1.0.0
2. [HTTP.jl](https://github.com/JuliaWeb/HTTP.jl) v0.6.14

### Apache
1. Server version: [Apache](https://httpd.apache.org)/2.4.29 (Ubuntu)
2. Server built:   2018-06-27T17:05:04

### Node.js based http-server
1. [node.js](https://nodejs.org/en/) v10.11.0
2. [http-server](https://www.npmjs.com/package/http-server)

## Environment

### Hardware
1. CPU: [Intel(R) Core(TM) i7-7500U](https://ark.intel.com/products/95451/Intel-Core-i7-7500U-Processor-4M-Cache-up-to-3_50-GHz-) CPU @ 2.70GHz
2. System Memory: 16 GB
2. Storage: PCIe NVMe Toshiba 512gb SSD

### OS
Linux xyxy 4.15.0-33-generic #36-Ubuntu SMP Wed Aug 15 16:00:05 UTC 2018 x86_64 x86_64 x86_64 GNU/Linux

## Benchmark
[ab - Apache HTTP server benchmarking tool](https://httpd.apache.org/docs/2.2/programs/ab.html)

```bash
bash$ ab -n 13000 -c 10000 -g test.csv http://localhost:8080/index.html
```

## Julia Web Server
A simple file server is implemented using HTTP.jl.

```julia
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
```

Running the server
```julia
(v1.0) pkg> activate .

julia> using C10k; C10k.file_server()
[ Info: Listening on: Sockets.InetAddr{Sockets.IPv4}(ip"127.0.0.1", 0x1f90)
Task (runnable) @0x00007fa9c0730d30

julia> using Logging; global_logger(NullLogger()) # Turn off logging
```

## Results

![Benchmark results](/C10k.png)

* For upto 6.8K simultaneous connections Julia performs 6 times better (in latency
per request) than nodejs, roughly equivalent to the native C performance of
Apache.
* Beyond 6.8K connections Julia's performance steadily degrades.
* Nodejs performance degrades more gradually after 6.8K connections.
* The worst case Latency of the Julia server is 6.7 seconds.
* Apache performs very badly on the last connection (possibly last close).

## Conclusions
An HTTP file server in Julia quickly put together with HTTP.jl performs well
upto about 5K simultaneous connections.

More tests need to be run for heavier workloads that exercise the CPU or
memory. And the degradation of performance beyond 6.8K connections needs
to be studied.

## OS Settings
```bash
bash$ sysctl net.ipv4.ip_local_port_range="15000	61000"
bash$ sysctl net.ipv4.tcp_fin_timeout=20
bash$ sysctl net.ipv4.tcp_tw_recycle=1
bash$ sysctl net.ipv4.tcp_tw_reuse=1
```

Increase the user's ulimit in /etc/security/limits.conf like so.

    user1        hard    nofile      100000
    user1        soft    nofile      100000

Set the user's ulimit in the shell before running the client or server.
```bash
ulimit -n 1000000
```
