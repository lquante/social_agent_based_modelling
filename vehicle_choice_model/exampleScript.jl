# example script to show basic model setup
include("agentFunctions.jl")
include("modelling.jl")
include("populationCreation.jl")
include("visualization.jl")


# test with more agents

space = Agents.GridSpace((30, 30); periodic = true, metric = :euclidean)

mixedHugeGaia = model_car_owners(electric_minority;space=space,scenarios="vehicle_choice_model/example_scenario.yml")

# set random number seed

seed!(mixedHugeGaia,19956060601032517)


interactive_simulation(mixedHugeGaia,agent_step!,model_step!)

Agents.step!(mixedHugeGaia,agent_step!,model_step!,1)
