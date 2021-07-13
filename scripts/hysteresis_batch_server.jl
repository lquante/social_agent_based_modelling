using DrWatson
@quickactivate "Social Agent Based Modelling"
include(srcdir("agentFunctions.jl"))
include(srcdir("modelling.jl"))
include(srcdir("populationCreation.jl"))
include(srcdir("visualization.jl"))
include(srcdir("hysteresisFunctions.jl"))
include(srcdir("slurm.jl"))


perform_incentive_hysteresis(ARGS[1],ARGS[2],ARGS[3],ARGS[4])
