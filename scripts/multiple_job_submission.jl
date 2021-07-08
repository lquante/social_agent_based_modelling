# script to submit multiple jobs via scheduling to HPC
using DrWatson
@quickactivate "Social Agent Based Modelling"
include(srcdir("slurm.jl"))

numberOfJobs = 10
for i in 1:numberOfJobs
    runpath = datadir("test_run_"*string(i))
    mkpath(runpath)
    schedule_script(script=scriptsdir("test.jl"),workdir=runpath)
end
