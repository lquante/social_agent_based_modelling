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

function Simulate(;low_self_reliance=0.5,share_low_self_reliance=0.95,high_self_reliance=0.95, kwargs...)

    seeds = collect(100:109)
    parameters = Dict(:seed => seeds, :two_levels_self_reliance => true,
    :low_self_reliance => low_self_reliance,:share_low_self_reliance => share_low_self_reliance,
    :high_self_reliance => high_self_reliance)
    mdata = [:seed,:lambda]
    adata = [:attitude,:self_reliance,:fixed_attitude]
    timesteps = 1000
    function shouldSaveData(model, s)
        return s % 1000 == 0
    end

    
    ensemble_agent_data_frame, ensemble_model_data = paramscan(parameters, initialize; 
        adata, agent_step!, model_step!, parallel=false, n=timesteps, when=shouldSaveData)

    parameter_str = @sprintf "low_share-%.2f_low-%.2f_high-%.2f" share_low_self_reliance low_self_reliance  high_self_reliance
    stringkey = "data_two_group-self_reliance_" * parameter_str

    filename = "agent_" * stringkey * ".csv" 
    CSV.write(datadir("grouped_self_reliance_ensembles", filename), ensemble_agent_data_frame)
    filename = "model_" * stringkey * ".csv" 
    CSV.write(datadir("grouped_self_reliance_ensembles", filename), ensemble_model_data)
end

# define parameter ranges
low_share_range = [0.8,0.9,0.95,0.99]
low_range = [0.5]
high_range = [0.9,0.95,0.99]
# call simulations
for low_share in low_share_range
    for low in low_range
        for high in high_range
            @printf "Simulation running with grouped self-reliance low_share-%.2f low-%.2f high-%.2f\n" low_share low  high
            Simulate(;low_self_reliance=low,share_low_self_reliance=low_share,high_self_reliance=high)
        end
    end
end
