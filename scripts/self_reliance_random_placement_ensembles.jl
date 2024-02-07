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

function Simulate(;mu=0.5, sigma=0.1 placement_probability=1.0, kwargs...)

    seeds = collect(100:199)
    parameters = Dict(:seed => seeds, :mean => mu, :sigma => sigma, :placement_probability => placement_probability)
    mdata = [:seed,:lambda]
    adata = [:attitude,:self_reliance,:fixed_attitude]
    timesteps = 1000
    function shouldSaveData(model, s)
        return s % timesteps == 0
    end

    
    ensemble_agent_data_frame, ensemble_model_data = paramscan(parameters, initalize_placement; 
        adata, agent_step!, model_step!, parallel=false, n=timesteps, when=shouldSaveData)

    parameter_str = @sprintf "mu-%.2f_sigma-%.3f_placement prob p=%.2f" mu sigma placement_probability
    stringkey = "data_random_placement_normal-self_reliance_" * parameter_str

    filename = "agent_" * stringkey * ".csv" 
    CSV.write(datadir("initial_attitude_fixed_ensembles", filename), ensemble_agent_data_frame)
    filename = "model_" * stringkey * ".csv" 
    CSV.write(datadir("initial_attitude_fixed_ensembles", filename), ensemble_model_data)
end

# define parameter ranges
mu_range = collect(range(0.35, 0.95, step=0.1))
sigma_range = collect(range(0.05, 0.20, step=0.1))
placement_probability_range = collect(range(0.5, 0.96, step=0.05))
# call simulations
for mu_p in mu_range
    for sigma_p in sigma_range
        for placement_probability in placement_probability_range
        @printf "Simulation running with normal distributed self-reliance mu=%.2f, sigma=%.3f\n and placement prob p=%.2f" mu_p sigma_p placement_probability
        Simulate(;mu=mu_p, sigma=sigma_p, placement_probability=placement_probability)
        end
    end
end
