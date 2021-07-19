using Distributed
@everywhere using DrWatson
@everywhere @quickactivate "Social Agent Based Modelling"
@everywhere using Pkg
Pkg.instantiate()
@everywhere include(srcdir("agentFunctions.jl"))
@everywhere include(srcdir("modelling.jl"))
@everywhere include(srcdir("populationCreation.jl"))
@everywhere include(srcdir("hysteresisFunctions.jl"))

Random.seed!(1234)

#set combustion share
#sample p_combustion from uniform distribution
#p_combustion_range=range(0, 1, length=50)
#sample p_combustion from normal distribution
p_normal_dist = truncated(Normal(0.5, 0.05), 0.3, 0.6)
print(ARGS)
p_combustion_range = [parse(Float64,ARGS[1])]

generate_ensemble(p_combustion_range,datadir();step_length=50,gridsize = 200, models_per_p = 50,seeds = rand(1234:9999,50),store_model = true, model_directory = datadir("preconverged_models_40000"))
