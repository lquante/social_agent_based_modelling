using DrWatson
@quickactivate "Social Agent Based Modelling"
using Agents

"define an agent for 2d grid space"
mutable struct DecisionAgentGrid <:AbstractAgent
    id::Int
    pos::Tuple{Int64,Int64}
    internalRationalInfluence::Float64
    state::Int
    state_old::Int
    affinity::Float64
    affinity_old::Float64
end

"define an agent for 2d grid space"
mutable struct DecisionAgentGraph <:AbstractAgent
    id::Int
    pos::Int
    internalRationalInfluence::Float64
    state::Int
    state_old::Int
    affinity::Float64
    affinity_old::Float64
end

"define an agent for coupled decision-SIR model on a graph"
mutable struct DecisionAgentGraphSIR <:AbstractAgent
    id::Int
    pos::Int
    internalRationalInfluence::Float64
    state::Int
    state_old::Int
    affinity::Float64
    affinity_old::Float64
    SIR_status::Symbol
    days_infected::Int
    days_recovered::Int
    infection_detected::Bool
end

"get random personal opinion on decision, skewed by inverted beta dist"
function randomInternalRational(model,distribution=Beta(2,5))
    return 1-rand(model.rng,distribution)
end
"get random affinity on decision, skewed by inverted beta dist"
function randomAffinity(model,distribution=Beta(2,5))
    return 1-rand(model.rng,distribution)
end

"function to add an agent to a space based on position"
function create_agent(model,position;SIR=false,initializeInternalRational=randomInternalRational,initializeAffinity=randomAffinity)
    initialInternalRational=initializeInternalRational(model)
    initialAffinity = initializeAffinity(model)
    initialState = 0
    if SIR == false
        add_agent!(position,
            model,
            #general parameters
            initialInternalRational,
            initialState,
            initialState,
            initialAffinity,
            initialAffinity
        )
    else
        SIR_status = rand(model.rng)<model.initialInfected ? :I : :S
        add_agent!(position,
            model,
            #general parameters
            initialInternalRational,
            initialState,
            initialState,
            initialAffinity,
            initialAffinity,
            SIR_status,
            0,
            0,
            false
        )
    end
end

function set_state!(state::Int,agent::AbstractAgent)
    agent.state = state
end

"computes rational decision for 0=no or 1=yes"
function rational_influence(agent,model)
    rationalAffinity = internalRational(agent,model) # no external rational component implemented yet
    return rationalAffinity-agent.affinity
end

"computes contribuition for rational decision from external sources"
function externalRational(agent,model)
    return model.externalRationalInfluence # first very simple case: model parameter controls external "forcing"
end
"computes contribuition for rational decision from internal sources"
function internalRational(agent,model)
    return agent.internalRationalInfluence # first very simple case: agent parameter controls internal "forcing"
end

"return distance of neighbour depending on space type of model"
function neigbourDistance(agent,neighbour,model)
    if typeof(model.space)<:Agents.GridSpace
        return edistance(agent,neighbour,model)
    else
        if typeof(model.space)<:Agents.GraphSpace
            if model.neighbourhoodExtent==1
                return 1 #shortcut to save expensive astar algorithm
            else
                return length(a_star(model.space.graph,agent.pos,neighbour.pos)) # get shortest path between a and neighbour
            end
        else
        error("distance for this space type not yet implemented")
        end
    end
end

"returns social influence based on neighbours state"
function state_social_influence(agent, model::AgentBasedModel)
    stateSocialInfluence::Real = 0
    sumNeighbourWeights = 0
    neighbours = nearby_agents(agent,model,model.neighbourhoodExtent)
    @inbounds for n in neighbours
        neighbourDistance=neigbourDistance(agent,n,model)
        stateSocialInfluence += (n.state_old-agent.state)/neighbourDistance
        sumNeighbourWeights +=1/neighbourDistance
    end
    if sumNeighbourWeights>0
        stateSocialInfluence /= sumNeighbourWeights #such that the maximum social influence is 1
    end
    return stateSocialInfluence * model.socialInfluenceFactor
end

"returns social influence based on neighbours affinity"
function affinity_social_influence(agent, model::AgentBasedModel)
    #calculate neighbours maximum distance based on
    affinitySocialInfluence = 0.0
    sumNeighbourWeights = 0
    neighbours = nearby_agents(agent,model,model.neighbourhoodExtent)
    @inbounds for n in neighbours
        neighbourDistance=neigbourDistance(agent,n,model)
        affinitySocialInfluence += (n.affinity_old-agent.affinity)/neighbourDistance
        sumNeighbourWeights +=1/neighbourDistance
    end
    if sumNeighbourWeights>0
        affinitySocialInfluence /= sumNeighbourWeights #such that the maximum social influence is 1
    end
    return affinitySocialInfluence * model.socialInfluenceFactor
end

