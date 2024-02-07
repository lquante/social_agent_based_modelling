using DrWatson
@quickactivate "Social Agent Based Modelling"
using Agents
using Distributions
using Random
using YAML
using Printf

"custom struct as a container of model parameters"
Base.@kwdef mutable struct ModelParameters
	#general parameters
	neighbourhoodExtent::Real # gives the extent of the neighbourhood: for grid spaces, euclidean distance, for networks: n-th neighbours
	lambda::Real #time scaling of attitude change
	lower_attitude_bound::Real
	upper_attitude_bound::Real
	scenario::Bool # help variable to trigger use of scenarios, i.e. dynamic change of model parameters
	timepoint::Int
end


"function to place one agent at each position of the models space"
function mixed_population(model; kwargs...)
    if typeof(model.space)<:Agents.GraphSpace
        for node in 1:length(model.space.s)
            create_agent(model, node; kwargs...)
        end
    end
    if typeof(model.space)<:Agents.GridSpace
        for pos in positions(model)
	    create_agent(model, pos; kwargs...)
        end
    end
end

"function to place one agent at positions of the models space with probability placement_probability"
function mixed_population_placement(model; placement_probability=1.0,kwargs...)
    if typeof(model.space)<:Agents.GraphSpace
        for node in 1:length(model.space.s)
            if rand() <= placement_probability
                create_agent(model, node; kwargs...)
            end
        end
    end
    if typeof(model.space)<:Agents.GridSpace
        for pos in positions(model)
            if rand() <= placement_probability
                create_agent(model, pos; kwargs...)
            end
        end
    end
end


"initialize function for model creation, needed for paramscan methods"
function initialize(;args ...)
    return model_decision_agents(mixed_population;args ...)
end

function initalize_placement(;args ...)
    return model_decision_agents(mixed_population_placement;args ...)
end


"creating a model with some plausible default parameters"
function model_decision_agents(
    placementFunction;
    seed=1234,
    space = Agents.GridSpace((100, 100); periodic = true, metric = :chebyshev),
    scheduler = Agents.Schedulers.fastest,
    # general parameters
    neighbourhoodExtent = 1, # distance of neighbours to be considered
    lambda = 1, #time scaling of attitude change
    lower_attitude_bound = 0.0,
    upper_attitude_bound = 1.0,
    scenario=0.,
    timepoint=0.,
    kwargs...)
        
    # reset seed
    seed = floor(Int64, seed)
    @printf("seed= %d\n", seed)    
    
    properties = ModelParameters(
        neighbourhoodExtent,
        lambda,
        lower_attitude_bound,
        upper_attitude_bound,
        scenario,
        timepoint)

	if typeof(space)<:GridSpace
	    model = ABM(DecisionAgentGrid, space;
                rng=(Random.seed!(seed)),
		scheduler=scheduler,
	        properties = properties)
	else
		if typeof(space)<:GraphSpace
		    model = ABM(DecisionAgentGraph, space;
                        rng=(Random.seed!(seed)), scheduler=scheduler, properties=properties)
		else
		    error("type of space not yet implemented")
		end
	end
    placementFunction(model; kwargs...)
    return model
end

"stepping function for updating model parameters"
function model_step!(model)
    model.timepoint += 1
    for agent in allagents(model)
        agent.attitude_old = agent.attitude
    end
    if model.scenario != false
        apply_scenario!(model)
    end
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

"function to get a matrix of all attitudes of the agents"
function get_attitude_matrix(model)
	if (typeof(model.space)<:Agents.GridSpace)
		position_matrix = model.space.s
	    property_matrix = zeros(size(position_matrix))
	    @inbounds for i_position in position_matrix
	        agent = model.agents[i_position[1]]
	        property_matrix[agent.pos[1],agent.pos[2]] = agent.attitudes
	    end
	    return property_matrix
	else
		print("not yet implemented for this space type")
	end
end
