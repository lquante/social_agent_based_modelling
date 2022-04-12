using DrWatson
@quickactivate "Social Agent Based Modelling"
using Agents, Random, Graphs
using GraphPlot
using StatsPlots
using Cairo, Compose

# functions to calculate some network measures
#details see http://networksciencebook.com/chapter/10#network-epidemic table 10.3

"epidemic threshold for SIR modell on given graph"
function SIR_epidemic_threshold(graph)
    degrees = degree(graph)
    mean_degree = mean(degrees)
    second_moment = mean(degrees.^2)
    return 1/(second_moment/mean_degree-1)
end

"epidemic threshold for SIS modell on given graph"
function SIS_epidemic_threshold(graph)
    degrees = degree(graph)
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

nodenumber=10000

watts_strogatz_test = watts_strogatz(nodenumber,10,0.8)
dorogovtsev_mendes_test = dorogovtsev_mendes(nodenumber)
bara_albert = Graphs.barabasi_albert(nodenumber,1)

# some plotting
# nodes size proportional to their degree
nodesize = degree(watts_strogatz_test)
@time draw(SVG(plotsdir("watts_strogatz.svg"),10cm,10cm),compose(gplot(watts_strogatz_test, nodesize=nodesize,edgelinewidth=0.25), compose(compose(context(), Compose.rectangle()), fill("white"))))

nodesize = degree(bara_albert)
@time draw(SVG(plotsdir("barabasi_albert.svg"),10cm,10cm),compose(gplot(bara_albert, nodesize=nodesize,edgelinewidth=0.0), compose(compose(context(), Compose.rectangle()), fill("white"))))

nodesize = degree(dorogovtsev_mendes)
@time draw(SVG(plotsdir("dorogovtsev_mendes.svg"),10cm,10cm),compose(gplot(dorogovtsev_mendes_test, nodesize=nodesize,edgelinewidth=0.25), compose(compose(context(), Compose.rectangle()), fill("white"))))