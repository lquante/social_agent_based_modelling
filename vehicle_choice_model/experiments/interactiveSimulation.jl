# example script to run basic model setup interactivly
include("../agentFunctions.jl")
include("../modelling.jl")
include("../populationCreation.jl")
include("../visualization.jl")
using Random

# set random number seed
seed = 1234
#random number generatos are seeded
rng = Random.seed!(seed)
Random.seed!(seed)
# create moderatly sized model for interactive run
# defaults: starting with 50/50 population
mixedHugeGaia = model_car_owners(mixed_population;rng=rng,space=Agents.GridSpace((50, 50); periodic = true, metric = :euclidean))

# if you want to start an interactive simulation, run this line
interactive_simulation(mixedHugeGaia,agent_step!,model_step!,heatarray=get_affinity_matrix)
