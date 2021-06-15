# example script to show basic model setup
include("agentFunctions.jl")
include("modelling.jl")
include("populationCreation.jl")
include("visualization.jl")
using Random

# set random number seed
rng = Random.seed!(1234)
Random.seed!(1234)
# create model with lots of agents
mixedHugeGaia = model_car_owners(mixed_population;rng=rng,space=Agents.GridSpace((100, 100); periodic = true, metric = :euclidean),scenarios="vehicle_choice_model/example_scenario.yml")

# if you want to to an interactive simulation, run this line
interactive_simulation(mixedHugeGaia,agent_step!,model_step!)

#video recording
video_recording(mixedHugeGaia,agent_step!,model_step!,"test.mp4","Test model for scenario")

#single step for debugging
Agents.step!(mixedHugeGaia,agent_step!,model_step!,1)
