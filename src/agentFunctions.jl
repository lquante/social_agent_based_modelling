using DrWatson
@quickactivate "Social Agent Based Modelling"
using Agents
using Printf

"define an agent for 2d grid space"
mutable struct DecisionAgentGrid <:AbstractAgent
    id::Int
    pos::Tuple{Int64,Int64}
    avantgarde::Float64
    affinityGoal::Float64
    state::Int
    state_old::Int
    affinity::Float64
    affinity_old::Float64
end

"define an agent for graph space"
mutable struct DecisionAgentGraph <:AbstractAgent
    id::Int
    pos::Int
    avantgarde::Float64
    affinityGoal::Float64
    state::Int
    state_old::Int
    affinity::Float64
    affinity_old::Float64
end


"get fixed avantgarde factor"
function constantAvantgarde(model)
    return model.constantAvantgarde
end

function initializeAvantgarde(rng; distribution=Uniform(0.0, 1))
    avantgarde = rand(rng, distribution)
    #b = 0.2
    #avantgarde *= 2 * b
    #if avantgarde >= b
    #    avantgarde += 1 - b
    #end
    return avantgarde
end

function initializeAffinity(rng; distribution=Uniform(0, 1))
    affinity = rand(rng, distribution)
    return affinity
end

function initializeAffinityGoal(rng; distribution=Uniform(0, 1))  # truncated(Normal(0.6, 0.2), 0.0, 1.0))
    rnd = rand(rng, distribution)
    return rnd
end


"function to add an agent to a space based on position"
function create_agent(model, position; alpha=0., beta=0., kwargs...)
    #if alpha == 0
    #    throw(ArgumentError("Invalid alpha"))
    #end
    initialAvantgarde = initializeAvantgarde(model.rng) #, distribution=truncated(Beta(alpha, beta), 0.0, 1.0))
    initialAffinityGoal = initializeAffinityGoal(model.rng) #, distribution=truncated(Beta(alpha, beta), 0.0, 1.0))
    initialAffinity = initializeAffinity(model.rng) #, distribution=truncated(Beta(alpha, beta), 0.0, 1.0))
    initialState = 0
    add_agent!(position,
        model,
        #general parameters
        initialAvantgarde,
        initialAffinityGoal,
        initialState,
        initialState,
        initialAffinity,
        initialAffinity
    )
end

function set_state!(state::Int,agent::AbstractAgent)
    agent.state = state
end

"distance of neighbour depending on space type of model"
function neighbourDistance(agent,neighbour,model)
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

"directed weighting scheme (influencers make opinions)"
function neighbourWeight(agent,neighbour,model)
        if typeof(model.space)<:Agents.GraphSpace
            return 1 # equal weighting for simplicity
        else
            return 1 # no weighting of neighbours in grid space
        end
end

function RiemannTheta(x)
    if x >= 0
        return 1
    else
        return 0
    end
end

function Sgn(x)
    if x >=0
        return 1
    else
        return -1
    end
end

"social influence based on neighbours affinity"
function affinity_social_influence(agent, model::AgentBasedModel)
    #calculate neighbours maximum distance based on
    affinitySocialInfluence = 0.0
    sumNeighbourWeights = 0
    neighbours = nearby_agents(agent,model,model.neighbourhoodExtent)
                      
    @inbounds for n in neighbours
        nWeight = 1 # neighbourWeight(agent,n,model)
        affinitySocialInfluence += (n.affinity_old-agent.affinity) * nWeight
        sumNeighbourWeights +=nWeight
    end
    if sumNeighbourWeights>0
        # sumNeighbourWeights = 0.5 / (affinitySocialInfluence + 1)
        affinitySocialInfluence /= sumNeighbourWeights #such that the maximum social influence is 1
    end

    # adjust by avantgarde factor
    crowdBehaviour = (1 - agent.avantgarde) * affinitySocialInfluence
    alpha = 1
    soloBehaviour = agent.avantgarde * alpha * (agent.affinityGoal - agent.affinity) * (abs(affinitySocialInfluence))
    avantgardedInfluence = crowdBehaviour + soloBehaviour

    # adjust by tauSocial 
    return avantgardedInfluence / model.tauSocial
end

"step function for agents"
function agent_step!(agent, model)
    # one way decision, no change for already "yes" decision, Q: should affinity still change?
    # compute new affinity    

    deltaAffinity = affinity_social_influence(agent, model) 
    unbounded_affinity = agent.affinity + deltaAffinity
    
    # set new affinity respecting the bounds for the affinity
    
    agent.affinity = min(model.upperAffinityBound, max(model.lowerAffinityBound,unbounded_affinity))
    if agent.state===0 
        #change state if affinity large enough & switching still possible
        if model.numberSwitched < model.switchingLimit
            if (agent.affinity >= model.switchingBoundary)
                set_state!(1,agent)
                model.numberSwitched+=1
            end
        end
    end

    #store affinity and state for social influence in next timestep
    #agent.affinity_old = agent.affinity
    agent.state_old = agent.state
end
