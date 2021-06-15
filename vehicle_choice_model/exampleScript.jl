# example script to show basic model setup
include("agentFunctions.jl")
include("modelling.jl")
include("populationCreation.jl")
include("visualization.jl")


# test with more agents


mixedHugeGaia = model_car_owners(mixed_population;space=Agents.GridSpace((30, 30); periodic = true, metric = :euclidean),scenarios="vehicle_choice_model/example_scenario.yml")

# set random number seed

seed!(mixedHugeGaia,19956060601032517)


interactive_simulation(mixedHugeGaia,agent_step!,model_step!)

video_recording(mixedHugeGaia,agent_step!,model_step!,"test.mp4","Test model for scenario")

Agents.step!(mixedHugeGaia,agent_step!,model_step!,1)