"returns social influence based on neighbours state"
function combined_social_influence(agent, model::AgentBasedModel)
    combinedSocialInfluence = 0.0
    sumNeighbourWeights = 0
    neighbours = nearby_agents(agent,model,model.neighbourhoodExtent)
    @inbounds for n in neighbours
        neighbourDistance=neigbourDistance(agent,n,model)
        combinedSocialInfluence += ((n.affinity_old-agent.affinity)+(n.state_old-agent.state))/neighbourDistance
        sumNeighbourWeights +=1/neighbourDistance
    end
    if sumNeighbourWeights>0
        combinedSocialInfluence /= sumNeighbourWeights #such that the maximum social influence is 1
    end
    return combinedSocialInfluence * model.socialInfluenceFactor
end

"step function for agents"
function agent_step!(agent, model)
    if agent.state===0 # one way decision, no change for already "yes" decision, Q: should affinity still change?
        #compute new affinity
        agent.affinity = min(
        model.upperAffinityBound,
          max(
              model.lowerAffinityBound,
              agent.affinity
              +rational_influence(agent,model)
              +state_social_influence(agent,model)
          )
        )
        #change state if affinity large enough & switching still possible
        if model.numberSwitched<model.switchingLimit
            if (agent.affinity>=model.switchingBoundary)
                set_state!(1,agent)
                model.numberSwitched+=1
            end
        end
    end
    #store affinity and state for next timestep
    agent.affinity_old = agent.affinity
    agent.state_old = agent.state
end

## SIR model functions
"step function for agents"
function agent_step_SIR!(agent, model)
    if agent.SIR_status == :I
        transmit!(agent,model)
        update!(agent,model)
        recover_or_die!(agent,model)
    end
    if agent.SIR_status == :R
        update_recovered!(agent,model)
    end
    if agent.state===0 # one way decision, no change for already "yes" decision, Q: should affinity still change?
        #compute new affinity
        agent.affinity = min(
        model.upperAffinityBound,
          max(
              model.lowerAffinityBound,
              agent.affinity
              +rational_influence(agent,model)
              +affinity_social_influence(agent,model)
          )
        )
        #change state if affinity large enough & switching still possible
        if model.numberSwitched<model.switchingLimit && agent.SIR_status == :S
            if (agent.affinity>=model.switchingBoundary)
                set_state!(1,agent)
                model.numberSwitched+=1
            end
        end
    end
    #store affinity and state for next timestep
    agent.affinity_old = agent.affinity
    agent.state_old = agent.state
    update_vaccinated!(agent,model)
end


"distribute infections between agents of different distance"

function distributedInfection(numberInfections,agent,model)
    # draw distribution of distances of infected agents
    distanceDistribution = Poisson(0.5) #tbd parametrize as model parameter
    distances = rand(model.rng,distanceDistribution,numberInfections).+1 #draw distances and shift by 1 to have at least distance 1
    infectionCache = 0
    for i_distance in Set(distances)
        numberInfectionsWithinDistance = count(i->(i==i_distance),distances)+infectionCache
        agentsWithinExactDistance = setdiff(nearby_agents(agent,model,i_distance),nearby_agents(agent,model,i_distance-1))
        for neighbour in agentsWithinExactDistance
            if neighbour.SIR_status == :S
                neighbour.SIR_status = :I
                numberInfectionsWithinDistance-=1
                numberInfectionsWithinDistance==0 && break
            end
        end
        infectionCache = numberInfectionsWithinDistance
    end
end

"determine transmission from infected to susceptible"
function detectInfection!(agent, model)
    if agent.days_infected>model.detectionTime && agent.infection_detected == false
        if (rand(model.rng)>model.detectionProbability) 
            agent.infection_detected = true
        end
    end
end


"determine transmission from infected to susceptible"
function transmit!(agent, model)
    rate = if agent.infection_detected
        model.transmissionDetected
    else
        model.transmissionUndetected
    end
    d = Poisson(rate)
    n = rand(model.rng, d)
    distributedInfection(n,agent,model)
end
"update number of days infected"
update!(agent, model) = (agent.days_infected += 1)

"check if patients die or recover after infection period"
function recover_or_die!(agent, model)
    if agent.days_infected ≥ model.infectionPeriod
        if rand(model.rng) ≤ model.deathRate
            agent.SIR_status = :D
            # kill_agent!(agent,model) # TBD: kill agents requires fix to data collection, discuss:remove them from network or leave them with affinity 1 to influence close contacts
            agent.affinity = 1
        else
            agent.SIR_status = :R
            agent.days_infected = 0
        end
    end
end

"count days since recovery & reset to susceptible after protection period"
function update_recovered!(agent,model)
    if agent.days_recovered < model.reinfectionProtection
        agent.days_recovered +=1
    else
        agent.SIR_status = :S
        agent.days_recovered = 0
    end
end

update_vaccinated!(agent, model) = agent.state == 1 && (agent.SIR_status = :V)
