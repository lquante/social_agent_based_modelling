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
function get_car_price(car::Int,model::AgentBasedModel)
        return car === 0 ? model.priceCombustionCar : model.priceElectricCar
end

"updates state and related variables of an CarOwner, ignoring budget due to overhead"
function update_state_woBudget!(state::Int,agent::CarOwner,model)
    set_state!(state,agent)
    set_carValue!(get_car_price(state,model),agent)
    set_purchaseValue!(agent.carValue,agent)
    set_carAge!(0,agent)
end
"updates state and related variables of an CarOwner"
function update_state!(state::Int,agent::CarOwner,model)
    set_state!(state,agent)
    set_carValue!(get_car_price(state,model),agent)
    set_purchaseValue!(agent.carValue,agent)
    set_carAge!(0,agent)
    update_budget!(agent.purchaseValue,agent)
end
function set_state!(state::Int,agent::CarOwner)
    agent.state = state
end
function set_carValue!(carValue::Float64,agent::CarOwner)
    agent.carValue = carValue
end
function set_purchaseValue!(purchaseValue::Float64,agent::CarOwner)
    agent.purchaseValue = purchaseValue
end
function set_carAge!(carAge::Int,agent::CarOwner)
    agent.carAge = carAge
end
function update_budget!(budgetChange::Float64,agent::CarOwner)
    agent.budget -= budgetChange
end
function set_budget!(budget::Float64,agent::CarOwner)
    agent.budget = budget
end

"returns yearly running cost of car usage, depending on agents yrly km, car age, car type and model parameters"
function yearly_car_cost(kilometersPerYear,carAge,fuelCostKM,maintenanceCostKM)
    return kilometersPerYear * (fuelCostKM +  (maintenanceCostKM * carAge))
end

function multi_year_car_cost(kilometersPerYear, usageYears,initialCarAge, state, model)
    totalCost = 0.0
    fuelCostKM = (state ===0 ? model.fuelCostKM : model.powerCostKM)
    maintenanceCostKM = (state ===0 ? model.maintenanceCostCombustionKM : model.maintenanceCostElectricKM)
    fuelCosts = kilometersPerYear*fuelCostKM*(usageYears-initialCarAge)
    # assuming linear weighting of maintenance costs by increasing age
    maintenanceCosts= kilometersPerYear*maintenanceCostKM*(usageYears-initialCarAge)*sum(initialCarAge:usageYears)
    return fuelCosts+maintenanceCosts
end

function average_car_cost(kilometersPerYear, usageYears,initialCarAge, state, model)
    cost = multi_year_car_cost(kilometersPerYear, usageYears,initialCarAge, state, model)
    return cost/(usageYears-initialCarAge)
end

"returns linearly depreciated value of the car"
function depreciate_car_value(agent::CarOwner,model)
    lifetime = cld(model.carLifetimeKilometers, agent.kilometersPerYear)
    return agent.purchaseValue - agent.carAge / lifetime * agent.purchaseValue # very simple linear depreciation
end

