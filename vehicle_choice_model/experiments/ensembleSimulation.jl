# script to run huge ensemble simulations
using Distributed
using ProgressMeter
using BenchmarkTools
addprocs(Sys.CPU_THREADS-1)
@everywhere begin
    include("../agentFunctions.jl")
    include("../modelling.jl")
    include("../populationCreation.jl")
    include("../visualization.jl")
    using Random
end

# create initialize function for model creation, needed for paramscan methods:
@everywhere begin
    function initialize(;args ...)
        return model_car_owners(mixed_population;args ...)
    end
end
# generate multiple models with different seeds

@everywhere begin
    seeds = 1000:1009
    spaceDims = (100,100)
    ensemble =   [initialize(;seed=i_seed,space=Agents.GridSpace(spaceDims;periodic=true,metric = :euclidean)) for i_seed in seeds];
end

@benchmark (initialize(;seed=1234,space=Agents.GridSpace(spaceDims;periodic=true,metric = :euclidean)))

@everywhere adata = [(:state, mean),(:rationalOptimum, mean), (:carAge, mean),(:affinity, mean)]

adf, = ensemblerun!(ensemble, agent_step!, model_step!, 10; adata,parallel=true)
