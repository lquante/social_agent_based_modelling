using DrWatson
@quickactivate "Social Agent Based Modelling"
using Agents
using Distributions
using Random
using YAML

"custom struct as a container of model parameters"
Base.@kwdef mutable struct ModelParameters
	#general parameters
	constantAvantgarde::Real #constant value of avantgarde
	neighbourhoodExtent::Real # gives the extent of the neighbourhood: for grid spaces, euclidean distance, for networks: n-th neighbours
	tauRational::Real # weight for the rational influence
	tauSocial::Real #weight for the social influence
	switchingLimit::Real #limited number of state changes possible (per timestep)
	numberSwitched::Real #umber of state changes occured (per timestep)
	switchingBoundary::Real # lower boundary for affinity to have a state switch
	lowerAffinityBound::Real
	upperAffinityBound::Real
	scenario::Bool # help variable to trigger use of scenarios, i.e. dynamic change of model parameters
	timepoint::Int
end


"function to place one agent at each position of the models space"
function mixed_population(model;SIR=false)
	if typeof(model.space)<:Agents.GraphSpace
		for node in 1:length(model.space.s)
			create_agent(model,node;SIR=SIR)
	    end
    end
	if typeof(model.space)<:Agents.GridSpace
		for pos in positions(model)
			create_agent(model,pos;SIR=SIR)
		end
	end
end

"initialize function for model creation, needed for paramscan methods"
function initialize(;args ...)
    return model_decision_agents(mixed_population;args ...)
end

"schedule agents by inverse affinity, thus the most sceptical agents get to switch first with the (potentially) limited switching capacity"
function lowAffinityFirst(agent)
	return 1-agent.affinity
end

"creating a model with some plausible default parameters"
function model_decision_agents(placementFunction;seed=1234,
    space = Agents.GridSpace((10, 10); periodic = false, metric = :euclidean),
	scheduler = Agents.Schedulers.fastest,
	schedulerIndex=1,
	kwargsPlacement = (),
    #general parameters
	constantAvantgarde = 0.5,
	neighbourhoodExtent = 1, # distance of neighbours to be considered
	tauRational = 1, #weight of rational influence
	tauSocial = 1, #weight of social influence
    switchingLimit=Inf, #limited number of state switching per timestep
	numberSwitched=0,
	switchingBoundary=0.5, # bound for affinity to switch state
    lowerAffinityBound = 0.0,
    upperAffinityBound = 1.0,
    scenario=0.,
    timepoint=0.)

	properties = ModelParameters(
			constantAvantgarde,
			neighbourhoodExtent,
            tauRational,
			tauSocial,
            switchingLimit,
			numberSwitched,
            switchingBoundary,
            lowerAffinityBound,
            upperAffinityBound,
            scenario,
            timepoint
    )

	if (scheduler==Agents.Schedulers.fastest)
		defaultSchedulers = [Agents.Schedulers.fastest,Agents.Schedulers.by_property(:affinity),Agents.Schedulers.by_property(lowAffinityFirst)]
		scheduler = defaultSchedulers[schedulerIndex]
	end
	if typeof(space)<:GridSpace
	    model = ABM(
	        DecisionAgentGrid,
	        space;rng=(Random.seed!(seed)),
			scheduler=scheduler,
	        properties = properties
	    )
	else
		if typeof(space)<:GraphSpace
			model = ABM(
		        DecisionAgentGraph,
		        space;rng=(Random.seed!(seed)),
				scheduler=scheduler,
		        properties = properties
		    )
		else
			error("type of space not yet implemented")
		end
	end

    placementFunction(model;kwargsPlacement...)
    return model
end

"constant switching limit"
function constantSwitchingLimit(model,timepoint)
	return model.switchingLimit
end

"increasing switching limit - final capacity = starting value * limit factor, build-up time = number of timesteps until maximum capacity reached"
function increasingSwitchingLimit(model,timepoint,limitFactor=10,buildupTime=150,initialSwitchingLimit=1)
	if timepoint > buildupTime 
		return model.switchingLimit
	else
		return initialSwitchingLimit*(1+(limitFactor-1)*(timepoint/buildupTime))
	end
end

"stepping function for updating model parameters"
function model_step!(model,switchingLimitFunction=constantSwitchingLimit)
    model.timepoint += 1
	model.numberSwitched=0
    if model.scenario != false
        apply_scenario!(model)
    end
	model.switchingLimit = switchingLimitFunction(model,model.timepoint)
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
	if (model.space<:Agents.GridSpace)
		position_matrix = model.space.s
	    property_matrix = zeros(size(position_matrix))
	    @inbounds for i_position in position_matrix
	        agent = model.agents[i_position[1]]
	        property_matrix[agent.pos[1],agent.pos[2]] = agent.affinity
	    end
	    return property_matrix
	else
		print("not yet implemented for this space type")
	end
end

"function to get a matrix of all states of the agents"
function get_state_matrix(model)
	if (model.space<:Agents.GridSpace)
		position_matrix = model.space.s
		property_matrix = zeros(size(position_matrix))
		@inbounds for i_position in position_matrix
			agent = model.agents[i_position[1]]
			property_matrix[agent.pos[1],agent.pos[2]] = agent.state
		end
		return property_matrix
	else
		print("not yet implemented for this space type")
	end
end
