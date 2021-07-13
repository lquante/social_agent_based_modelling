include("vehicle_choice_model\\agentFunctions.jl")
include("vehicle_choice_model\\modelling.jl")
include("vehicle_choice_model\\populationCreation.jl")
include("vehicle_choice_model\\visualization.jl")


gaiaOeconomicus = model_car_owners(combustion_population)

diverseGaia = model_car_owners(electric_minority,space = Agents.GridSpace((30, 30);periodic = true),tauSocial=1)

interactive_simulation(diverseGaia,agent_step!,model_step!)

Agents.step!(gaiaOeconomicus,agent_step!,model_step!,1) # stepping to test, wheither model setup is working
