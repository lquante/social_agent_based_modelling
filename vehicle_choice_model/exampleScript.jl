# example script to show basic model setup
include("agentFunctions.jl")
include("modelling.jl")
include("populationCreation.jl")
include("visualization.jl")


diverseGaia = model_car_owners(mixed_population)

interactive_simulation(diverseGaia,agent_step!,model_step!)

Agents.step!(gaiaOeconomicus,agent_step!,model_step!,1) # stepping to test, wheither model setup is working


# test with more agents

space = Agents.GridSpace((30, 30); periodic = true, metric = :euclidean)

mixedHugeGaia = model_car_owners(electric_minority;space=space)

interactive_simulation(mixedHugeGaia,agent_step!,model_step!)
