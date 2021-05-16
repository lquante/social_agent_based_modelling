using Agents

@agent homoOeconomicus GridAgent{2} begin
    kilometersPerYear::Float64
    vehicle::Int # very primitive state variable: 1 = combustion engine, 2 = electric vehicle (TBextended by 0= no car)
    vehicleValue::Float64 # current time value
    purchaseValue::Float64
    vehicleAge::Int
    budget::Float64
    affinity::Float64
    affinity_old::Float64
end

function yearlyVehicleCost(
    yrlyKilometers::Float64,
    vehicleAge,
    vehicle,
    model
)
    fuelCostKM = vehicle == 1 ? model.fuelCostKM : model.powerCostKM
    maintenanceCostKM = vehicle == 1 ? model.maintenanceCostCombustionKM : model.maintenanceCostElectricKM
    return yrlyKilometers * (fuelCostKM +  maintenanceCostKM * vehicleAge)
end

function depreciateVehicleValue(purchaseValue, vehicleAge, feasibleYears)
    return purchaseValue - vehicleAge / feasibleYears * purchaseValue # very simple linear depreciation
end

function rationalDecision(vehicleAge::Int,feasibleYears::Float64,kilometersPerYear::Float64,vehicle::Int,vehicleValue::Float64,budget::Float64,model)
    #calculate cost of current car vs. a new car:
    currentCost = 0.0
    newCombustionCost = 0.0
    newElectricCost = 0.0
    for i_year in 1:(feasibleYears-vehicleAge)
            currentCost += yearlyVehicleCost(
                kilometersPerYear,
                vehicleAge + i_year,
                vehicle,
                model
            )
    end

    for i_year in 1:feasibleYears
        newCombustionCost += yearlyVehicleCost(
            kilometersPerYear,
            i_year,
            1,
            model
        )
        newElectricCost += yearlyVehicleCost(
            kilometersPerYear,
            i_year,
            2,
            model
        )
    end
    #purchasing cost after selling old car
    incomeSellingOldVehicle = vehicleValue*model.usedVehicleDiscount
    newCombustionPurchase = model.priceCombustionVehicle - incomeSellingOldVehicle
    newElectricPurchase = model.priceElectricVehicle - incomeSellingOldVehicle
    if (vehicleAge<feasibleYears)
        currentVehicleAverageCost =
            (currentCost) / (feasibleYears - vehicleAge)
    else
        currentVehicleAverageCost = 1000000 # dummy implementation to enforce buying a new car at the end of useage time
    end
    newCombustionAverageCost =
        (newCombustionCost + newCombustionPurchase) / feasibleYears
    newElectricAverageCost =
        (newElectricCost + newElectricPurchase) / feasibleYears

    #compute rational decision
    new_vehicle = false # dummy variable
    if (
            min(newCombustionAverageCost, newElectricAverageCost) <
            currentVehicleAverageCost
        )
            if (newCombustionAverageCost < newElectricAverageCost)
                if (newCombustionPurchase<=budget)
                    new_vehicle=true
                    vehicle_preference = 1
                end
            else
                if (newElectricPurchase<=budget)
                    new_vehicle=true
                    vehicle_preference = 2
                end
            end
    end
    if (new_vehicle==false)
        vehicle_preference = vehicle
    end
    return new_vehicle, vehicle_preference
end


function agent_step!(agent, model)
    agent.vehicleAge = agent.vehicleAge + 1
    #assumption: all vehicles are assumed to last at least 300.000km before purchase of a new vehicle
    feasibleYears = cld(300000, agent.kilometersPerYear) # rounding up division
    new_vehicle, vehicle_preference = rationalDecision(agent.vehicleAge,feasibleYears,agent.kilometersPerYear,agent.vehicle,agent.vehicleValue,agent.budget,model)

    #find neighbouring agents
    neighbours = nearby_agents(agent.pos,model,1)
    #compute the influence
    influence = 0
    for n in neighbours
        influence += model.influence_factor*(n.affinity_old-agent.affinity_old)
    end

    #set tau_pa to 3 at the moment
    tau_pa=3
    tau_a=3
    influence = influence/tau_pa
    #store previous affinity
    agent.affinity_old = agent.affinity
    #compute new affinity
    agent.affinity = agent.affinity_old + ((vehicle_preference-agent.affinity_old)/tau_a+influence)

    if (new_vehicle == true)
        if (agent.affinity<=1.5)
            agent.vehicle = 1
            agent.vehicleValue = model.priceCombustionVehicle
            agent.purchaseValue = model.priceCombustionVehicle
            agent.vehicleAge = 0
        else
            agent.vehicle = 2
            agent.vehicleValue = model.priceElectricVehicle
            agent.purchaseValue = model.priceElectricVehicle
            agent.vehicleAge = 0
        end
    else
        agent.vehicleValue = depreciateVehicleValue(
        agent.purchaseValue,
        agent.vehicleAge,
        feasibleYears,
        )
    end
end
