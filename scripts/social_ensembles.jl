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

    #Random.seed!(101)

    ## define model(s) to be used
    #network_number = 1
    #network_seeds = rand((0:10),network_number)

    #ensemble_spaces = [] #TODO: define properly typed container
    ##network params
    #k = 10 # number of neighbours of each node before randomization if even, otherwise k-1
    #beta = 0.8 # probability for an edge to be rewired to another node, i.e.  a share beta of edges will be rewired

    node_number = 100 # number of nodes in the random networks
   
    ##for testing
    # watts_strogatz_space = Agents.GraphSpace(watts_strogatz(node_number,k,beta,seed=network_seeds[1]))
    # barabasi_albert_space = Agents.GraphSpace(barabasi_albert(node_number,2,seed=network_seeds[1]))
    # dorogovtsev_mendes_space = Agents.GraphSpace(dorogovtsev_mendes(node_number,seed=network_seeds[1]))
    
    spaceDims = (20, 20)
    grid_space = Agents.GridSpace(spaceDims; periodic = true, metric = :chebyshev)


    # range for array of varying tauSocials
    # tauSocialVariation = range(0., 2.5, step=1)

    # set parameters to be varied in the ensemble
    parameters = Dict(
        :space => [grid_space],
        :constantAvantgarde => 0.0,
        :switchingLimit => [Inf], # assuming that 0.5 percent of population can be vaccinated per timestep
        :schedulerIndex => [1], #only standard fastest scheduler by agent id, no affinity ordering (index 2) or lowAffinityFirst (index 3)
        :neighbourhoodExtent => 1,
        :tauSocial => [0.5],
        :switchingBoundary => [0.9], #varying vaccine decision boundary to check for sensitivity,
    )
    # data to be tracked for each agent
    adata = [:affinity,:state,:avantgarde]
end

function GetMeanAffinity(model)
    summedAffinity = 0.0
    counts = 0
    for agentPair in getproperty(model, :agents)
        agent = agentPair.second
        summedAffinity += agent.affinity
        counts += 1
    end
    return summedAffinity / counts
end

function GetStandardDeviationAffinity(model, mean)
    summedDeltaAffinity = 0.0
    counts = 0
    for agentPair in getproperty(model, :agents)
        agent = agentPair.second
        diff = (agent.affinity - mean)
        summedDeltaAffinity += diff * diff
        counts += 1
    end
    return sqrt(summedDeltaAffinity / counts)
end


spaceDims = (100, 100)
grid_space = Agents.GridSpace(spaceDims; periodic = true, metric = :chebyshev)
a = 0.0
tau = 10.0
threshold = 0.9
seedNumber = parse(Int, ARGS[1])
model = initialize(;seed=seedNumber, space=grid_space, constantAvantgarde=a, tauSocial=tau, switchingBoundary=threshold) 
mdata = [:constantAvantgarde,:tauSocial,:switchingBoundary]
adata = [:affinity,:avantgarde]
df_agent = init_agent_dataframe(model, adata)
df_model = init_model_dataframe(model, mdata)

timesteps = 600
collectTime = 4
firstSteps = 0
global c = 0 # counter
global k = 0 # collect counter
while c < timesteps
    if k <= 0 || c <= firstSteps # record first steps
        collect_agent_data!(df_agent, model, adata, c)
        collect_model_data!(df_model, model, mdata, c)
        if k <= 0
            k = collectTime
        end
        # display(get_affinity_matrix(model))
        mean = GetMeanAffinity(model)
        stdv = GetStandardDeviationAffinity(model, mean)
        @printf "Step %2i:   Affinity: %.5f +- %.5f \n" c mean stdv   
    end
    step!(model, agent_step!, model_step!, 1)
    global c += 1
    global k -= 1
end

###
# perform parameter scan for varying models
# ensemble_agent_data_frame, ensemble_model_data = paramscan(parameters, initialize; adata, agent_step!=agent_step!, model_step!, n=timesteps, parallel=true)

# safe to datadir
# identify by date
using Dates
date = Dates.now()
identifierAgent = "data_avantgarde-uniform-0.3_affinity-uniform" * string(seedNumber) * ".csv" # "data_Np-25_Nf-x_No-25_mix_real_tau-10.0_ap-0.5_ao-0.5_init-beta-4.0-4.0_seed_" * string(seedNumber) * ".csv" # "data_metric=chebyshev_avantgarde=n=100_tau=1.50_step=25.csv"
CSV.write(datadir("avantgarde/po100k", identifierAgent), df_agent)
