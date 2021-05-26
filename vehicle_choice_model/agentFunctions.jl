using Agents

"create an agent for 2d grid space"
@agent CarOwner GridAgent{2} begin
    #case specific parameters
    kilometersPerYear::Float64
    carValue::Float64 # current time value
    purchaseValue::Float64
    carAge::Int
    budget::Float64
    #general parameters
    state::Int
    state_old::Int
    affinity::Float64
    affinity_old::Float64
    rationalOptimum::Int
end

"returns car value for model and car type"
function get_car_value(car,model)
        return (car == 0 ? model.priceCombustionCar : model.priceElectricCar)
end

"updates state and related variables of an CarOwner"
function set_state!(state::Int,agent::CarOwner,model)
    agent.state = state
    agent.carValue = get_car_value(state,model)
    agent.purchaseValue = agent.carValue
    agent.carAge = 0
    agent.budget -= agent.purchaseValue
end

"returns yearly running cost of car usage, depending on agents yrly km, car age, car type and model parameters"
function yearly_car_cost(
    kilometersPerYear,
    carAge,
    state,
    model
)
    fuelCostKM = state == 0 ? model.fuelCostKM : model.powerCostKM
    maintenanceCostKM = state == 0 ? model.maintenanceCostCombustionKM : model.maintenanceCostElectricKM
    return kilometersPerYear * (fuelCostKM +  (maintenanceCostKM * carAge))
end

"returns linearly depreciated value of the car"
function depreciate_car_value(agent::CarOwner, feasibleYears)
    return agent.purchaseValue - agent.carAge / feasibleYears * agent.purchaseValue # very simple linear depreciation
end

"computes rational decision for 0=combustion car or 1=electric car based on comparison of average cost"
function rational_decision(agent::CarOwner,model)
    feasibleYears = cld(300000, agent.kilometersPerYear) # rounding up division
    #calculate cost of current car vs. a new car:
    currentCost = 0.0
    newCombustionCost = 0.0
    newElectricCost = 0.0
    for iYear in 1:(feasibleYears-agent.carAge)
            currentCost += yearly_car_cost(
                agent.kilometersPerYear,
                agent.carAge + iYear,
                agent.state,
                model
            )
    end

    for iYear in 1:feasibleYears
        newCombustionCost += yearly_car_cost(
            agent.kilometersPerYear,
            iYear,
            0,
            model
        )
        newElectricCost += yearly_car_cost(
            agent.kilometersPerYear,
            iYear,
            1,
            model
        )
    end
    #purchasing cost after selling old car
    incomeSellingOldCar = agent.carValue*model.usedCarDiscount
    newCombustionPurchase = model.priceCombustionCar - incomeSellingOldCar
    newElectricPurchase = model.priceElectricCar - incomeSellingOldCar
    if (agent.carAge<feasibleYears)
        currentCarAverageCost =
            (currentCost) / (feasibleYears - agent.carAge)
    else
        currentCarAverageCost = 1000000 # dummy implementation to enforce buying a new car at the end of useage time
    end
    newCombustionAverageCost =
        (newCombustionCost + newCombustionPurchase) / feasibleYears
    newElectricAverageCost =
        (newElectricCost + newElectricPurchase) / feasibleYears

    #compute rational decision
    combustionCostEfficient = newCombustionAverageCost < currentCarAverageCost
    electricCostEfficient = newElectricAverageCost < currentCarAverageCost
    # check preference between new combustion or new electric car:
    # default: remain with old car
    newCar = false
    carPreference = agent.state # remain with old car
    agent.budget += 5000

    if (combustionCostEfficient || electricCostEfficient)
        carPreference = (newCombustionAverageCost < newElectricAverageCost) ? 0 : 1 # preference independent of budget constraint
        if (combustionCostEfficient && newCombustionPurchase<agent.budget) || (electricCostEfficient && newElectricPurchase<agent.budget)
            newCar = true
        end
    end
    return newCar, carPreference, newCombustionAverageCost, newElectricAverageCost

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
function state_social_influence(agent::CarOwner, model)
    neighboursStateAffinityChange=0
    for n in nearby_agents(agent,model,1)
        neighboursStateAffinityChange += model.socialInfluenceFactor*(n.state_old-agent.affinity_old)
    end
    return neighboursStateAffinityChange / model.tauSocial
end

"returns social influence resulting from neighbours current affinity"
function affinity_social_influence(agent::CarOwner, model)
    neighboursAffinityAffinityChange=0
    for n in nearby_agents(agent,model,1)
        neighboursAffinityAffinityChange += model.socialInfluenceFactor*(n.affinity_old-agent.affinity_old)
    end
    return neighboursAffinityAffinityChange / model.tauSocial
end

"step function for agents"
function agent_step!(agent, model)
    agent.carAge += 1
    #assumption: all cars are assumed to last at least 300.000km before purchase of a new car
    feasibleYears = cld(300000, agent.kilometersPerYear) # rounding up division

    newCar, rationalOptimum, averageCostCombustion, averageCostElectric = rational_decision(agent,model)
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

    if newCar
        if (agent.affinity<model.switchingBoundary)
            set_state!(0,agent,model)
        else
            set_state!(1,agent,model)
        end
    else
        agent.carValue = depreciate_car_value(
        agent, feasibleYears
        )
    end
end
