using Agents

"create an agent for 2d grid space"
@agent CarOwner GridAgent{2} begin
    #case specific parameters
    kilometersPerYear::Float64
    carValue::Float64 # current time value
    purchaseValue::Float64
    carAge::Int
    budget::Float64
    income::Float64
    #general parameters
    state::Int
    state_old::Int
    affinity::Float64
    affinity_old::Float64
    rationalOptimum::Int
end

"returns car price for model and car type"
function get_car_price(car,model)
        return (car == 0 ? model.priceCombustionCar : model.priceElectricCar)
end

"updates state and related variables of an CarOwner"
function set_state!(state::Int,agent::CarOwner,model)
    agent.state = state
    agent.carValue = get_car_price(state,model)
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

function multi_year_car_cost(kilometersPerYear, usageYears,
    initialCarAge, state, model)
    totalCost = 0.0
    for iYear in 0:(usageYears-initialCarAge)
        totalCost += yearly_car_cost(
            kilometersPerYear,
            initialCarAge+iYear,
            state,
            model
        )
    end
    return totalCost
end

"returns linearly depreciated value of the car"
function depreciate_car_value(agent::CarOwner, lifetime)
    return agent.purchaseValue - agent.carAge / lifetime * agent.purchaseValue # very simple linear depreciation
end

"computes rational decision for 0=combustion car or 1=electric car based on comparison of average cost"
function rational_decision(agent::CarOwner,model)
    lifetime = cld(300000, agent.kilometersPerYear) # rounding up division
    #calculate cost of current car vs. a new car:
    currentCost = multi_year_car_cost(
        agent.kilometersPerYear, lifetime,
        agent.carAge,
        agent.state,
        model
        )
    newCombustionCost = multi_year_car_cost(
        agent.kilometersPerYear, lifetime,
            0,
            0,
            model
        )
    newElectricCost = multi_year_car_cost(
        agent.kilometersPerYear, lifetime,
            0,
            1,
            model
        )
    #purchasing cost after selling old car
    incomeSellingOldCar = agent.carValue*model.usedCarDiscount
    newCombustionPurchase = model.priceCombustionCar - incomeSellingOldCar
    newElectricPurchase = model.priceElectricCar - incomeSellingOldCar
    if (agent.carAge<lifetime)
        currentCarAverageCost = (currentCost) / (lifetime - agent.carAge)
    else
        currentCarAverageCost = Inf #infinite cost to enforce buying a new car at the end of lifetime
    end
    newCombustionAverageCost = (newCombustionCost + newCombustionPurchase) / lifetime
    newElectricAverageCost = (newElectricCost + newElectricPurchase) / lifetime
    #compute rational decision
    combustionCostEfficient = newCombustionAverageCost < currentCarAverageCost
    electricCostEfficient = newElectricAverageCost < currentCarAverageCost
    # check preference between new combustion or new electric car:
    # default: remain with old car
    newCar = false
    carPreference = agent.state # remain with old car
    agent.budget += agent.income

    if (combustionCostEfficient || electricCostEfficient)
        carPreference = (newCombustionAverageCost < newElectricAverageCost) ? 0 : 1 # preference independent of budget constraint
        if (combustionCostEfficient && newCombustionPurchase<agent.budget) || (electricCostEfficient && newElectricPurchase<agent.budget)
            newCar = true
        end
    end
    return newCar, carPreference, newCombustionAverageCost, newElectricAverageCost

end

"returns personal utility influence, based on cost benefit ratio"
function calc_utility_influence_ratio(costDenominator::Float64, costNumerator::Float64, affinity::Float64, model)
    costRatio=costNumerator/costDenominator
    rationalAffinity=costRatio/(costRatio+model.switchingBias)
    return (rationalAffinity-affinity)/model.tauRational
end

"returns personal utility influence, based on one of the provided functions of cost difference"
function calc_utility_influence_diff(costSubtrahend::Float64, costMinuend::Float64 , affinity::Float64, model, diffSmoothingFunction,costDiffScale=2500)
    costDiff=(costMinuend-costSubtrahend)/costDiffScale
    rationalAffinity=diffSmoothingFunction(costDiff)
    return (rationalAffinity-affinity)/model.tauRational
end

function tanh_costDiff(costDiff::Float64)
    return 0.5*(1+tanh(costDiff))
end
function linear_costDiff(costDiff::Float64)
    return 0.5*(1+costDiff)
end
function step_costDiff(costDiff::Float64)
    return Int(costDiff>=0)
end


"returns social influence resulting from neighbours current state"
#edit which ensures as distance is increased, the same agents are not counted multiple times
function state_social_influence(agent::CarOwner, model, neighboursMaximumDistance=2)
    stateSocialInfluence = 0
    counted=[agent.id]
    for distance in 1:neighboursMaximumDistance
        neighboursStateDiff = 0
        neighbours = nearby_agents(agent,model,distance)
        numberNeighbours = 0
        for n in neighbours
            if !(n.id in counted)
                neighboursStateDiff += (n.state_old-agent.affinity_old)
                numberNeighbours +=1
                counted=append!(counted,n.id)
            end
        end
        neighboursStateDiff /= numberNeighbours # mean of neighbours opinion
        stateSocialInfluence += neighboursStateDiff * model.socialInfluenceFactor/distance # decaying influence of more distanced neighbours
    end
    stateSocialInfluence /= neighboursMaximumDistance #such that the maximum social influence is between -1/1
    return stateSocialInfluence / model.tauSocial
end

"returns social influence resulting from neighbours current affinity"
function affinity_social_influence(agent::CarOwner, model, neighboursMaximumDistance=1)
    affinitySocialInfluence = 0
    counted=[agent.id]
    for distance in 1:neighboursMaximumDistance
        neigboursAffinityDiff = 0
        neighbours = nearby_agents(agent,model,distance)
        numberNeighbours = 0
        for n in neighbours
            if !(n.id in counted)
                neigboursAffinityDiff += (n.affinity_old-agent.affinity_old)
                numberNeighbours +=1
                counted=append!(counted,n.id)
            end
        end
        neigboursAffinityDiff /= numberNeighbours # mean of neighbours opinion
        affinitySocialInfluence += neigboursAffinityDiff * model.socialInfluenceFactor^distance # decaying influence of more distanced neighbours
    end
    affinitySocialInfluence /= neighboursMaximumDistance #such that the maximum social influence is -1/1
    return affinitySocialInfluence / model.tauSocial
end

"step function for agents"
function agent_step!(agent, model)
    agent.carAge += 1
    #assumption: all cars are assumed to last at least 300.000km before purchase of a new car
    lifetime = cld(300000, agent.kilometersPerYear) # rounding up division

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
            calc_utility_influence_diff(averageCostElectric,averageCostCombustion,agent.affinity_old,model,tanh_costDiff)
            + state_social_influence(agent,model)
        )
    )
    if newCar
        if agent.state_old==0
            (agent.affinity<model.switchingBoundary+model.decisionGap) ? set_state!(0,agent,model) : set_state!(1,agent,model)
        else
            (agent.affinity<model.switchingBoundary-model.decisionGap) ? set_state!(0,agent,model) : set_state!(1,agent,model)
        end
    else
        agent.carValue = depreciate_car_value(agent, lifetime)
    end
end
