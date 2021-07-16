using Distributed
@everywhere using DrWatson
@everywhere @quickactivate "Social Agent Based Modelling"
@everywhere using Pkg
@everywhere Pkg.instantiate()
@everywhere include(srcdir("agentFunctions.jl"))
@everywhere include(srcdir("modelling.jl"))
@everywhere include(srcdir("populationCreation.jl"))
@everywhere include(srcdir("hysteresisFunctions.jl"))



perform_incentive_hysteresis(ARGS[1],ARGS[2],ARGS[3],ARGS[4])
