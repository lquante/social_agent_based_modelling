using DrWatson
@quickactivate "Social Agent Based Modelling"
using Agents, Random, DataFrames, Graphs, Plots
using GraphPlot
using SNAPDatasets
using LightGraphs
using StatsPlots
using Cairo, Compose

watts_strogatz_test = watts_strogatz(1000,10,0.9)
bara_albert = barabasi_albert(1000,10,5)
# calculate some network measures

degrees = indegree(test)
mean_degree = mean(degrees)
second_moment = mean(degrees.^2)

SIR_network_threshold = 1/(second_moment/mean_degree-1) # assuming SIR (i.e. complete immunity)
SIS_network_threshold = mean_degree/second_moment # assuming SIS (i.e. immedialty succeptible after infection)

#details see http://networksciencebook.com/chapter/10#network-epidemic table 10.3

#some epidemic measures
spreading_rate = 3
recovery_rate = 30
epidemic_threshold = spreading_rate/recovery_rate # eq. 10.22 in http://networksciencebook.com/chapter/10#network-epidemic 

# some plotting
# nodes size proportional to their degree
nodesize = [LightGraphs.outdegree(watts_strogatz_test,v) for v in LightGraphs.vertices(watts_strogatz_test)]
@time draw(SVG(plotsdir("watts_strogatz.svg")),compose(gplot(watts_strogatz_test, nodesize=nodesize,edgelinewidth=0.25), compose(compose(context(), Compose.rectangle()), fill("white"))))

nodesize = [LightGraphs.outdegree(bara_albert,v) for v in LightGraphs.vertices(bara_albert)]
@time draw(SVG(plotsdir("barabasi_albert.svg")),compose(gplot(bara_albert, nodesize=nodesize,edgelinewidth=0.25), compose(compose(context(), Compose.rectangle()), fill("white"))))
