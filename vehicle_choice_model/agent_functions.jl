using Agents

"create an agent for 2d grid space"
@agent VehicleOwner GridAgent{2} begin
    #case specific parameters
    kilometersPerYear::Float64
    vehicleValue::Float64 # current time value
    purchaseValue::Float64
    vehicleAge::Int
    budget::Float64
    #general parameters
    state::Int
    state_old::Int
    affinity::Float64
    affinity_old::Float64
    rational_optimum::Int
end

"returns vehicle value for model and vehicle type"
function get_vehicle_value(vehicle,model)
        return (vehicle == 0 ? model.priceCombustionVehicle : model.priceElectricVehicle)
end

"updates state and related variables of an VehicleOwner"
function setState!(state::Int,agent::VehicleOwner,model)
    agent.state = state
    agent.vehicleValue = get_vehicle_value(state,model)
    agent.purchaseValue = agent.vehicleValue
    agent.vehicleAge = 0
end

"returns yearly running cost of vehicle usage, depending on agents yrly km, vehicle age, vehicle type and model parameters"
function yearlyVehicleCost(
    kilometersPerYear,
    vehicleAge,
    state,
    model
)
    fuelCostKM = state == 0 ? model.fuelCostKM : model.powerCostKM
    maintenanceCostKM = state == 0 ? model.maintenanceCostCombustionKM : model.maintenanceCostElectricKM
    return kilometersPerYear * (fuelCostKM +  (maintenanceCostKM * vehicleAge)) 
end

"returns linearly depreciated value of the vehicle"
function depreciateVehicleValue(agent::VehicleOwner, feasibleYears)
    return agent.purchaseValue - agent.vehicleAge / feasibleYears * agent.purchaseValue # very simple linear depreciation
end

"computes rational decision for 0=combustion car or 1=electric car based on comparison of average cost"
function rationalDecision(agent::VehicleOwner,model)
    feasibleYears = cld(300000, agent.kilometersPerYear) # rounding up division
    #calculate cost of current car vs. a new car:
    currentCost = 0.0
    newCombustionCost = 0.0
    newElectricCost = 0.0
    for i_year in 1:(feasibleYears-agent.vehicleAge)
            currentCost += yearlyVehicleCost(
                agent.kilometersPerYear,
                agent.vehicleAge + i_year,
                agent.state,
                model
            )
    end

    for i_year in 1:feasibleYears
        newCombustionCost += yearlyVehicleCost(
            agent.kilometersPerYear,
            i_year,
            0,
            model
        )
        newElectricCost += yearlyVehicleCost(
            agent.kilometersPerYear,
            i_year,
            1,
            model
        )
    end
    #purchasing cost after selling old car
    incomeSellingOldVehicle = agent.vehicleValue*model.usedVehicleDiscount
    newCombustionPurchase = model.priceCombustionVehicle - incomeSellingOldVehicle
    newElectricPurchase = model.priceElectricVehicle - incomeSellingOldVehicle
    if (agent.vehicleAge<feasibleYears)
        currentVehicleAverageCost =
            (currentCost) / (feasibleYears - agent.vehicleAge)
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
                if (newCombustionPurchase<=agent.budget)
                    new_vehicle=true
                    vehicle_preference = 0
                end
            else
                if (newElectricPurchase<=agent.budget)
                    new_vehicle=true
                    vehicle_preference = 1
                end
            end
    end
    if (new_vehicle==false)
        vehicle_preference = agent.state
    end
    #cost_ratio to be used in the Chi framework
    cost_ratio=newCombustionAverageCost/newElectricAverageCost
    return new_vehicle, vehicle_preference, cost_ratio

end

"returns influence of rational decision on decision"
function calc_utility_influence(costRatio::Float64, affinity::Float64, model)
    A_hat=costRatio/(costRatio+model.X_s)
    return (A_hat-affinity)/model.tau_rational
end

"returns social influence resulting from neighbours current state"
function calc_state_social_influence(agent::VehicleOwner, model)
    influence=0
    for n in nearby_agents(agent,model,1)
        influence += model.social_influence_factor*(n.state_old-agent.affinity_old)
    end
    return influence / model.tau_social
end

"returns social influence resulting from neighbours current affinity"
function calc_affinity_social_influence(agent::VehicleOwner, model)
    influence=0
    for n in nearby_agents(agent,model,1)
        influence += model.social_influence_factor*(n.affinity_old-agent.affinity_old)
    end
    return influence / model.tau_social
end



"step function for agents"
function agent_step!(agent, model)
    agent.vehicleAge = agent.vehicleAge + 1
    #assumption: all vehicles are assumed to last at least 300.000km before purchase of a new vehicle
    feasibleYears = cld(300000, agent.kilometersPerYear) # rounding up division

    new_vehicle, rational_optimum, cost_ratio = rationalDecision(agent,model)
    agent.rational_optimum = rational_optimum
    utility_influence = calc_utility_influence(cost_ratio,agent.affinity_old,model)

    social_state_influence = calc_state_social_influence(agent,model)
    social_affinity_influence = calc_affinity_social_influence(agent,model)

    #store previous affinity
    agent.affinity_old = agent.affinity
    agent.state_old = agent.state
    #compute new affinity
    agent.affinity = min(
    model.upperAffinityBound,
        max(
            model.lowerAffinityBound,
            agent.affinity_old +
            utility_influence +
            social_affinity_influence +
            social_state_influence
        )
    )

    if new_vehicle
        if (agent.affinity<model.A_s)
            setState!(0,agent,model)
        else
            setState!(1,agent,model)
        end
    else
        agent.vehicleValue = depreciateVehicleValue(
        agent, feasibleYears
        )
    end
end
