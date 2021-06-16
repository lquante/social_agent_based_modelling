# example script to run basic model setup interactivly
include("../agentFunctions.jl")
include("../modelling.jl")
include("../populationCreation.jl")
include("../visualization.jl")


# set random number seed
seed = 4321
# create moderatly sized model for interactive run
# defaults: starting with 50/50 population
mixedHugeGaia = model_car_owners(mixed_population;seed=seed,space=Agents.GridSpace((50, 50); periodic = true, metric = :euclidean))

# if you want to start an interactive simulation, run this line
interactive_simulation(mixedHugeGaia,agent_step!,model_step!,heatarray=get_affinity_matrix)
