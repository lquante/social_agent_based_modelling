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
    rationalOptimum::Int
end

"returns vehicle value for model and vehicle type"
function get_vehicle_value(vehicle,model)
        return (vehicle == 0 ? model.priceCombustionVehicle : model.priceElectricVehicle)
end

"updates state and related variables of an VehicleOwner"
function set_state!(state::Int,agent::VehicleOwner,model)
    agent.state = state
    agent.vehicleValue = get_vehicle_value(state,model)
    agent.purchaseValue = agent.vehicleValue
    agent.vehicleAge = 0
    agent.budget -= agent.purchaseValue
end

"returns yearly running cost of vehicle usage, depending on agents yrly km, vehicle age, vehicle type and model parameters"
function yearly_vehicle_cost(
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
function depreciate_vehicle_value(agent::VehicleOwner, feasibleYears)
    return agent.purchaseValue - agent.vehicleAge / feasibleYears * agent.purchaseValue # very simple linear depreciation
end

"computes rational decision for 0=combustion car or 1=electric car based on comparison of average cost"
function rational_decision(agent::VehicleOwner,model)
    feasibleYears = cld(300000, agent.kilometersPerYear) # rounding up division
    #calculate cost of current car vs. a new car:
    currentCost = 0.0
    newCombustionCost = 0.0
    newElectricCost = 0.0
    for iYear in 1:(feasibleYears-agent.vehicleAge)
            currentCost += yearly_vehicle_cost(
                agent.kilometersPerYear,
                agent.vehicleAge + iYear,
                agent.state,
                model
            )
    end

    for iYear in 1:feasibleYears
        newCombustionCost += yearly_vehicle_cost(
            agent.kilometersPerYear,
            iYear,
            0,
            model
        )
        newElectricCost += yearly_vehicle_cost(
            agent.kilometersPerYear,
            iYear,
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
    newVehicle = false # dummy variable
    if (
            min(newCombustionAverageCost, newElectricAverageCost) <
            currentVehicleAverageCost
        )
            if (newCombustionAverageCost < newElectricAverageCost)
                if (newCombustionPurchase<=agent.budget)
                    newVehicle=true
                    vehiclePreference = 0
                end
            else
                if (newElectricPurchase<=agent.budget)
                    newVehicle=true
                    vehiclePreference = 1
                end
            end
    end
    if (newVehicle==false)
        agent.budget += 5000 # linearly increasing budget until you get a car
        vehiclePreference = agent.state
    end
    return newVehicle, vehiclePreference, newCombustionAverageCost, newElectricAverageCost

end

"returns personal utility influence, based on cost benefit ratio"
function calc_utility_influence_ratio(cost1::Float64, cost2::Float64, affinity::Float64, model)
    costRatio=cost2/cost1
    rationalAffinity=costRatio/(costRatio++model.switchingBias)
    return (rationalAffinity-affinity)/model.tauRational
end

"returns personal utility influence, based on one of the provided functions of cost difference"
function calc_utility_influence_diff(cost1::Float64, cost2::Float64, affinity::Float64, model, diffFunction)
    costDiff=(cost2-cost1)/(cost2+cost1)
    rationalAffinity=diffFunction(costDiff)
    return (rationalAffinity-affinity)/model.tauRational
end

function tanh_costDiff_rational_affinity(costDiff::Float64)
    return 0.5*(1+tanh(costDiff))
end

function linear_costDiff_rational_affinity(costDiff::Float64)
    return 0.5*(1+costDiff)
end
function step_costDiff_rational_affinity(costDiff::Float64)
    return Int(costDiff>0)
end

"returns social influence resulting from neighbours current state"
function state_social_influence(agent::VehicleOwner, model)
    neighboursStateAffinityChange=0
    for n in nearby_agents(agent,model,1)
        neighboursStateAffinityChange += model.socialInfluenceFactor*(n.state_old-agent.affinity_old)
    end
    return neighboursStateAffinityChange / model.tauSocial
end

"returns social influence resulting from neighbours current affinity"
function affinity_social_influence(agent::VehicleOwner, model)
    neighboursAffinityAffinityChange=0
    for n in nearby_agents(agent,model,1)
        neighboursAffinityAffinityChange += model.socialInfluenceFactor*(n.affinity_old-agent.affinity_old)
    end
    return neighboursAffinityAffinityChange / model.tauSocial
end

"step function for agents"
function agent_step!(agent, model)
    agent.vehicleAge += 1
    #assumption: all vehicles are assumed to last at least 300.000km before purchase of a new vehicle
    feasibleYears = cld(300000, agent.kilometersPerYear) # rounding up division

    newVehicle, rationalOptimum, averageCostCombustion, averageCostElectric = rational_decision(agent,model)
    agent.rationalOptimum = rationalOptimum

    #store previous affinity
    agent.affinity_old = agent.affinity
    agent.state_old = agent.state
    #compute new affinity
    agent.affinity = min(
    model.upperAffinityBound,
        max(
            model.lowerAffinityBound,
            agent.affinity_old +
            calc_utility_influence_diff(averageCostElectric,averageCostCombustion,agent.affinity_old,model,tanh_costDiff_rational_affinity)
            + affinity_social_influence(agent,model)
            + state_social_influence(agent,model)
        )
    )

    if newVehicle
        if (agent.affinity<model.switchingBoundary)
            set_state!(0,agent,model)
        else
            set_state!(1,agent,model)
        end
    else
        agent.vehicleValue = depreciate_vehicle_value(
        agent, feasibleYears
        )
    end
end
