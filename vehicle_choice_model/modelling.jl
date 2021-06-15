using Agents
using Distributions
using YAML

"creating a model with default 10*10 gridspace and default parameters, which need to be calibrated more sophisticated"
function model_car_owners(placementFunction;
    space = Agents.GridSpace((10, 10); periodic = false, metric = :euclidean),
    priceCombustionCar = 10000,
    priceElectricCar = 10000,
    fuelCostKM = 0.05,
    powerCostKM = 0.05,
    maintenanceCostCombustionKM = 0.01,
    maintenanceCostElectricKM = 0.01,
    usedCarDiscount::Float64 = 0.5, #assumption: loss of 50% of car value due to used car market conditions
    budget = 200000,
    #general parameters
    socialInfluenceFactor = 1, # weight of neighbours opinion, declining with distance of neighbours (if more than first-order neighbours considered)
    affinityDistribution = Bernoulli(0.5),  # specify a distribution from which the starting affinity should be drawn
    tauRational = 3, #inertia for the rational part
    tauSocial = 1, #intertia for the social part
    switchingBias=1.0, #bias to switching, if <1, bias towards state 1, if >1, bias towards state 0
    switchingBoundary=0.5, # bound for affinity to switch state
    lowerAffinityBound = 0.0,
    upperAffinityBound = 1.0,
    scenarios=false,
    timepoint=0)


    model = ABM(
        CarOwner,
        space;
        properties = Dict(:priceCombustionCar => priceCombustionCar,
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
            :lowerAffinityBound => lowerAffinityBound,
            :upperAffinityBound => upperAffinityBound,
            :scenarios => scenarios,
            :timepoint=>timepoint)
    )
    numagents=length(space.s)
    placementFunction(model,numagents,budget)
    return model
end

"stepping function for updating model parameters based on scenarios *.yml file"
function model_step!(model)
    model.timepoint += 1
    if model.scenarios != false
        scenario_dict = YAML.load_file(model.scenarios)
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
end
