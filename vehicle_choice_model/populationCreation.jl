using Agents

"yielding population with only combustion cars"
function combustion_population(model,numagents,budget)
    for i = 1:numagents
        kilometersPerYear = 15000 + (7500 * (rand(model.rng) - 0.5)) #  diverse population with different millages
        initialCar = 0 # population of combustion engine owners
        starting_affinity = 0
        initialValue = get_car_value(initialCar,model)
        add_agent_single!(
            model,
            #case specific parameters
            kilometersPerYear,
            initialValue,
            initialValue,
            0,
            budget,
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
        kilometersPerYear = 15000 + (7500 * (rand(model.rng) - 0.5)) #  diverse population with different millages
        if (rand(model.rng)<population_split) # random 50/50 distribution of cars
            initialCar = 0
            starting_affinity=0
        else
            initialCar = 1
            starting_affinity=1
        end
        initialValue = get_car_value(initialCar,model)
        add_agent_single!(
            model,
            #case specific parameters
            kilometersPerYear,
            initialValue,
            initialValue,
            0,
            budget,
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
        kilometersPerYear = 15000 + (7500 * (rand(model.rng) - 0.5)) #  diverse population with different millages
        if (i in electric_positions) # blocked population according to minortiy size
            initialCar = 1
            starting_affinity= 1
        else
            initialCar = 0
            starting_affinity= 0
        end
        initialValue = get_car_value(initialCar,model)
        add_agent!((positions.iter[i][1],positions.iter[i][2]),
            model,
            #case specific parameters
            kilometersPerYear,
            initialValue,
            initialValue,
            0,
            budget,
            #general parameters
            initialCar,
            initialCar,
            starting_affinity,
            starting_affinity,
            0,
        )
    end
end
