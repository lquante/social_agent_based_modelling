using DrWatson
using Printf
@quickactivate "Social Agent Based Modelling"

using Distributed

nprocs = 1#floor(Int, length(Sys.cpu_info())/4) # get number of available physical CPUS
addprocs(nprocs - 1; exeflags="--project")

@everywhere using DrWatson

@everywhere begin
    @quickactivate "Social Agent Based Modelling" 
    using Agents
    using Random
    using Graphs
    using CSV
    using Printf
    using Base
    include(srcdir("agentFunctions.jl"))
    include(srcdir("modelling.jl"))
end

function Simulate(;kwargs...)

    seeds = collect(100:199)
    parameters = Dict(:seed => seeds, :)
    mdata = [:seed,:lambda]
    adata = [:attitude,:self_reliance,:fixed_attitude]
    timesteps = 1000
    function shouldSaveData(model, s)
        return s % timesteps == 0
    end

    
    ensemble_agent_data_frame, ensemble_model_data = paramscan(parameters, initialize; 
        adata, agent_step!, model_step!, parallel=false, n=timesteps, when=shouldSaveData)

    stringkey = "data_uniform_distributed-self_reliance_"

    filename = "agent_" * stringkey * ".csv" 
    CSV.write(datadir("uniform_self_reliance_ensembles", filename), ensemble_agent_data_frame)
    filename = "model_" * stringkey * ".csv" 
    CSV.write(datadir("uniform_self_reliance_ensembles", filename), ensemble_model_data)
end


Simulate(;uniform_self_reliance =true)
end
