# script to facilitate ensemble simulations
include("agentFunctions.jl")
include("modelling.jl")
include("populationCreation.jl")
include("visualization.jl")


# define parameters to be collected

adata = [:state,:rationalOptimum,:carAge, :affinity]
mdata=[]
# helper functions

function model_run!(model, timesteps; a_step=agent_step!,m_step=model_step!,adata=adata,mdata=mdata)
    return run!(model, a_step, m_step, timesteps; adata=adata,mdata=mdata)
end


# create model

diverseOwnership = model_car_owners(electric_minority)

# set random number seed

seed!(diverseOwnership,19956060601032517)

# create space
space = Agents.GridSpace((100, 100); periodic = false, metric = :euclidean)


mixedHugeGaia = model_car_owners(mixed_population;space=space)

# collect all data of agents for 10 timesteps
agentData, _ = model_run!(diverseOwnership, 10)

# example how to use parameter variation:


function initialize(;tauSocial_p=3,tauRational_p=3,space_p= Agents.GridSpace((100, 100); periodic = false, metric = :euclidean))
    return model_car_owners(mixed_population;space=space_p,tauSocial=tauSocial_p,tauRational=tauRational_p)
end
parameters = parameters = Dict(
    :tauRational_p => collect(1.0:0.5:5),
    :tauSocial_p => collect(1.0:0.5:5)
)

paramAgentData, _ = paramscan(parameters,initialize;include_constants=true,adata,agent_step!,n=10)
