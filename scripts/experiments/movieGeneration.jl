# script to create videos of model evolution
using DrWatson
@quickactivate "Social Agent Based Modelling"
include(srcdir("vehicle_choice_model/agentFunctions.jl"))
include(srcdir("vehicle_choice_model/modelling.jl"))
include(srcdir("vehicle_choice_model/populationCreation.jl"))
include(srcdir("vehicle_choice_model/visualization.jl"))
# set random number seed
seed = 1234
# create normal sized model for interactive run
# defaults: starting with 50/50 population
mixedHugeGaia = model_car_owners(mixed_population;seed=seed,space=Agents.GridSpace((1000, 1000); periodic = true, metric = :euclidean))
#video recording of simulation, heatmap of affinity still experimental
path = "vehicle_choice_model/experiments/videos/test.mp4"
title = "Test video"
video_recording(mixedHugeGaia,agent_step!,model_step!,path,title,as=3,frames=1000,framerate=50,resolution = (600, 600),heatarray=get_affinity_matrix)
