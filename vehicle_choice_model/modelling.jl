using Agents
using Distributions
using Random
using YAML

"creating custom data strucure to avoid dictionary with varying types (see https://juliadynamics.github.io/Agents.jl/stable/performance_tips/#Performance-Tips)"
Base.@kwdef mutable struct Parameters
	priceCombustionCar::Float32 = 10000
    priceElectricCar::Float32 = 10000
    fuelCostKM::Float32 = 0.05
    powerCostKM::Float32 = 0.05
    maintenanceCostCombustionKM::Float32 = 0 # for now ignored for simplicity
    maintenanceCostElectricKM::Float32 = 0# for now ignored for simplicity
    usedCarDiscount::Float32 = 0.5 #assumption: loss of 50% of car value due to used car market conditions
    budget::Float32 = Inf #for now ignoring budget limitations
    #general parameters
    socialInfluenceFactor::Float32 = 1 # weight of neighbours opinion declining with distance of neighbours (if more than first-order neighbours considered)
    tauRational::Float32 = 3 #inertia for the rational part
    tauSocial::Float32 = 1 #intertia for the social part
    switchingBias::Float32 =1.0 #bias to switching if <1 bias towards state 1 if >1 bias towards state 0
    switchingBoundary::Float32 = 0.5 # bound for affinity to switch state
    lowerAffinityBound::Float32 = 0.0
    upperAffinityBound::Float32 = 1.0
    scenario::Bool = false
    timepoint::Int = 0
    decisionGap::Float32 = 0
    summaryStats::Bool = false
end

"creating a model with default 10*10 gridspace and default parameters, which need to be calibrated more sophisticated"
function model_car_owners(placementFunction;seed=1234,
    space = Agents.GridSpace((10, 10); periodic = false, metric = :euclidean),
    args ...)
	properties = Parameters(args ...)
    model = ABM(
        CarOwner,
        space;rng=(Random.seed!(seed)),
        properties = properties
    )
    placementFunction(model,length(space.s),properties.budget)
    return model
end

"stepping function for updating model parameters"
function model_step!(model)
    model.timepoint += 1
    if model.scenario != false
        apply_scenario!(model)
    end
    if model.summaryStats
        # collecting some summary stats to detect stable states
        push!(model.meanState,mean(get_state_matrix(model)))
        push!(model.meanAffinity,mean(get_affinity_matrix(model)))
        push!(switichingAgents,sum(abs.(get_agent_property_matrix(model,"state_old")-get_agent_property_matrix(model,"state"))))
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

"function to get a matrix of all values of a property of the agents"

function get_agent_property_matrix(model,agentProperty)
    position_matrix = model.space.s
    property_matrix = zeros(size(position_matrix))
    for i_position in position_matrix
        agent = model.agents[i_position[1]]
        property_matrix[agent.pos[1],agent.pos[2]] = get_property(agent,agentProperty)
    end
    return property_matrix
end

function get_affinity_matrix(model)
    position_matrix = model.space.s
    property_matrix = zeros(size(position_matrix))
    for i_position in position_matrix
        agent = model.agents[i_position[1]]
        property_matrix[agent.pos[1],agent.pos[2]] = agent.affinity
    end
    return property_matrix
end

function get_state_matrix(model)
    return get_agent_property_matrix(model,"state")
end
"primitive helper function, TB improved"
function get_property(agent,agent_property::String)
    return eval(Meta.parse(string("agent.",agent_property)))
end
