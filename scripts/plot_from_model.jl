using Distributed
@everywhere using DrWatson
@everywhere @quickactivate "Social Agent Based Modelling"
@everywhere using CSVFiles
@everywhere using Random
@everywhere include(srcdir("hysteresisFunctions.jl"))
@everywhere include(srcdir("agentFunctions.jl"))
@everywhere include(srcdir("modelling.jl"))
@everywhere include(srcdir("clusterDetection.jl"))
path = ARGS[1] # get path via script argument
ensembleidentifier = ARGS[2]
if (ispath(path)==false)
    warn("Please specify a valid path!")
end
# some plotting parameters
figsize = (2000,2000)
combustioncolor=:black
electricColor=:lightgreen
blackgreen_binary = range(colorant"black", stop=colorant"lightgreen", length=2)
blackgreen_continous = cgrad([combustioncolor, electricColor], [0, 0.5, 1])
Random.seed!(1234)
model_files = get_model_files(path)
random_models = rand(1:length(model_files),100)
mkpath(plotsdir(ensembleidentifier))
for i_random_model in random_models
    i_model_file = model_files[i_random_model]
    model_params = parse_savename(i_model_file)[2]
    i_model= deserialize(i_model_file)
    state_matrix = get_state_matrix(i_model)
    affinity_matrix = get_affinity_matrix(i_model)

    states = heatmap(state_matrix,color=blackgreen_binary,legend=false,size=figsize,xlabel="state")
    filename=savename("state_matrix",model_params,"png")
    savefig(states,plotsdir(joinpath(ensembleidentifier,filename)))

    affinities= heatmap(affinity_matrix,color=blackgreen_continous,size=figsize,xlabel="affinity")
    filename=savename("affinity_matrix",model_params,"png")
    savefig(affinities,plotsdir(joinpath(ensembleidentifier,filename)))

    # plot cluster sizes
    electric_clusters = cluster_sizes(find_state_clusters(state_matrix)[2])
    if (length(electric_clusters) != 0)
        hist = histogram(electric_clusters)
        filename=savename("electric_clusters",model_params,"png")
        savefig(hist,plotsdir(joinpath(ensembleidentifier,filename)))
    end
    combustion_clusters = cluster_sizes(find_state_clusters(state_matrix,invert=true)[2])
    if (length(combustion_clusters) != 0)
        hist = histogram(combustion_clusters)
        filename=savename("combustion_clusters",model_params,"png")
        savefig(hist,plotsdir(joinpath(ensembleidentifier,filename)))
    end
end
