using Distributed
@everywhere using DrWatson
@everywhere @quickactivate "Social Agent Based Modelling"
@everywhere include(srcdir("hysteresisFunctions.jl"))

path = ARGS[1] # get path via script argument

if (ispath(path)==false)
    warn("Please specify a valid path!")
end
data = load_results_data(path)
ensembleidentifier = ARGS[2]
plotpath = plotsdir(ensembleidentifier)
mkpath(plotpath)
plot_multi_incentive_scatter(data,joinpath(plotpath,"scatter"))
