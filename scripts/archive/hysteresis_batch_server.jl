using Distributed
@everywhere using DrWatson
@everywhere @quickactivate "Social Agent Based Modelling"
@everywhere include(srcdir("agentFunctions.jl"))
@everywhere include(srcdir("modelling.jl"))
@everywhere include(srcdir("populationCreation.jl"))
@everywhere include(srcdir("hysteresisFunctions.jl"))
@everywhere include(srcdir("slurm.jl"))

println(ARGS[1])
print("Arg 2 ")
println(ARGS[2])
print("Arg 3 ")
println(ARGS[3])
print("Arg 4 ")
println(ARGS[4])
print("Arg 5 ")
println(ARGS[5])

all_model_files = get_model_files(ARGS[1])

# random shuffle of the model files to equalibrate runtime of simulations
Random.seed!(1234)
shuffled_model_files = shuffle(all_model_files)

#split files into chucks of max 50 files each
model_file_chunks = chunk(shuffled_model_files, 50)

#pick the relevant chunk for this job

local_file_list = model_file_chunks[parse(Int,ARGS[5])]
println(local_file_list)

perform_incentive_hysteresis(local_file_list,ARGS[2],parse(Float64,ARGS[3]),ARGS[4];batch_number =parse(Int,ARGS[5]) )
