# example script to show basic model setup
include("agentFunctions.jl")
include("modelling.jl")
include("populationCreation.jl")
include("visualization.jl")


gaiaOeconomicus = model_car_owners(combustion_population)

diverseGaia = model_car_owners(electric_minority)

interactive_simulation(diverseGaia,agent_step!,model_step!)

Agents.step!(gaiaOeconomicus,agent_step!,model_step!,1) # stepping to test, wheither model setup is working


# test with more agents

space = Agents.GridSpace((100, 100); periodic = false, metric = :euclidean)

mixedHugeGaia = model_car_owners(mixed_population;space=space)

interactive_simulation(mixedHugeGaia,agent_step!,model_step!)
