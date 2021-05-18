# example script to show basic model setup
include("agent_functions.jl")
include("modelling.jl")
include("population_creation.jl")
include("visualization.jl")


gaiaOeconomicus = modelVehicleOwners(create_combustion_population)

diverseGaia = modelVehicleOwners(create_electric_minority)

interactive_simulation(diverseGaia,agent_step!,model_step!)

Agents.step!(gaiaOeconomicus,agent_step!,model_step!,1) # stepping to test, wheither model setup is working


# test with more agents

space = Agents.GridSpace((100, 100); periodic = false, metric = :euclidean)

mixedHugeGaia = modelVehicleOwners(create_mixed_population;space=space)

interactive_simulation(mixedHugeGaia,agent_step!,model_step!)
