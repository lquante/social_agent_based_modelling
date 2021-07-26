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
#incentives = [5000:100:10000;]
incentive_variable = :priceCombustionCar
incentives = [5050,6050,7050,8050,9050,10050]
#data frame for results

all_model_files = get_model_files("/p/projects/compacts/projects/DeMo/ensemble_900_agents/")
model_path = "/p/projects/compacts/projects/DeMo/ensemble_900_agents/"
#split files into chucks of max 100 files each
all_model_file_chunks = chunk(all_model_files, 100)

run_number =3
for  i = 1:length(all_model_file_chunks)
    chunk_number = i
    for inc in incentives
        #where we wanna store the stuff
        runpath = datadir("/p/projects/compacts/projects/DeMo/hysteresis_900"*string(run_number))
        mkpath(runpath)
        schedule_script(script=scriptsdir("hysteresis_batch_server.jl")*" $model_path"*" $incentive_variable"*" $inc"*" $runpath"*" $chunk_number",workdir=runpath)
    end
end
