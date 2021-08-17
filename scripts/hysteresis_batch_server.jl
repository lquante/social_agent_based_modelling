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
print(ARGS[5])

all_model_files = get_model_files(ARGS[1])


#split files into chucks of max 100 files each
all_model_file_chunks = chunk(all_model_files, 100)

#pick the relevant chunk for this job

local_file_list = all_model_file_chunks[parse(Int,ARGS[5])]
println(local_file_list)

perform_incentive_hysteresis(local_file_list,ARGS[2],parse(Float64,ARGS[3]),ARGS[4];batch_number =parse(Int,ARGS[5]),step_length = 1000,convergence_stop=false )
