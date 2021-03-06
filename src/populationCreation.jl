using DrWatson
@quickactivate "Social Agent Based Modelling"
using Agents
using Distributions

"returns affinity relative to initial state, using a one-sided normal distribuition"
function affinityRandomization(model,state)
    d = Normal(0,1/6)
    normal =   rand(model.rng,d)
    return (state===0) ? state+abs(normal) : state-abs(normal) # assuming binary state space of 0 or 1
end

"population with a specified share of no agents"
function mixed_population_grid(model,numagents;noShare=0.5)
    positions = Agents.positions(model)
    for i_position in positions.iter
        create_agent(model,i_position,noShare)
    end
end

"population with only no agents"
function nosayers_population(model,numagents)
    mixed_population(model,numagents;noShare=1)
end


"adds an agent at specified position of the model"
function create_agent_grid(model,position,noShare;initializeInternalRational=randomInternalRational,initializeAffinity=randomAffinity)
    initialInternalRational=initializeInternalRational(model)
    initialAffinity = initializeAffinity(model,noShare)
    initialState = (initialAffinity<(model.switchingBoundary)) ? 0 : 1
    add_agent!((position[1],position[2]),
        model,
        #general parameters
        initialInternalRational,
        initialState,
        initialState,
        initialAffinity,
        initialAffinity,
        initialState
    )
end

"function to randomly initialize internal rational preference of agent"
function randomInternalRational(model,distribution=Uniform(0,1))
    return rand(model.rng,distribution)
end
"function to randomly initialize affinity of agent"
function randomAffinity(model,noShare)
    distribution=Bernoulli(noShare)
    return rand(model.rng,distribution)
end
