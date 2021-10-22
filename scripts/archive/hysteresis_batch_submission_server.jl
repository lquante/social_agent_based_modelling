using Distributed
@everywhere using DrWatson
@everywhere @quickactivate "Social Agent Based Modelling"
@everywhere include(srcdir("agentFunctions.jl"))
@everywhere include(srcdir("modelling.jl"))
@everywhere include(srcdir("populationCreation.jl"))
@everywhere include(srcdir("hysteresisFunctions.jl"))
@everywhere include(srcdir("slurm.jl"))

#set price for incentive
incentive_variable = :priceCombustionCar
incentives = [5050]
#data frame for results

model_path = datadir("scaled_distance_models_10000")
all_model_files = get_model_files(model_path)
#split files into chucks of max 50 files each
all_model_file_chunks = chunk(all_model_files, 50)
run_number = 0
for  i in 1:length(all_model_file_chunks)
    chunk_number = i
    for inc in incentives
        #where we wanna store the stuff
        runpath = datadir("hysteresis_10000_"*string(run_number))
        params = @ntuple chunk_number inc
        jobname=savename("hysteresis",params)
        mkpath(runpath)
        schedule_script(script=scriptsdir("hysteresis_batch_server.jl")*" $model_path"*" $incentive_variable"*" $inc"*" $runpath"*" $chunk_number",
        workdir=runpath,time="0-24:00:00",jobname="")
    end
end
