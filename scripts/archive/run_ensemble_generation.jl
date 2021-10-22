using Distributed
@everywhere using DrWatson
@everywhere @quickactivate "Social Agent Based Modelling"
@everywhere include(srcdir("agentFunctions.jl"))
@everywhere include(srcdir("modelling.jl"))
@everywhere include(srcdir("populationCreation.jl"))
@everywhere include(srcdir("hysteresisFunctions.jl"))
@everywhere include(srcdir("slurm.jl"))

Random.seed!(1234)

p_normal_dist = truncated(Normal(0.5, 0.05), 0.3, 0.6)
p_range = rand(p_normal_dist, 100)
plot_combustion_share_histogram(p_range, plotsdir("histogram_p_shares.png"))
run_index = 0
for p in p_combustion_range
    global run_index +=1
    params = (run=run_index,p=p)
    runpath = datadir(savename("10k_model_generation_",params;digits=10))
    mkpath(runpath)
    schedule_script(script=scriptsdir("run_single_model_generation.jl")*" $p",workdir=runpath,memory=16000,time="0-12:00:00")
end
