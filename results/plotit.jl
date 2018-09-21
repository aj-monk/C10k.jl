using Plots

percentile = [ 50,  66,   75,   80,  90,    95,   98,   99,   100]
jul        = [106, 115, 1796, 3366, 4839, 4885, 6652, 6681,  6704]
nodejs     = [610, 737, 1458, 1632, 1701, 1898, 1945, 1952,  2059]
apache     = [ 89,  95,   99,  102,  151,  424, 1075, 1085, 21092]

data = hcat(jul./1000, nodejs./1000, apache./1000)

p = plot(percentile, data, title="Request Latency", xlabel="Percentile of requests", ylabel="Latency in seconds", label=["Julia", "Nodejs", "Apache"])
display(p)
savefig(p, "C10k.png")
