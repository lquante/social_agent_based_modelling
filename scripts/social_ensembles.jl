using DrWatson
@quickactivate "Social Agent Based Modelling"
using Distributed
numberCPUS = floor(Int, length(Sys.cpu_info())/4) # get number of available physical CPUS
addprocs(numberCPUS-1; exeflags="--project") # avoiding non-initialized project on the distributed workers (https://stackoverflow.com/questions/60934852/why-does-multiprocessing-julia-break-my-module-imports)

@everywhere begin
    using DrWatson
    using Agents, Random, Graphs
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

    node_number = 10000 # number of nodes in the random networks
   
    #for testing
    watts_strogatz_space = Agents.GraphSpace(watts_strogatz(node_number,k,beta,seed=network_seeds[1]))
    barabasi_albert_space = Agents.GraphSpace(barabasi_albert(node_number,2,seed=network_seeds[1]))
    dorogovtsev_mendes_space = Agents.GraphSpace(dorogovtsev_mendes(node_number,seed=network_seeds[1]))



# range for array of varying tauSocials
    tauSocialVariation = range(0.5, 2.5, step=1)

# set parameters to be varied in the ensemble
    parameters = Dict(
        :space => Dict(:barabasi_albert => barabasi_albert_space,:dorogovtsev_mendes => dorogovtsev_mendes),
        :switchingLimit => [node_number*0.005], # assuming that 0.5 percent of population can be vaccinated per timestep
        #:schedulerIndex => [1], #only standard fastest scheduler by agent id, no affinity ordering (index 2) or lowAffinityFirst (index 3)
        #:neighbourhoodExtent => 1,
        :tauSocial => [i for i in tauSocialVariation],
        :switchingBoundary => [0.5,0.7,0.9], #varying vaccine decision boundary to check for sensitivity
    )
    # data to be tracked for each agent
    adata = [:affinity,:SIR_status]
end
timesteps = 500
# perform parameter scan for varying models
ensemble_agent_data_frame, ensemble_model_data = paramscan(parameters, initialize; adata,agent_step! = agent_step_SIR_latent!,model_step!, n = timesteps, parallel = true)
# safe to datadir
#identify by date
using Dates
date = Dates.now()
identifier = "social_ensemble_"*string(date)*".csv"
CSV.write(datadir(identifier),ensemble_agent_data_frame)