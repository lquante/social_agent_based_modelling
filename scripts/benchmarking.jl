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
@benchmark model_step!(test)
@benchmark old_state_social_influence(tagent,test,2)
@benchmark state_social_influence(tagent,test,2)
@benchmark init_test = initialize(;seed=1234,space=Agents.GridSpace(spaceDims;periodic=true,metric = :euclidean))

@benchmark mixed_population(test,10000,Inf)

test_vector = fill(1,10000000)
@benchmark conv_test = check_conversion(test_vector,1)
@benchmark conv_test_all = check_conversion_all(test_vector,1)
@benchmark conv_test_allequal = check_conversion_allequal(test_vector,1)

@benchmark osc_test = check_conversion_osc(test_vector,20)
@benchmark osc_test = check_conversion_osc_recursive(test_vector;pmax=20)


state_matrix = get_state_matrix(test)
@benchmark find_state_clusters(state_matrix)
labels, groups = find_state_clusters(state_matrix)
@benchmark cluster_sizes(groups)


@code_warntype initialize(;seed=1234,space=Agents.GridSpace(spaceDims;periodic=true,metric = :euclidean))
@code_warntype agent_step!(tagent,test)
@code_warntype old_state_social_influence(tagent,test,2)
@code_warntype state_social_influence(tagent,test,2)
