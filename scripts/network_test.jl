using DrWatson
@quickactivate "Social Agent Based Modelling"
using Agents, Random, DataFrames, LightGraphs
using Distributions: Poisson, DiscreteNonParametric
using LinearAlgebra: diagind
using GraphPlot
using SNAPDatasets
using DelimitedFiles
using CSV


include(srcdir("agentFunctions.jl"))
include(srcdir("modelling.jl"))

watts_networks = watts_strogatz(1000,10,0.8)
bara_albert = barabasi_albert(10000,10,5)

space = Agents.GraphSpace(watts_networks)


natural_spread = 0.15/0.97

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

SIR_epidemic_threshold(watts_networks)
SIS_epidemic_threshold(watts_networks)

seeds = rand(0:5000,100)
decisionModel = model_decision_agents_SIR(mixed_population;space=space,seed = seeds[1],socialInfluenceFactor=2, switchingLimit=2,detectionTime = 6,
	initialInfected = 0.01,
	deathRate = 0.02,
	reinfectionProtection = 180,
	infectionPeriod=30,
	transmissionUndetected = 0.12,
	transmissionDetected = 0.0005,
	detectionProbability = 0.58) #according to Gutenberg study of U Mainz, 42.4% undetected overall ==> since multiple days of possible detection, lower individual detection probability.)

	#TODO calibrate parameters properly

agent_df, model_df = run!(decisionModel, agent_step_SIR!,model_step!, 500; adata = [:state,:affinity,:SIR_status])

CSV.write(datadir("watts_test_with_vaccine.csv"),agent_df)




# test with karate club network
karate_am = readdlm(datadir("karate.txt"))
karate_g = Graph(karate_am)

seeds = rand(0:1000,100)
decisionModel = model_decision_agents_SIR(mixed_population;space=Agents.GraphSpace(karate_g),seed = seeds[1],socialInfluenceFactor=2)

# test with small network from facebook data (stanford SNAP)
fb = loadsnap(:facebook_combined)
fbModel = model_decision_agents(mixed_population;space=Agents.GraphSpace(fb),seed = seeds[1],socialInfluenceFactor=0.5,switchingLimit=50,neighbourhoodExtent=1,switchingBoundary=0.85)
agent_df, model_df = run!(fbModel, agent_step!,model_step!, 100; adata = [(:state,mean),(:affinity,mean)])


# test with small network from twitter data (stanford SNAP)
twitter = loadsnap(:ego_twitter_u)
twitterModel = model_decision_agents(mixed_population;space=Agents.GraphSpace(twitter),seed = seeds[1],socialInfluenceFactor=0.5,switchingLimit=1000,neighbourhoodExtent=1,switchingBoundary=0.85)
agent_df, model_df = run!(twitterModel, agent_step!,model_step!, 100; adata = [(:state,mean),(:affinity,mean)])


# some ensemble run test
parameters = Dict(
	:space => Agents.GraphSpace(fb),
	:switchingLimit => 50,
    :schedulerIndex => [2],
	:neighbourhoodExtent => 1,
	:switchingBoundary => [0.5,0.6,0.7,0.8,0.9],
	:seed => rand(0:1000,1)        # expanded
)
adata = [(:state, mean),(:affinity,mean)]
adf, _ = paramscan(parameters, initialize; adata, agent_step!,model_step!, n = 100)



using StatsPlots
gr()
@df adf plot(:step,:mean_state,group = :switchingBoundary)
@df adf plot(:step,:mean_affinity,group = :switchingBoundary)
