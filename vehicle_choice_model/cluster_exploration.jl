include("agentFunctions.jl")
include("modelling.jl")
include("populationCreation.jl")
include("visualization.jl")
using Random

##observation: For equal incentive the model converges to stable patterns
# it converges for all srots of taus for larger incentives towards a classic "strip" pattern
# for an incremental incentive change the patterns are different

rng = Random.seed!(1234)
Random.seed!(1234)
space = Agents.GridSpace((30, 30); periodic = true, metric = :euclidean)

mixedHugeGaia = model_car_owners(mixed_population;seed = rng,space=space,tauSocial=4,tauRational=6,fuelCostKM=0,powerCostKM=0,priceCombustionCar=5000,priceElectricCar=5000)
interactive_simulation(mixedHugeGaia,agent_step!,model_step!;heatarray=get_affinity_matrix)
