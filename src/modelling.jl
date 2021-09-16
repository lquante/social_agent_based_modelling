using DrWatson
@quickactivate "Social Agent Based Modelling"
using Agents
using Distributions
using Random
using YAML
include(srcdir("populationCreation.jl"))

"custom struct as a container of model parameters"
Base.@kwdef mutable struct ModelParameters
	#general parameters
	externalRationalInfluence::Real
	neighbourShare::Real
	socialInfluenceFactor::Real
	switchingLimit::Real
	switchingBoundary::Real
	lowerAffinityBound::Real
	upperAffinityBound::Real
	scenario::Bool
	timepoint::Int
end

"creating a model with some plausible default parameters"
function model_decision_agents_grid(placementFunction;seed=1234,
    space = Agents.GridSpace((10, 10); periodic = false, metric = :euclidean),
    kwargsPlacement = (),
    #general parameters
	externalRationalInfluence = 0.5,
	neighbourShare = 0.1, # share of neighbours to be considered of sqrt(numberAgents)
	socialInfluenceFactor = 0.5, #weight of social influence
    switchingLimit=Inf, #limited number of state switching per timestep
    switchingBoundary=0.5, # bound for affinity to switch state
    lowerAffinityBound = 0.0,
    upperAffinityBound = 1.0,
    scenario=0.,
    timepoint=0.)

	properties = ModelParameters(
            externalRationalInfluence,
			neighbourShare,
            socialInfluenceFactor,
            switchingLimit,
            switchingBoundary,
            lowerAffinityBound,
            upperAffinityBound,
            scenario,
            timepoint
    )
    model = ABM(
        DecisionAgent,
        space;rng=(Random.seed!(seed)),
        properties = properties
    )
    placementFunction(model,length(space.s);kwargsPlacement...)
    return model
end

"stepping function for updating model parameters"
function model_step!(model)
    model.timepoint += 1
    if model.scenario != false
        apply_scenario!(model)
    end
end

"initialize function for model creation, needed for paramscan methods"
function initialize(;args ...)
    return model_decision_agents(mixed_population;args ...)
end

"function to interpret scenario *.yml file"

function apply_scenario!(model)
    scenario_dict = YAML.load_file(model.scenario)
    if (model.timepoint in keys(scenario_dict["timepoints"]))
        timepoint_dict = scenario_dict["timepoints"][model.timepoint]
        variableSymbol = Symbol(timepoint_dict["variable"])
        if timepoint_dict["change"]["relative"]
            model.properties[variableSymbol] *= timepoint_dict["change"]["change"]
        else
            model.properties[variableSymbol] += timepoint_dict["change"]["change"]
        end
    end
end

"function to get a matrix of all affinities of the agents"
function get_affinity_matrix(model)
    position_matrix = model.space.s
    property_matrix = zeros(size(position_matrix))
    @inbounds for i_position in position_matrix
        agent = model.agents[i_position[1]]
        property_matrix[agent.pos[1],agent.pos[2]] = agent.affinity
    end
    return property_matrix
end

"function to get a matrix of all states of the agents"
function get_state_matrix(model)
	position_matrix = model.space.s
    property_matrix = zeros(size(position_matrix))
    @inbounds for i_position in position_matrix
        agent = model.agents[i_position[1]]
        property_matrix[agent.pos[1],agent.pos[2]] = agent.state
    end
    return property_matrix
end
