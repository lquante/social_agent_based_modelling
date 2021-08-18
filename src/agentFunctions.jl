using DrWatson
@quickactivate "Social Agent Based Modelling"
using Agents
"create an agent for 2d grid space"
@agent DecisionAgent GridAgent{2} begin
    internalRationalInfluence::Float64
    state::Int
    state_old::Int
    affinity::Float64
    affinity_old::Float64
    rationalOptimum::Int
end

function set_state!(state::Int,agent::DecisionAgent)
    agent.state = state
end

"computes rational decision for 0= no or 1= yes"
function rational_influence(agent::DecisionAgent,model)
    rationalAffinity = (externalRational(agent,model)+internalRational(agent,model))/2 #equal weighting of external and internal influence
    return rationalAffinity-agent.affinity_old/model.tauRational
end

"computes contribuition for rational decision from external sources"
function externalRational(agent,model)
    return model.externalRationalInfluence # first very simple case:model parameter controls external "forcing"
end
"computes contribuition for rational decision from internal sources"
function internalRational(agent,model)
    return agent.internalRationalInfluence # first very simple case:agent parameter controls internal "forcing"
end

"helper function to calculate neighbours maximum distance as sqrt(number of agents)*neighbourhood_share"
function neighbour_distance(model)
    number_agents = length(model.agents)
    return cld(sqrt(number_agents),1/model.neighbourShare)
end

"returns social influence based on neighbours state"
function state_social_influence(agent::DecisionAgent, model::AgentBasedModel)
    stateSocialInfluence = 0.0
    numberNeighbours = 0
    neighboursMaximumDistance=neighbour_distance(model)
    neighbours = nearby_agents(agent,model,neighboursMaximumDistance)
    @inbounds for n in neighbours
        stateSocialInfluence += (n.state_old-agent.affinity_old)/edistance(n,agent,model) #scaling by exact distance
        numberNeighbours +=1
    end
    stateSocialInfluence /= numberNeighbours # mean of neighbours opinion
    stateSocialInfluence /= neighboursMaximumDistance #such that the maximum social influence is -1/1
    return stateSocialInfluence / model.tauSocial
end

"returns social influence based on neighbours affinity"
function affinity_social_influence(agent::DecisionAgent, model::AgentBasedModel)
    #calculate neighbours maximum distance based on
    affinitySocialInfluence = 0.0
    numberNeighbours = 0
    neighboursMaximumDistance=neighbour_distance(model)
    neighbours = nearby_agents(agent,model,neighboursMaximumDistance)
    @inbounds for n in neighbours
        affinitySocialInfluence += (n.affinity_old-agent.affinity_old)/edistance(n,agent,model) #scaling by exact distance
        numberNeighbours +=1
    end
    affinitySocialInfluence /= numberNeighbours # mean of neighbours opinion
    affinitySocialInfluence /= neighboursMaximumDistance #such that the maximum social influence is -1/1
    return affinitySocialInfluence / model.tauSocial
end

"returns social influence based on neighbours affinity and state combined to improve performance"
function combined_social_influence(agent::DecisionAgent, model::AgentBasedModel)
    #calculate neighbours maximum distance based on
    combinedSocialInfluence = 0.0
    numberNeighbours = 0
    @inbounds for n in nearby_agents(agent,model,neighbour_distance(model))
        combinedSocialInfluence += ((n.affinity_old-agent.affinity_old)+(n.state_old-agent.affinity_old))/edistance(n,agent,model) #scaling by exact distance
        numberNeighbours =+1
    end
    combinedSocialInfluence /= numberNeighbours # mean of neighbours opinion
    combinedSocialInfluence /= neighbour_distance(model) #such that the maximum social influence is -1/1
    return combinedSocialInfluence / model.tauSocial
end


"step function for agents"
function agent_step!(agent, model)
    #store previous affinity
    agent.affinity_old = agent.affinity
    agent.state_old = agent.state
    #compute new affinity
    agent.affinity = min(
  model.upperAffinityBound,
      max(
          model.lowerAffinityBound,
          agent.affinity_old +
          rational_influence(agent,model)
          + combined_social_influence(agent,model)
      )
  )
    if agent.state_old===0 # one way decision, no change for already "yes" decision, Q: should affinity still change as implemented?!
        (agent.affinity<model.switchingBoundary+model.decisionGap) ? set_state!(0,agent) : set_state!(1,agent)
    end
end
