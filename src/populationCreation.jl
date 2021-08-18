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
function mixed_population(model,numagents;noShare=0.5)
    positions = Agents.positions(model)
    for i_position in positions.iter
        create_agent(model,i_position,noShare)
    end
end

"population with only no agents"
function combustion_population(model,numagents)
    mixed_population(model,numagents;noShare=1)
end


"adds an agent at specified position of the model"
function create_agent(model,position,noShare)
    initialAffinity = (rand(model.rng)<noShare) ? 0 : 1 # just assuming Bernoulli distr for now
    initialState = (initialAffinity<(model.switchingBoundary+model.decisionGap)) ? 0 : 1
    initialInternalRational=0.5
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
