using Distributed
@everywhere using DrWatson
@everywhere @quickactivate "Social Agent Based Modelling"
@everywhere using CSVFiles
@everywhere using Random
@everywhere include(srcdir("hysteresisFunctions.jl"))
@everywhere include(srcdir("agentFunctions.jl"))
@everywhere include(srcdir("modelling.jl"))
@everywhere include(srcdir("clusterDetection.jl"))
using StatsPlots
path = "/home/quante/git/social_agent_based_modelling/_research/clusters_900/cluster_sizes.csv"

data = CSV.read(path,DataFrame)

data.p_combustion=[split(x, "s")[1] for x in data.combustion]

data



@df data scatter(:p_combustion, :minSizeElectricCluster)
@df data scatter(:p_combustion, :minSizeCombustionCluster)
