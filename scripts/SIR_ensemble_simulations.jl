using DrWatson
@quickactivate "Social Agent Based Modelling"
using Distributed
numberCPUS = length(Sys.cpu_info()) # get number of available CPUS
addprocs(numberCPUS-1; exeflags="--project") # avoiding non-initialized project on the distributed workers (https://stackoverflow.com/questions/60934852/why-does-multiprocessing-julia-break-my-module-imports)

@everywhere begin
    using DrWatson
    using Agents, Random, DataFrames, LightGraphs
    using Distributions: Poisson, DiscreteNonParametric
    using GraphPlot
    using DelimitedFiles

    include(srcdir("agentFunctions.jl"))
    include(srcdir("modelling.jl"))
    include(srcdir("hysteresisFunctions.jl"))

    Random.seed!(1234)

    # define model(s) to be used
    network_number = 1000
    network_seeds = rand((0:10000),network_number)

    ensemble_spaces = [] #TODO: define properly typed container
    #network params
    k = 5 # number of neighbours of each node before randomization if even, otherwise k-1
    beta = 0.1 # probability for an edge to be not rewired to another node, i.e. 1-beta edges will be rewired
    node_number = 1000 # number of nodes in the random networks

    for i_seed in network_seeds
        push!(ensemble_spaces,Agents.GraphSpace(watts_strogatz(node_number,k,beta,seed=i_seed)))
    end

# set parameters to be varied in the ensemble
    parameters = Dict(
        :space => ensemble_spaces[1],
        :switchingLimit => node_number*0.01, # assuming that 1 percent of population can be vaccinated per timestep
        :schedulerIndex => [1], #only standard fastest scheduler by agent id, no affinity ordering (index 2) or lowAffinityFirst (index 3)
        :neighbourhoodExtent => 1,
        :socialInfluenceFactor => [0.5,1,1.5,2,2.5,3],
        :switchingBoundary => [0.5], #varying vaccine decision boundary to check for sensitivity
        :seed => 1910, # fixed seed to to enough variation by network composition
        #SIR parameters
        :detectionTime => [7],
        :initialInfected => [0.003], # estimated from German Data
        :deathRate => 0.03, # estimated from German Data
        :reinfectionProtection => 180,
        :transmissionUndetected => 0.2,
        :transmissionDetected => 0.02
    )

    # data to be tracked for each agent

    adata = [:state,:affinity,:SIR_status]
end

# perform parameter scan for varying models
ensemble_agent_data_frame, ensemble_model_data = paramscan(parameters, initialize_SIR; adata,agent_step! = agent_step_SIR!,model_step!, n = 100, parallel = true)
# safe to datadir
#identify by date
using Dates
date = Dates.now()
identifier = "ensemble_"*string(date)*".csv"
CSV.write(datadir(),ensemble_agent_data_frame)