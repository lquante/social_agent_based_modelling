using Distributed
@everywhere using DrWatson
@everywhere @quickactivate "Social Agent Based Modelling"
@everywhere include(srcdir("agentFunctions.jl"))
@everywhere include(srcdir("modelling.jl"))
@everywhere include(srcdir("populationCreation.jl"))
@everywhere include(srcdir("hysteresisFunctions.jl"))

Random.seed!(1234)

p_normal_dist = truncated(Normal(0.5, 0.05), 0.3, 0.6)
print(ARGS)
p_range = [parse(Float64,ARGS[1])]

generate_ensemble(p_range,datadir("scaled_distance_models_10000");step_length=50,gridsize = 100, models_per_p = 100,seeds = rand(1234:9999,100),store_model = true, model_directory = datadir("scaled_distance_models_10000"))
