using Agents
using Distributions

function millageRandomization(model)
    return 15000 + (7500 * (rand(model.rng) - 0.5)) #  diverse population with different millages
end

function incomeRandomization(model)
    return 5000 #  diverse population with different incomes
end

"returns affinity relative to initial state, using a one-sided normal distribuition"
function affinityRandomization(model,state)
    d = Normal(0,1/6)
    normal =   rand(d)
    return (state==0) ? state+normal : state-abs(normal) # assuming binary state space of 0 or 1
end

"yielding population with only combustion cars"
function combustion_population(model,numagents,budget)
    for i = 1:numagents
        initialCar = 0 # population of combustion engine owners
        starting_affinity = affinityRandomization(model,initialCar)
        initialValue = get_car_value(initialCar,model)
        add_agent_single!(
            model,
            #case specific parameters
            millageRandomization(model),
            initialValue,
            initialValue,
            0,
            budget,
            incomeRandomization(model),
            #general parameters
            initialCar,
            initialCar,
            starting_affinity,
            starting_affinity,
            0,
        )
    end
end

"yielding population with a share of electric cars"
function mixed_population(model,numagents,budget;population_split=0.25)
    for i = 1:numagents
        initialCar = (rand(model.rng)<population_split) ? 0 : 1
        starting_affinity= affinityRandomization(model,initialCar)
        initialValue = get_car_value(initialCar,model)
        add_agent_single!(
            model,
            #case specific parameters
            millageRandomization(model),
            initialValue,
            initialValue,
            0,
            budget,
            incomeRandomization(model),
            #general parameters
            initialCar,
            initialCar,
            starting_affinity,
            starting_affinity,
            0,
        )
    end
end

"yielding population with electric cars in the electric positions parameter"
function electric_minority(model,numagents,budget;electric_positions = [1,2,3,4,5,11,12,13,14,15,21,23,24,25,31,32,33,34,35])

    positions = Agents.positions(model)
    electric_positions = [1,2,3,4,5,11,12,13,14,15,21,22,23,24,25,31,32,33,34,35]
    for i = 1:numagents
        initialCar = (i in electric_positions) ? 1 : 0 # blocked population according to minortiy size
        starting_affinity= affinityRandomization(model,initialCar)
        initialValue = get_car_value(initialCar,model)
        add_agent!((positions.iter[i][1],positions.iter[i][2]),
            model,
            #case specific parameters
            millageRandomization(model),
            initialValue,
            initialValue,
            0,
            budget,
            incomeRandomization(model),
            #general parameters
            initialCar,
            initialCar,
            starting_affinity,
            starting_affinity,
            0,
        )
    end
end
