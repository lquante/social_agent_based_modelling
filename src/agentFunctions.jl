using DrWatson
@quickactivate "Social Agent Based Modelling"
using Agents
using Printf

"define an agent for 2d grid space"
mutable struct DecisionAgentGrid <:AbstractAgent
    id::Int
    pos::Tuple{Int64,Int64}
    avantgarde::Float64
    intrinsicBelief::Float64
    state::Int
    state_old::Int
    currentChoice::Float64
    previousChoice::Float64
end

"define an agent for graph space"
mutable struct DecisionAgentGraph <:AbstractAgent
    id::Int
    pos::Int
    avantgarde::Float64
    intrinsicBelief::Float64
    state::Int
    state_old::Int
    currentChoice::Float64
    previousChoice::Float64
end

"get fixed avantgarde factor"
function constantAvantgarde(model)
    return model.constantAvantgarde
end

function initializeAvantgarde(rng, distribution=Uniform(0, 1))
    avantgarde = rand(rng, distribution)
    return avantgarde
end

function initializecurrentChoice(rng, distribution=Uniform(0, 1))
    currentChoice = rand(rng, distribution)
    return currentChoice
end

function initializeintrinsicBelief(rng, distribution=Uniform(0, 1))  # truncated(Normal(0.6, 0.2), 0.0, 1.0))
    rnd = rand(rng, distribution)
    return rnd
end


"function to add an agent to a space based on position"
function create_agent(model,position)
    initialAvantgarde = initializeAvantgarde(model.rng)
    initialintrinsicBelief = initializeintrinsicBelief(model.rng)
    initialcurrentChoice = initializecurrentChoice(model.rng)
    initialState = 0
    add_agent!(position,
        model,
        #general parameters
        initialAvantgarde,
        initialintrinsicBelief,
        initialState,
        initialState,
        initialcurrentChoice,
        initialcurrentChoice
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


"social influence based on neighbours currentChoice"
function currentChoice_social_influence(agent, model::AgentBasedModel)
    #calculate neighbours maximum distance based on
    currentChoiceSocialInfluence = 0.0
    sumNeighbourWeights = 0
    neighbours = nearby_agents(agent,model,model.neighbourhoodExtent)
                      
    @inbounds for n in neighbours
        nWeight = 1 # neighbourWeight(agent,n,model)
        currentChoiceSocialInfluence += (n.previousChoice-agent.currentChoice) * nWeight
        sumNeighbourWeights +=nWeight
    end
    if sumNeighbourWeights>0
        # sumNeighbourWeights = 0.5 / (currentChoiceSocialInfluence + 1)
        currentChoiceSocialInfluence /= sumNeighbourWeights #such that the maximum social influence is 1
    end

    # adjust by avantgarde factor
    crowdBehaviour = (1 - agent.avantgarde) * currentChoiceSocialInfluence
    alpha = 1
    soloBehaviour = agent.avantgarde * alpha * (agent.intrinsicBelief - agent.currentChoice) * (abs(currentChoiceSocialInfluence)) #* RiemannTheta((-1) * agent.avantgarde * currentChoiceSocialInfluence)
    avantgardedInfluence = crowdBehaviour + soloBehaviour

    # adjust by tauSocial 
    return avantgardedInfluence / model.tauSocial
end

"step function for agents"
function agent_step!(agent, model)
    # one way decision, no change for already "yes" decision, Q: should currentChoice still change?
    # compute new currentChoice    

    deltaCurrentChoice = currentChoice_social_influence(agent, model) 
    unboundedCurrentChoice = agent.currentChoice + deltaCurrentChoice
    
    # set new currentChoice respecting the bounds for the currentChoice
    
    agent.currentChoice = min(model.uppercurrentChoiceBound, max(model.lowercurrentChoiceBound,unboundedCurrentChoice))
    if agent.state===0 
        #change state if currentChoice large enough & switching still possible
        if model.numberSwitched < model.switchingLimit
            if (agent.currentChoice >= model.switchingBoundary)
                set_state!(1,agent)
                model.numberSwitched+=1
            end
        end
    end

    #store state for social influence in next timestep
    agent.state_old = agent.state
end
