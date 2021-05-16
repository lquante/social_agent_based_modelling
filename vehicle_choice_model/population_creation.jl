using Agents

function create_combustion_population(model,numagents,budget)
    for i = 1:numagents
        kilometersPerYear = 15000 + (7500 * (rand(model.rng) - 0.5)) #  diverse population with different millages
        initialVehicle = 1 # population of combustion engine owners
        initialValue = get_vehicle_value(model,initialVehicle)
        add_agent_single!(
            model,
            kilometersPerYear,
            initialVehicle,
            initialValue,
            initialValue,
            0,
            budget,
            1,
            1
        )
    end
end


function create_mixed_population(model,numagents,budget)
    for i = 1:numagents
        kilometersPerYear = 15000 + (7500 * (rand(model.rng) - 0.5)) #  diverse population with different millages
        if (rand(model.rng)<0.5) # random 50/50 distribution of cars
            initialVehicle = 1
        else
            initialVehicle = 2
        end
        initialValue = get_vehicle_value(model,initialVehicle)
        add_agent_single!(
            model,
            kilometersPerYear,
            initialVehicle,
            initialValue,
            initialValue,
            0,
            budget,
            initialVehicle,
            initialVehicle
        )
    end
end

function create_electric_minority(model,numagents,budget)

    positions = Agents.positions(model)
    minority_positions = [1,2,3,4,5,11,12,13,14,15,21,23,24,25,31,32,33,34,35]
    for i = 1:numagents
        kilometersPerYear = 15000 + (7500 * (rand(model.rng) - 0.5)) #  diverse population with different millages
        if (i in minority_positions) # blocked population according to minortiy size
            initialVehicle = 2
        else
            initialVehicle = 1
        end
        initialValue = get_vehicle_value(model,initialVehicle)
        add_agent!((positions.iter[i][1],positions.iter[i][2]),
            model,
            kilometersPerYear,
            initialVehicle,
            initialValue,
            initialValue,
            0,
            budget,
            initialVehicle,
            initialVehicle
        )
    end
end
