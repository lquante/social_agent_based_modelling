# script to run huge ensemble simulations
using Distributed
using ProgressMeter
using BenchmarkTools
using Profile
using Random
using Traceur

include("../agentFunctions.jl")
include("../modelling.jl")
include("../populationCreation.jl")
#end
# create initialize function for model creation, needed for paramscan methods:

function initialize(;args ...)
    return model_car_owners(mixed_population;args ...)
end

# generate multiple models with different seeds

#small test of performance
spaceDims = (100,100)
test = initialize(;seed=1234,space=Agents.GridSpace(spaceDims;periodic=true,metric = :euclidean))
tagent=test.agents[23]

@benchmark agent_step!(tagent,test)
@benchmark old_state_social_influence(tagent,test,2)
@benchmark state_social_influence(tagent,test,2)

@benchmark init_test = initialize(;seed=1234,space=Agents.GridSpace(spaceDims;periodic=true,metric = :euclidean))
