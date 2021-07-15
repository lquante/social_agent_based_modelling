using DrWatson
@quickactivate "Social Agent Based Modelling"
include(srcdir("agentFunctions.jl"))
include(srcdir("modelling.jl"))
include(srcdir("populationCreation.jl"))
include(srcdir("hysteresisFunctions.jl"))
include(srcdir("slurm.jl"))

Random.seed!(1234)
seeds = rand(1234:9999,100)

#set combustion share
#sample p_combustion from uniform distribution
#p_combustion_range=range(0, 1, length=50)
#sample p_combustion from normal distribution
p_normal_dist = truncated(Normal(0.5, 0.05), 0.3, 0.6)
p_combustion_range = rand(p_normal_dist, 100)
plot_combustion_share_histogram(p_combustion_range, plotsdir("histogram_p_combustion.png"))
run_index = 0
for p in p_combustion_range
    global run_index +=1
    params = (run=run_index,p=p)
    runpath = datadir(savename("model_generation_",params;digits=10))
    mkpath(runpath)
    schedule_script(script=scriptsdir("run_single_model_generation.jl")*" $p",workdir=runpath,memory=16000,time="0-02:00:00")
end
