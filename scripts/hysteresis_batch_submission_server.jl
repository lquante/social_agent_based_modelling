using Distributed
@everywhere using DrWatson
@everywhere @quickactivate "Social Agent Based Modelling"
@everywhere using Pkg
@everywhere Pkg.instantiate()
@everywhere include(srcdir("agentFunctions.jl"))
@everywhere include(srcdir("modelling.jl"))
@everywhere include(srcdir("populationCreation.jl"))
@everywhere include(srcdir("hysteresisFunctions.jl"))


#set price for incentive
incentive_variable = :priceCombustionCar
#incentives = [5000:100:10000;]
incentive_variable = :priceCombustionCar
incentives = [5050]
#data frame for results

all_model_files = get_model_files("/p/projects/compacts/projects/DeMo/ensemble_900_agents")

#split files into chucks of max 100 files each
all_model_file_chunks = chunk(all_model_files, 100)

run_number =1
for  file_chunk in all_model_file_chunks
    for inc in incentives
        #where we wanna store the stuff
        runpath = datadir("/p/projects/compacts/projects/DeMo/hysteresis_900"*string(run_number))
        mkpath(runpath)
        #put in test script and some parameters
        schedule_script(script=scriptsdir("hysteresis_batch_server.jl $file_chunk $inc $incentive_variable $runpath"),workdir=runpath)
    end
end
