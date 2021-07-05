using Agents
using Distributions
using Random
using YAML
import Base.get

"creating a model with default 10*10 gridspace and default parameters, which need to be calibrated more sophisticated"
function model_car_owners(placementFunction;seed=1234,
    space = Agents.GridSpace((10, 10); periodic = false, metric = :euclidean),
    kwargsPlacement = (),
	#carLifetimeKilometers = 300000., reverting this change to be able to use preconverged models
    priceCombustionCar = 10000.,
    priceElectricCar = 10000.,
    fuelCostKM = 0.05,
    powerCostKM = 0.05,
    maintenanceCostCombustionKM = 0., # for now ignored for simplicity
    maintenanceCostElectricKM = 0.,# for now ignored for simplicity
    usedCarDiscount::Float64 = 0.5, #assumption: loss of 50% of car value due to used car market conditions
    budget = Inf, #for now ignoring budget limitations
    #general parameters
    socialInfluenceFactor = 1., # weight of neighbours opinion, declining with distance of neighbours (if more than first-order neighbours considered)
    tauRational = 3., #inertia for the rational part
    tauSocial = 1., #intertia for the social part
    switchingBias=1.0, #bias to switching, if <1, bias towards state 1, if >1, bias towards state 0
    switchingBoundary=0.5, # bound for affinity to switch state
    lowerAffinityBound = 0.0,
    upperAffinityBound = 1.0,
    scenario=0.,
    timepoint=0.,
    decisionGap=0.)

	properties = Dict(#:carLifetimeKilometers => carLifetimeKilometers,
			:priceCombustionCar => priceCombustionCar,
            :priceElectricCar => priceElectricCar,
            :fuelCostKM => fuelCostKM,
            :powerCostKM => powerCostKM,
            :maintenanceCostCombustionKM => maintenanceCostCombustionKM,
            :maintenanceCostElectricKM => maintenanceCostElectricKM,
            :usedCarDiscount => usedCarDiscount,
            :budget => budget,
            :socialInfluenceFactor => socialInfluenceFactor,
            :tauRational => tauRational,
            :tauSocial => tauSocial,
            :switchingBias => switchingBias,
            :switchingBoundary => switchingBoundary,
            :decisionGap => decisionGap,
            :lowerAffinityBound => lowerAffinityBound,
            :upperAffinityBound => upperAffinityBound,
            :scenario => scenario,
            :timepoint=>timepoint
    )
    model = ABM(
        CarOwner,
        space;rng=(Random.seed!(seed)),
        properties = properties
    )
    placementFunction(model,length(space.s),budget;kwargsPlacement...)
    return model
end

"stepping function for updating model parameters"
function model_step!(model)
    model.timepoint += 1
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

"function to get a matrix of all values of a property of the agents"
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
	position_matrix = model.space.s
    property_matrix = zeros(size(position_matrix))
    for i_position in position_matrix
        agent = model.agents[i_position[1]]
        property_matrix[agent.pos[1],agent.pos[2]] = agent.state
    end
    return property_matrix
end
