using Distributed
@everywhere using DrWatson
@everywhere @quickactivate "Social Agent Based Modelling"
@everywhere using Pkg
Pkg.instantiate()

@everywhere include(srcdir("hysteresisFunctions.jl"))

path = ARGS[1] # get path via script argument

if not (ispath(path))
    warn("Please specify a valid path!")
end
data = load_results_data(path)
ensembleidentifier = ARGS[2]
plotpath = plotsdir(ensembleidentifier)
plot_scatter(data,joinpath(plotspath,"scatter"))
plot_histogram(data,joinpath(plotspath,"histogram"))
