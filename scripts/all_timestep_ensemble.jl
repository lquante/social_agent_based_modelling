using DrWatson
using Printf
@quickactivate "Social Agent Based Modelling"

using Distributed

nprocs = 1 #floor(Int, length(Sys.cpu_info())/4) # get number of available physical CPUS
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

function Simulate(;mu=0.5, sigma=0.1, kwargs...)

    seeds = collect(100:109) #less seeds
    parameters = Dict(:seed => seeds, :mean => mu, :sigma => sigma,)
    mdata = [:seed,:lambda]
    adata = [:attitude,:self_reliance,:fixed_attitude]
    timesteps = 1000
    function shouldSaveData(model, s)
        return true #safe at every timepoint
    end

    
    ensemble_agent_data_frame, ensemble_model_data = paramscan(parameters, initialize; 
        adata, agent_step!, model_step!, parallel=false, n=timesteps, when=shouldSaveData)

    parameter_str = @sprintf "mu-%.2f_sigma-%.3f" mu sigma
    stringkey = "data_normal-self_reliance_" * parameter_str

    filename = "agent_" * stringkey * ".csv" 
    CSV.write(datadir("all_timestep_ensemble", filename), ensemble_agent_data_frame)
    #filename = "model_" * stringkey * ".csv" 
    #CSV.write(datadir("initial_attitude_fixed_ensembles", filename), ensemble_model_data)
end

# define parameter ranges
mu_range = collect(range(0.45, 0.95, step=0.1))
sigma_range = collect(range(0.05, 0.20, step=0.05))
# call simulations
for mu_p in mu_range
    for sigma_p in sigma_range
        @printf "Simulation running with normal distributed self-reliance mu=%.2f, sigma=%.3f\n" mu_p sigma_p
        Simulate(;mu=mu_p, sigma=sigma_p)
    end
end
