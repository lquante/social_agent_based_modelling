# script to run huge ensemble simulations
using DrWatson
@quickactivate "Social Agent Based Modelling"
using ProgressMeter
using BenchmarkTools

include(srcdir("agentFunctions.jl"))
include(srcdir("modelling.jl"))
include(srcdir("populationCreation.jl"))
include(srcdir("hysteresisFunctions.jl"))
include(srcdir("clusterDetection.jl"))

#small test of performance
spaceDims = (50,50)
test = initialize(;seed=1234,space=Agents.GridSpace(spaceDims;periodic=true,metric = :euclidean))
tagent=test.agents[23]

@benchmark agent_step!(tagent,test)
@benchmark agent_step!(tagent,test)
@benchmark model_step!(test)
@benchmark state_social_influence(tagent,test)
@benchmark affinity_social_influence(tagent,test)
@benchmark combined_social_influence(tagent,test)

@benchmark init_test = initialize(;seed=1234,space=Agents.GridSpace(spaceDims;periodic=true,metric = :euclidean))
@code_warntype neighbour_distance(test)
@benchmark neighbour_distance(test)



@code_warntype initialize(;seed=1234,space=Agents.GridSpace(spaceDims;periodic=true,metric = :euclidean))
@code_warntype agent_step!(tagent,test)
@code_warntype state_social_influence(tagent,test)
