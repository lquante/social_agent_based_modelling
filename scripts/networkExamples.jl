using DrWatson
@quickactivate "Social Agent Based Modelling"
using Agents, Random, DataFrames, Graphs, Plots, Statistics
using GraphPlot
using SNAPDatasets
using LightGraphs
using StatsPlots
using Cairo, Compose

watts_strogatz_test = watts_strogatz(1000,10,0.9)
bara_albert = barabasi_albert(1000,10,5)


# functions to calculate some network measures
#details see http://networksciencebook.com/chapter/10#network-epidemic table 10.3

"epidemic threshold for SIR modell on given graph"
function SIR_epidemic_threshold(graph)
    degrees = indegree(graph)
    mean_degree = mean(degrees)
    second_moment = mean(degrees.^2)
    return 1/(second_moment/mean_degree-1)
end

"epidemic threshold for SIS modell on given graph"
function SIS_epidemic_threshold(graph)
    degrees = indegree(graph)
    mean_degree = mean(degrees)
    second_moment = mean(degrees.^2)
    return mean_degree/second_moment
end


#some epidemic measures
"epidemic threshold = spreading rate / recovery rate"
spreading_rate = 0.2
recovery_rate = 0.97
naturalSpread = spreading_rate/recovery_rate # eq. 10.22 in http://networksciencebook.com/chapter/10#network-epidemic 


# calculate necessary vaccinate rate to stop spread in a mean field fashion

function vaccinationRequirement(naturalSpread,epidemicThreshold)
    return 1-naturalSpread*epidemicThreshold
end


# some plotting
# nodes size proportional to their degree
nodesize = [LightGraphs.outdegree(watts_strogatz_test,v) for v in LightGraphs.vertices(watts_strogatz_test)]
@time draw(SVG(plotsdir("watts_strogatz.svg")),compose(gplot(watts_strogatz_test, nodesize=nodesize,edgelinewidth=0.25), compose(compose(context(), Compose.rectangle()), fill("white"))))

nodesize = [LightGraphs.outdegree(bara_albert,v) for v in LightGraphs.vertices(bara_albert)]
@time draw(SVG(plotsdir("barabasi_albert.svg")),compose(gplot(bara_albert, nodesize=nodesize,edgelinewidth=0.25), compose(compose(context(), Compose.rectangle()), fill("white"))))


