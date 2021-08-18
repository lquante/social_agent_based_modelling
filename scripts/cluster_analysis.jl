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
Random.seed!(1234)
model_files = get_model_files(path)
mkpath(plotsdir(ensembleidentifier))

clusterResults = DataFrame()
allowmissing!(clusterResults)
blackgreen_binary = range(colorant"black", stop=colorant"lightgreen", length=2)
figsize = (2000,2000)

for i_modelfile in model_files
    modelParams = parse_savename(i_modelfile)[2]
    i_model= deserialize(i_modelfile)
    state_matrix = get_state_matrix(i_model)

    # plot cluster sizes
    electric_clusters = cluster_sizes(find_state_clusters(state_matrix)[2])
    minSizeElectricCluster = 0
    if (length(electric_clusters) != 0)
        minSizeElectricCluster = minimum(electric_clusters)
    end
    combustion_clusters = cluster_sizes(find_state_clusters(state_matrix,invert=true)[2])
    minSizeCombustionCluster = 0
    if (length(combustion_clusters) != 0)
        minSizeCombustionCluster = minimum(combustion_clusters)
    end
    clusterSizes = @ntuple minSizeElectricCluster minSizeCombustionCluster
    paramTuple = dict2ntuple(modelParams)
    data = merge(paramTuple,clusterSizes)
    push!(clusterResults,data)
    allowmissing!(clusterResults)
end
mkpath(datadir(ensembleidentifier))
filename = joinpath(datadir(ensembleidentifier),"cluster_sizes.csv")
CSV.write(filename, clusterResults)
