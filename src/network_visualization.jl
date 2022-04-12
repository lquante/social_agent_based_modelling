using DrWatson
@quickactivate "Social Agent Based Modelling"
using Agents, Random, DataFrames, Graphs, Plots, Statistics, Distributions
using GraphPlot
using SNAPDatasets
using Graphs
using StatsPlots
using Cairo, Compose
using Colors

watts_strogatz_test = watts_strogatz(1000,10,0.8)
bara_albert = barabasi_albert(100,10,5)

## remove all vertices of degree 0
function strip_isolates(g)
    isolates=findall(x->x==0, degree(g))
    isolates = reverse(isolates)
    for i in isolates
        rem_vertex!(g,i)
    end
    return g
end

@time draw(SVG(plotsdir("bara_albert.svg"),10cm,10cm),compose(gplot(bara_albert,edgelinewidth=0.25), compose(compose(context(), Compose.rectangle()), fill("white"))))
