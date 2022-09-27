using DrWatson
@quickactivate "Social Agent Based Modelling"
using Distributed
numberCPUS = floor(Int, length(Sys.cpu_info())/4) # get number of available physical CPUS
addprocs(numberCPUS-1; exeflags="--project") # avoiding non-initialized project on the distributed workers (https://stackoverflow.com/questions/60934852/why-does-multiprocessing-julia-break-my-module-import)

using Printf

@everywhere begin
	using DrWatson
	using Agents, Random, Graphs
	using CSV
	include(srcdir("agentFunctions.jl"))
	include(srcdir("modelling.jl"))
	arguments = ["100"] #default 100 runs, need to figure out how to share ARGS between distributed processes
	#create random ensemble with ARGS[1] members:
	seeds = rand((0:10000),parse(Int, arguments[1]))
	parameters = Dict(:seed => seeds)
	mdata = [:seed,:tauSocial]
	adata = [:affinity,:avantgarde,:affinityGoal]
	timesteps = 200
end
# perform parameter scan for varying random seeds
ensemble_agent_data_frame, ensemble_model_data = paramscan(parameters, initialize; adata, agent_step! =agent_step!, model_step!, n=timesteps, parallel=true)

filename = "uniform_parameters_agent_data.csv" 
CSV.write(datadir("uniform_parameters", filename), ensemble_agent_data_frame)
filename = "uniform_parameters_model_data.csv" 
CSV.write(datadir("uniform_parameters", filename), ensemble_model_data)