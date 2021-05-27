using Agents
using Distributions

"creating a model with default 10*10 gridspace and default parameters, which need to be calibrated more sophisticated"
function model_car_owners(placementFunction;
    space = Agents.GridSpace((10, 10); periodic = false, metric = :euclidean),
    priceCombustionCar = 10000,
    priceElectricCar = 20000,
    fuelCostKM = 0.125,
    powerCostKM = 0.05,
    maintenanceCostCombustionKM = 0.0075,
    maintenanceCostElectricKM = 0.01,
    usedCarDiscount::Float64 = 0.5, #assumption: loss of 50% of car value due to used car market conditions
    budget = 200000,
    #general parameters
    socialInfluenceFactor = 0.2,
    affinityDistribution = Bernoulli(0.5),  # specify a distribution from which the starting affinity should be drawn
    tauRational = 3, #inertia for the rational part
    tauSocial = 3, #intertia for the social part
    switchingBias=1.0, #bias to switching, if <1, bias towards state 1, if >1, bias towards state 0
    switchingBoundary=0.5, # bound for affinity to switch state
    lowerAffinityBound = 0.0,
    upperAffinityBound = 1.0
)
    model = ABM(
        CarOwner,
        space,
        scheduler = Agents.Schedulers.fastest,
        properties = Dict(
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
            :tauSocial => tauSocial, # assumtpion for now: uniform budget
            :switchingBias => switchingBias,
            :switchingBoundary => switchingBoundary,
            :lowerAffinityBound => lowerAffinityBound,
            :upperAffinityBound => upperAffinityBound
        )
    )
    numagents=length(space.s)
    placementFunction(model,numagents,budget)
    return model
end

"stepping function for updating model paramters, ATM doing nothing"
function model_step!(model)
    for a in allagents(model)
        rand(model.rng)
    end
end
