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

    # path = $path    

    include(srcdir("agentFunctions.jl"))
    include(srcdir("modelling.jl"))
end

function Simulate(;alpha=0.0, beta=0.0, beta_mean=0.0, kwargs...)
    
    @everywhere begin
        alpha = $alpha
        beta = $beta
        seeds = collect(100:109)
        parameters = Dict(:seed => seeds, :alpha => alpha, :beta => beta,)
        mdata = [:seed,:tauSocial]
        adata = [:affinity,:avantgarde,:affinityGoal]
        timesteps = 1000
    end
    
    @everywhere function shouldSaveData(model, s)
        return s % 1000 == 0
    end    
    
    ensemble_agent_data_frame, ensemble_model_data = paramscan(parameters, initialize; 
        adata, agent_step!, model_step!, parallel=true, n=timesteps, when=shouldSaveData)

    parameter_str = @sprintf "a-%.2f_b-%.2f_m-%.2f" alpha beta beta_mean
    stringkey = "data_beta-affinity_" * parameter_str

    filename = "agent_" * stringkey * ".csv" 
    CSV.write(datadir("paramstest", filename), ensemble_agent_data_frame)

    filename = "model_" * stringkey * ".csv" 
    # CSV.write(datadir("paramstest", filename), ensemble_model_data)
end

# define parameter ranges
mm = collect(range(0.1, 0.9, step=0.1))
c = 5
aa = [m <= 0.5 ? c : c * m / (1 - m) for m in mm]
bb = [m > 0.5 ? c : c * (1- m) / m for m in mm]

# call simulations
for (index, parameters) in enumerate(zip(mm, aa, bb))
    m, alpha, beta = parameters
    
    # logging    
    @printf "Simulation running with parameters m=%.2f, alpha=%.2f, beta=%.2f\n" m alpha beta

    Simulate(;alpha=alpha, beta=beta, beta_mean=m)
end
