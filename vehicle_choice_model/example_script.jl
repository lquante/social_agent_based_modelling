include("agent_functions.jl")
include("modelling.jl")
include("population_creation.jl")
include("visualization.jl")


gaiaOeconomicus = modelHomoOeconomicus(create_combustion_population)
gaiaMixedOeconomicus = modelHomoOeconomicus(create_mixed_population)
gaiaMinority = modelHomoOeconomicus(create_electric_minority)

interactive_simulation(gaiaOeconomicus,agent_step!,model_step!)
