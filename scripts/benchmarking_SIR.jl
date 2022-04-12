# script to run huge ensemble simulations
using DrWatson
@quickactivate "Social Agent Based Modelling"
using ProgressMeter
using BenchmarkTools
using Graphs
include(srcdir("agentFunctions.jl"))
include(srcdir("modelling.jl"))

#small test of performance
spaceDims = (50,50)
graphspace = Agents.GraphSpace(SimpleGraph(2000,3000))
test = initialize_SIR(;seed=1234,space=graphspace)
tagent=test.agents[23]
neighbour=test.agents[27]

@benchmark agent_step_SIR!(tagent,test)
@benchmark model_step!(test,increasingSwitchingLimit)
@benchmark distributedInfection(1,tagent,test)
@code_warntype distributedInfection(1,tagent,test)

@benchmark state_social_influence(tagent,test)
@benchmark affinity_social_influence(tagent,test)
@benchmark combined_social_influence(tagent,test)

#maybe one can speed up the neighbourhood calcs for graphs, some performance bottleneck atm
@benchmark neigbourDistance(tagent,neighbour,test)

@code_warntype agent_step_SIR!(tagent,test)
@code_warntype affinity_social_influence(tagent,test)
@code_warntype model_step!(test)