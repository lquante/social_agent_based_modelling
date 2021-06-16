# script to create videos of model evolution
include("../agentFunctions.jl")
include("../modelling.jl")
include("../populationCreation.jl")
include("../visualization.jl")
using Random

# set random number seed
seed = 1234
#random number generatos are seeded
rng = Random.seed!(seed)
Random.seed!(seed)
# create normal sized model for interactive run
# defaults: starting with 50/50 population
mixedHugeGaia = model_car_owners(mixed_population;rng=rng,space=Agents.GridSpace((100, 100); periodic = true, metric = :euclidean))
#video recording of simulation, heatmap of affinity still experimental
path = "vehicle_choice_model/experiments/videos/test.mp4"
title = "Test video"
video_recording(mixedHugeGaia,agent_step!,model_step!,path,title,as=3,frames=1000,framerate=50,resolution = (600, 600),heatarray=get_affinity_matrix)
