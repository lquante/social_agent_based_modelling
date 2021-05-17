# example script to show basic model setup
include("agent_functions.jl")
include("modelling.jl")
include("population_creation.jl")
include("visualization.jl")


gaiaOeconomicus = modelHomoOeconomicus(create_combustion_population)

diverseGaia = modelHomoOeconomicus(create_electric_minority)

interactive_simulation(diverseGaia,agent_step!,model_step!)

Agents.step!(diverseGaia,agent_step!,model_step!,1) # stepping to test, wheither model setup is working
