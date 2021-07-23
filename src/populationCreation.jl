using DrWatson
@quickactivate "Social Agent Based Modelling"
using Agents
using Distributions

function millageRandomization(model)
    return 15000 + (7500 * (rand(model.rng) - 0.5)) #  diverse population with different millages
end

function incomeRandomization(model)
    return 5000 + (2500 * (rand(model.rng) - 0.5)) #  diverse population with different incomes could be enabled here
end

"returns affinity relative to initial state, using a one-sided normal distribuition"
function affinityRandomization(model,state)
    d = Normal(0,1/6)
    normal =   rand(model.rng,d)
    return (state===0) ? state+abs(normal) : state-abs(normal) # assuming binary state space of 0 or 1
end

"population with a share of electric cars"
function mixed_population(model,numagents,budget;combustionShare=0.5)
    positions = Agents.positions(model)
    for i_position in positions.iter
        create_agent(model,budget,i_position,combustionShare)
    end
end

"population with only combustion cars"
function combustion_population(model,numagents,budget)
    mixed_population(model,numagents,budget;combustionShare=1)
end


"adds an agent at specified position of the model"
function create_agent(model,budget,position,combustionShare)
    starting_affinity = (rand(model.rng)<combustionShare) ? 0 : 1 # just assuming Bernoulli distr for now
    initialCar = (starting_affinity<(model.switchingBoundary+model.decisionGap)) ? 0 : 1
    initialValue = get_car_price(initialCar,model)
    add_agent!((position[1],position[2]),
        model,
        #case specific parameters
        millageRandomization(model),
        initialValue,
        initialValue,
        0,
        budget,
        5000, # assuming constant income (irrelevant due to infinite budget)
        #general parameters
        initialCar,
        initialCar,
        starting_affinity,
        starting_affinity,
        0, # rational optimum not yet known
    )
end

"population with electric cars in the electric positions parameter"
function electric_minority(model,numagents,budget;electric_positions = [1,2,3,4,5,6,7,31,32,33,34,35,36,37,61,62,63,64,65,66,67,91,92,93,94,95,96,97,121,122,123,124,125,126,127])
    positions = Agents.positions(model)
    for i = 1:numagents
        initialCar = (i in electric_positions) ? 1 : 0 # blocked population according to minortiy size
        starting_affinity= affinityRandomization(model,initialCar)
        initialValue = get_car_price(initialCar,model)
        add_agent!((positions.iter[i][1],positions.iter[i][2]),
            model,
            #case specific parameters
            millageRandomization(model),
            initialValue,
            initialValue,
            0,
            budget,
            5000, # assuming constant income (irrelevant due to infinite budget)
            #general parameters
            initialCar,
            initialCar,
            starting_affinity,
            starting_affinity,
            0, # rational optimum not yet known
        )
    end
end
