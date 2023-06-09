using DrWatson
@quickactivate "Social Agent Based Modelling"
using Agents
using Printf

"define an agent for 2d grid space"
mutable struct DecisionAgentGrid <:AbstractAgent
    id::Int
    pos::Tuple{Int64,Int64}
    self_reliance::Float64
    fixed_attitude::Float64
    attitude::Float64
    attitude_old::Float64
end

"define an agent for graph space"
mutable struct DecisionAgentGraph <:AbstractAgent
    id::Int
    pos::Int
    self_reliance::Float64
    fixed_attitude::Float64
    attitude::Float64
    attitude_old::Float64
end


function initialize_self_reliance(rng; distribution=Uniform(0.0, 1.0))
    return rand(rng, distribution)
end

function initialize_attitude(rng; distribution=Uniform(0.0, 1.0))
    return rand(rng, distribution)
end

function initialize_fixed_attitude(rng; distribution=Uniform(0.0, 1.0))
    return rand(rng, distribution)
end


"function to add an agent to a space based on position"
function create_agent(model, position; mean=0.5, sigma=0.1, two_levels_self_reliance = false,low_self_reliance=0.5,share_low_self_reliance=0.95,high_self_reliance=0.95, kwargs...)
    # truncated at 0 1 normal distributed self reliance
    initial_self_reliance = initialize_self_reliance(model.rng,distribution=truncated(Normal(mean,sigma),0.0,1.0))

    # second option to create partitioned population 
    if two_levels_self_reliance
        share_high_self_reliance = 1- share_low_self_reliance
        high_or_low_self_reliance = rand(model.rng,Bernoulli(share_high_self_reliance))
        initial_self_reliance = high_or_low_self_reliance*high_self_reliance + (1-high_or_low_self_reliance)*low_self_reliance
    end
    # uniform distributed inital and fixed attitude
    initial_fixed_attitude = initialize_attitude(model.rng) 
    initial_attitude = initialize_attitude(model.rng)
    add_agent!(position,
        model,
        #general parameters
        initial_self_reliance,
        initial_fixed_attitude,
        initial_attitude,
        initial_attitude
    )
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

"social influence based on neighbours attitude"
function attitude_social_influence(agent, model::AgentBasedModel)
    #calculate neighbours maximum distance based on
    social_influence = 0.0
    sumNeighbourWeights = 0
    neighbours = nearby_agents(agent,model,model.neighbourhoodExtent)
                      
    @inbounds for n in neighbours
        nWeight = 1
        social_influence += (n.attitude_old-agent.attitude) * nWeight
        sumNeighbourWeights +=nWeight
    end
    if sumNeighbourWeights>0
        social_influence /= sumNeighbourWeights
    end

    # adjust by self-reliance factor
    social_attitude_change = (1 - agent.self_reliance) * social_influence
    individual_attitude_change = agent.self_reliance * (agent.attitude_old - agent.attitude) * (abs(social_influence))
    combined_attitude_change = social_attitude_change + individual_attitude_change

    # adjust by scaling factor lambda 
    return combined_attitude_change * model.lambda
end

"step function for agents"
function agent_step!(agent, model)
    attitude_delta = attitude_social_influence(agent, model) 
    unbounded_attitude = agent.attitude + attitude_delta
    agent.attitude = min(model.upper_attitude_bound, max(model.lower_attitude_bound,unbounded_attitude))
end
