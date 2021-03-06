using DrWatson
@quickactivate "Social Agent Based Modelling"
using Distributed
numberCPUS = floor(Int, length(Sys.cpu_info())/2) # get number of available physical CPUS
addprocs(numberCPUS-1; exeflags="--project") # avoiding non-initialized project on the distributed workers (https://stackoverflow.com/questions/60934852/why-does-multiprocessing-julia-break-my-module-imports)

@everywhere begin
    using DrWatson
    using Agents, Random, DataFrames, LightGraphs
    using Distributions: Poisson, DiscreteNonParametric
    using GraphPlot
    using DelimitedFiles
    using CSV
    include(srcdir("agentFunctions.jl"))
    include(srcdir("modelling.jl"))

    Random.seed!(1234)

    # define model(s) to be used
    network_number = 1
    network_seeds = rand((0:10000),network_number)

    ensemble_spaces = [] #TODO: define properly typed container
    #network params
    k = 10 # number of neighbours of each node before randomization if even, otherwise k-1
    beta = 0.8 # probability for an edge to be rewired to another node, i.e.  a share beta of edges will be rewired



    node_number = 1000 # number of nodes in the random networks
    #for testing
    barabasi_albert_space = Agents.GraphSpace(barabasi_albert(node_number,k,5))
    dorogovtsev_mendes_space = Agents.GraphSpace(dorogovtsev_mendes(node_number))


    for i_seed in network_seeds
        push!(ensemble_spaces,Agents.GraphSpace(watts_strogatz(node_number,k,beta,seed=i_seed)))
    end

# range for array of varying tauSocials
    tauSocialVariation = range(0.25, 2.5, step=0.025)

# set parameters to be varied in the ensemble
    parameters = Dict(
        :space => dorogovtsev_mendes_space,
        :switchingLimit => [node_number*0.01], # assuming that 1 percent of population can be vaccinated per timestep
        #:schedulerIndex => [1], #only standard fastest scheduler by agent id, no affinity ordering (index 2) or lowAffinityFirst (index 3)
        #:neighbourhoodExtent => 1,
        :tauSocial => [i for i in tauSocialVariation],
        :tauRational => 1,
        #:switchingBoundary => [0.5], #varying vaccine decision boundary to check for sensitivity
        :seed => 1910, # fixed seed to to enough variation by network composition
    )
    # data to be tracked for each agent
    adata = [:affinity,:state]
end
timesteps = 500
# perform parameter scan for varying models
ensemble_agent_data_frame, ensemble_model_data = paramscan(parameters, initialize; adata,agent_step! = agent_step!,model_step!, n = timesteps, parallel = true)
# safe to datadir
#identify by date
using Dates
date = Dates.now()
identifier = "social_ensemble_dorogotsev_"*string(date)*".csv"
CSV.write(datadir(identifier),ensemble_agent_data_frame)