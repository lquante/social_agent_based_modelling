using Agents
using Distributions

"creating a model with default 10*10 gridspace and default parameters, which need to be calibrated more sophisticated"
function modelHomoOeconomicus(placementFunction;
    space = Agents.GridSpace((10, 10); periodic = false, metric = :euclidean),
    priceCombustionVehicle = 10000,
    priceElectricVehicle = 20000,
    fuelCostKM = 0.125,
    powerCostKM = 0.05,
    maintenanceCostCombustionKM = 0.0075,
    maintenanceCostElectricKM = 0.01,
    usedVehicleDiscount::Float64 = 0.8, #assumption: loss of 20% of vehicle value due to used vehicle market conditions
    budget = 1000000, # for now only dummy implementation,

    #general parameters
    social_influence_factor = 0.2,
    affinity_distribution = Bernoulli(0.5),  # specify a distribution from which the starting affinity should be drawn
    tau_rational = 3, #inertia for the rational part
    tau_social = 3, #intertia for the social part
    #switching ratio
    X_s=0.5,
    #switching affinity
    A_s=0.5
)
    model = ABM(
        homoOeconomicus,
        space,
        scheduler = Agents.Schedulers.fastest,
        properties = Dict(
            :priceCombustionVehicle => priceCombustionVehicle,
            :priceElectricVehicle => priceElectricVehicle,
            :fuelCostKM => fuelCostKM,
            :powerCostKM => powerCostKM,
            :maintenanceCostCombustionKM => maintenanceCostCombustionKM,
            :maintenanceCostElectricKM => maintenanceCostElectricKM,
            :usedVehicleDiscount => usedVehicleDiscount,
            :budget => budget,
            :social_influence_factor => social_influence_factor,
            :tau_rational => tau_rational,
            :tau_social => tau_social, # assumtpion for now: uniform budget
            :X_s => X_s,
            :A_s => A_s
        )
    )
    numagents=length(space.s)
    placementFunction(model,numagents,budget)
    return model
end

"stepping function for updating model paramters, ATM doing noting"
function model_step!(model)
    for a in allagents(model)
        rand(model.rng)
    end
end

"returns vehicle value for model and vehicle type"
function get_vehicle_value(model,vehicle)
    if vehicle == 0
        return model.priceCombustionVehicle
    end
    if vehicle == 1
        return model.priceElectricVehicle
    end
end
