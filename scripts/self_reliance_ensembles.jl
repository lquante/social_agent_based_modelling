using DrWatson
using Printf
@quickactivate "Social Agent Based Modelling"

using Distributed

nprocs = floor(Int, length(Sys.cpu_info())/4) # get number of available physical CPUS
addprocs(nprocs - 1; exeflags="--project")
# avoiding non-initialized project on the distributed workers 
# (https://stackoverflow.com/questions/60934852/why-does-multiprocessing-julia-break-my-module-import)

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

function Simulate(;mean=0.5, sigma=0.1, kwargs...)
    
    @everywhere begin
        mean = mean
        sigma = sigma
        seeds = collect(100:109)
        parameters = Dict(:seed => seeds, :mean => mean, :sigma => sigma,)
        mdata = [:seed,:lambda]
        adata = [:attitude,:self_reliance,:fixed_attitude]
        timesteps = 1000
    end
    
    @everywhere function shouldSaveData(model, s)
        return s % 1000 == 0
    end    
    
    ensemble_agent_data_frame, ensemble_model_data = paramscan(parameters, initialize; 
        adata, agent_step!, model_step!, parallel=true, n=timesteps, when=shouldSaveData)

    parameter_str = @sprintf "mean-%.2f_sigma-%.2f" mean sigma
    stringkey = "data_normal-self_reliance_" * parameter_str

    filename = "agent_" * stringkey * ".csv" 
    CSV.write(datadir("self_reliance_ensembles", filename), ensemble_agent_data_frame)
    filename = "model_" * stringkey * ".csv" 
    CSV.write(datadir("paramstest", filename), ensemble_model_data)
end

# define parameter ranges
mean = collect(range(0.05, 0.95, step=0.05))
sigma = collect(range(0.01, 0.2, step=0.01))

# call simulations
for (index, parameters) in enumerate(zip(mean, sigma))
    mean, sigma = parameters   
    @printf "Simulation running with normal distributed self-reliance mean=%.2f, sigma=%.2f\n" mean sigma
    Simulate(;mean=mean, sigma=sigma)
end
