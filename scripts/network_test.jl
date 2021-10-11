using DrWatson
@quickactivate "Social Agent Based Modelling"
using Agents, Random, DataFrames, LightGraphs
using Distributions: Poisson, DiscreteNonParametric
using LinearAlgebra: diagind
using GraphPlot
using SNAPDatasets
using DelimitedFiles

include(srcdir("agentFunctions.jl"))
include(srcdir("modelling.jl"))
include(srcdir("hysteresisFunctions.jl"))

watts_networks = watts_strogatz(1000,5,0.1)
space = Agents.GraphSpace(watts_networks)

seeds = rand(0:5000,100)
decisionModel = model_decision_agents_SIR(mixed_population;space=space,seed = seeds[1],socialInfluenceFactor=2, switchingLimit=20)
agent_df, model_df = run!(decisionModel, agent_step_SIR!,model_step!, 500; adata = [:state,:affinity,:SIR_status])

CSV.write("C:\\Users\\stecheme\\Documents\\Social_Modelling\\saved_dataframes\\watts_100_steps.csv",agent_df)

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
