using Agents


function modelHomoOeconomicus(placementFunction,
    space = Agents.GridSpace((10, 10); periodic = false, metric = :euclidean);
    numagents = 100,
    influence_factor = 0.5,
    priceCombustionVehicle = 10000,
    priceElectricVehicle = 20000,
    fuelCostKM = 0.125,
    powerCostKM = 0.05,
    maintenanceCostCombustionKM = 0.0075,
    maintenanceCostElectricKM = 0.01,
    usedVehicleDiscount::Float64 = 0.8, #assumption: loss of 20% of vehicle value due to used vehicle market conditions
    budget = 1000000 # for now only dummy implementation
)
    model = ABM(
        homoOeconomicus,
        space,
        properties = Dict(
            :influence_factor => influence_factor,
            :priceCombustionVehicle => priceCombustionVehicle,
            :priceElectricVehicle => priceElectricVehicle,
            :fuelCostKM => fuelCostKM,
            :powerCostKM => powerCostKM,
            :maintenanceCostCombustionKM => maintenanceCostCombustionKM,
            :maintenanceCostElectricKM => maintenanceCostElectricKM,
            :usedVehicleDiscount => usedVehicleDiscount,
            :budget => budget # assumtpion for now: uniform budget
        ),
    )
    placementFunction(model,numagents,budget)
    return model
end

function model_step!(model)
    for a in allagents(model)
        rand(model.rng) # dummy function since no model updated implemented ATM
    end
end

function get_vehicle_value(model,vehicle)
    if vehicle == 1
        return model.priceCombustionVehicle
    end
    if vehicle == 2
        return model.priceElectricVehicle
    end
end