"computes rational decision for 0=combustion car or 1=electric car based on comparison of average cost"
function rational_decision(agent::CarOwner,model)
    #purchasing cost after selling old car
    incomeSellingOldCar = agent.carValue*model.usedCarDiscount
    newCombustionPurchase = model.priceCombustionCar - incomeSellingOldCar
    newElectricPurchase = model.priceElectricCar - incomeSellingOldCar
    lifetime = cld(model.carLifetimeKilometers, agent.kilometersPerYear)
    remainingLifetime = lifetime-agent.carAge
    if (agent.carAge<lifetime)
        currentCarAverageCost = average_car_cost(agent.kilometersPerYear, lifetime,agent.carAge,agent.state,model)+ incomeSellingOldCar / remainingLifetime
    else
        currentCarAverageCost = Inf #infinite cost to enforce buying a new car at the end of lifetime
    end
    newCombustionAverageCost = average_car_cost(agent.kilometersPerYear, lifetime,0,0,model) + newCombustionPurchase/lifetime
    newElectricAverageCost = average_car_cost(agent.kilometersPerYear, lifetime,0,1,model) + newElectricPurchase/lifetime
    #compute rational decision
    combustionCostEfficient = newCombustionAverageCost < currentCarAverageCost
    electricCostEfficient = newElectricAverageCost < currentCarAverageCost
    # check preference between new combustion or new electric car:
    # default: remain with old car
    newCar = false
    carPreference = agent.state # remain with old car
    agent.budget += agent.income
    # use car at least for half of the liftime:
    if (agent.carAge >= cld(lifetime,2))
        if (combustionCostEfficient || electricCostEfficient)
            carPreference = (newCombustionAverageCost < newElectricAverageCost) ? 0 : 1 # preference independent of budget constraint
            if (combustionCostEfficient && newCombustionPurchase<agent.budget) || (electricCostEfficient && newElectricPurchase<agent.budget)
                newCar = true
            end
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
function calc_utility_influence_diff(costSubtrahend::Float64, costMinuend::Float64 , affinity::Float64, model, diffSmoothingFunction = tanh_costDiff,costDiffScale::Float64=2500.)
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
function state_social_influence(agent::CarOwner, model::AgentBasedModel, neighboursMaximumDistance=2.)
    stateSocialInfluence = 0.
    numberNeighbours = 0
    neighbours = nearby_agents(agent,model,neighboursMaximumDistance)
    for n in neighbours
        stateSocialInfluence += (n.state_old-agent.affinity_old)/edistance(n,agent,model) #scaling by exact distance
        numberNeighbours +=1
    end
    stateSocialInfluence /= numberNeighbours # mean of neighbours opinion
    stateSocialInfluence /= neighboursMaximumDistance #such that the maximum social influence is -1/1
    return stateSocialInfluence / model.tauSocial * model.socialInfluenceFactor
end

function affinity_social_influence(agent::CarOwner, model::AgentBasedModel, neighboursMaximumDistance=2.)
    affinitySocialInfluence = 0.
    numberNeighbours = 0
    neighbours = nearby_agents(agent,model,neighboursMaximumDistance)
    for n in neighbours
        affinitySocialInfluence += (n.affinity_old-agent.affinity_old)/edistance(n,agent,model) #scaling by exact distance
        numberNeighbours +=1
    end
    affinitySocialInfluence /= numberNeighbours # mean of neighbours opinion
    affinitySocialInfluence /= neighboursMaximumDistance #such that the maximum social influence is -1/1
    return affinitySocialInfluence / model.tauSocial * model.socialInfluenceFactor
end

function old_state_social_influence(agent::CarOwner, model, neighboursMaximumDistance=1)
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
        stateSocialInfluence += neighboursStateDiff/distance # decaying influence of more distanced neighbours
    end
    stateSocialInfluence /= neighboursMaximumDistance #such that the maximum social influence is between -1/1
    return stateSocialInfluence / model.tauSocial * model.socialInfluenceFactor
end

"returns social influence resulting from neighbours current affinity"
function old_affinity_social_influence(agent::CarOwner, model, neighboursMaximumDistance=1)
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
        affinitySocialInfluence += neigboursAffinityDiff/distance # decaying influence of more distanced neighbours
    end
    affinitySocialInfluence /= neighboursMaximumDistance #such that the maximum social influence is -1/1
    return affinitySocialInfluence * model.socialInfluenceFactor / model.tauSocial
end

"step function for agents"
function agent_step!(agent, model)
    set_carAge!(agent.carAge+1,agent)
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
        if agent.state_old===0
            (agent.affinity<model.switchingBoundary+model.decisionGap) ? update_state!(0,agent,model) : update_state!(1,agent,model)
        else
            (agent.affinity<model.switchingBoundary-model.decisionGap) ? update_state!(0,agent,model) : update_state!(1,agent,model)
        end
    else
        agent.carValue = depreciate_car_value(agent,model)
    end
end
