# script to submit multiple jobs via scheduling to HPC
using DrWatson
@quickactivate "Social Agent Based Modelling"
include(srcdir("slurm.jl"))

numberOfJobs = 10
for i in 1:numberOfJobs
    #where we wanna store the stuff
    runpath = datadir("test_run_"*string(i))
    mkpath(runpath)
    #put in test script and some parameters
    schedule_script(script=scriptsdir("test.jl paramA paramB"),workdir=runpath)
end
