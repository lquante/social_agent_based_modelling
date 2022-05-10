using DrWatson
@quickactivate "Social Agent Based Modelling"
using Agents
using Printf

"define an agent for 2d grid space"
mutable struct DecisionAgentGrid <:AbstractAgent
    id::Int
    pos::Tuple{Int64,Int64}
    avantgarde::Float64
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
    state::Int
    state_old::Int
    affinity::Float64
    affinity_old::Float64
end


"get fixed avantgarde factor"
function constantAvantgarde(model)
    return model.constantAvantgarde
end

"get varying avantgarde factor"
function getAvantgarde(model)
    avantgarde = 0.0    
    rnd = rand(model.rng, Uniform(0.0, 1.0))
    p = 0.01
    if rnd < p
        avantgarde = 1.0
    end
    return avantgarde
end

"get random avantgarde factor, skewed by inverted beta dist"
function randomAvantgarde(model,distribution=Beta(2,3))
    return 1-rand(model.rng,distribution)
end
"get random affinity on decision, skewed by inverted beta dist"
function randomAffinity(model,distribution=Beta(2,3))
    return 1-rand(model.rng,distribution)
end

"get random affinity on decision, skewed by inverted beta dist"
function randomAffinityNormal(model,distribution=Beta(0.6, 4.)) # truncated(Normal(0.5,0.5),0,1))
    return rand(model.rng,distribution)
end

function constantAffinity(model)
    return 0.1
end

"function to add an agent to a space based on position"
function create_agent(model,position;initializeAvantgarde=constantAvantgarde,initializeAffinity=randomAffinityNormal)
    initialAvantgarde=initializeAvantgarde(model)
    initialAffinity = initializeAffinity(model)
    initialState = 0
    add_agent!(position,
        model,
        #general parameters
        initialAvantgarde,
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
    crowdBehaviour = (1 - abs(agent.avantgarde)) * affinitySocialInfluence
    soloBehaviour = agent.avantgarde * (1 - abs(affinitySocialInfluence)) #* RiemannTheta((-1) * agent.avantgarde * affinitySocialInfluence)
    avantgardedInfluence = crowdBehaviour + soloBehaviour
    
#    if (Sgn(agent.avantgarde) * Sgn(affinitySocialInfluence) != -1) && (agent.avantgarde != 0)
#        @printf "agent anormal a=%.5f W=%.5f\n" agent.avantgarde affinitySocialInfluence
#    end

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
