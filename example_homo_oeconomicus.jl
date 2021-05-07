using Agents
using Statistics
using InteractiveDynamics
using GLMakie

@agent homoOeconomicus GridAgent{2} begin
    kilometersPerYear::Float64
    vehicle::Int # very primitive state variable: 1 = combustion engine, 2 = electirc vehicle
    vehicleValue::Float64
    purchaseValue::Float64
    vehicleAge::Int
end

population = 100
space = Agents.GridSpace((10,10);periodic=false, metric = :euclidean)

function modelHomeOeconmicus(space;numagents=population,priceCombustionVehicle = 10000, priceElectricVehicle = 20000, fuelCostKM= 0.1, powerCostKM= 0.05,maintenanceCostCombustionKM = 0.005,maintenanceCostElectricKM = 0.01)
    local model = ABM(homoOeconomicus,space,scheduler=Agents.fastest,
    properties = Dict(:priceCombustionVehicle => priceCombustionVehicle,:priceElectricVehicle => priceElectricVehicle,:fuelCostKM => fuelCostKM,:powerCostKM => powerCostKM,:maintenanceCostCombustionKM=>maintenanceCostCombustionKM,:maintenanceCostElectricKM => maintenanceCostElectricKM))
    for i in 1:numagents
        kilometersPerYear = 15000+(7500*(rand(model.rng)-0.5))
        initialVehicle = 1 # yielding a population of combustion engine owners
        initialValue = 0.0
        if initialVehicle==1
            initialValue=priceCombustionVehicle
        end
        add_agent_single!(model,kilometersPerYear,initialVehicle,initialValue,initialValue,0)
    end
    return model
end

function yearlyVehicleCost(yrlyKilometers::Float64,vehicleAge,fuelCostKM::Float64,maintenanceCostKM::Float64)
    return yrlyKilometers*(fuelCostKM+maintenanceCostKM*vehicleAge)
end

function depreciateVehicleValue(purchaseValue,vehicleAge,feasibileYears)
    return purchaseValue-(1/feasibileYears)*purchaseValue*vehicleAge # very simple linear depreciation
end

function agent_step!(agent,model)
    agent.vehicleAge = agent.vehicleAge+1
    # calculate cost-benefit of current car:
    if(agent.vehicle==1)
        currentCost = yearlyVehicleCost(agent.kilometersPerYear,agent.vehicleAge,model.fuelCostKM,model.maintenanceCostCombustionKM)
    end
    if(agent.vehicle==2)
        currentCost = yearlyVehicleCost(agent.kilometersPerYear, agent.vehicleAge,model.powerCostKM,model.maintenanceCostElectricKM)
    end
    #calculate cost-benefit of a new car:
    #assumption: all vehicles are assumed to last at least 300.000km before purchase
    feasibileYears = cld(300000,agent.kilometersPerYear) # rounding up division
    newCombustionCost = 0
    newElectricCost = 0
    for i_year in 1:feasibileYears-agent.vehicleAge
        if(agent.vehicle==1)
            currentCost += yearlyVehicleCost(agent.kilometersPerYear,agent.vehicleAge+i_year,model.fuelCostKM,model.maintenanceCostCombustionKM)
        end
        if(agent.vehicle==2)
            currentCost += yearlyVehicleCost(agent.kilometersPerYear,agent.vehicleAge+i_year,model.powerCostKM,model.maintenanceCostElectricKM)
        end
    end
    for i_year in 1:feasibileYears
        newCombustionCost += yearlyVehicleCost(agent.kilometersPerYear,i_year,model.fuelCostKM,model.maintenanceCostCombustionKM)
        newElectricCost += yearlyVehicleCost(agent.kilometersPerYear,i_year,model.powerCostKM,model.maintenanceCostElectricKM)
    end
    # calculte purchasing cost after selling old car:
    newCombustionPurchase = model.priceCombustionVehicle-agent.vehicleValue
    newElectricPurchase = model.priceElectricVehicle-agent.vehicleValue
    # compare average cost
    currentVehicleAverageCost = (currentCost+agent.vehicleValue)/(feasibileYears-agent.vehicleAge)
    newCombustionAverageCost = (newCombustionCost+newCombustionPurchase)/feasibileYears
    newElectricAverageCost = (newElectricCost+newElectricPurchase)/feasibileYears

    #make decision and update vehicle attributes
    if (min(newCombustionAverageCost,newElectricAverageCost) < currentVehicleAverageCost)
        if (newCombustionAverageCost < newElectricAverageCost)
            agent.vehicle = 1
            agent.vehicleValue = model.priceCombustionVehicle
            agent.purchaseValue = model.priceCombustionVehicle
            agent.vehicleAge = 0
        else
            agent.vehicle = 2
            agent.vehicleValue = model.priceElectricVehicle
            agent.purchaseValue = model.priceElectricVehicle
            agent.vehicleAge = 0
        end
    else
        agent.vehicleValue = depreciateVehicleValue(agent.purchaseValue,agent.vehicleAge,feasibileYears)
    end
end

function model_step!(model)
    for a in allagents(model)
        rand(model.rng)
    end
end


gaiaOeconomicus = modelHomeOeconmicus(space)

Agents.step!(gaiaOeconomicus,agent_step!,model_step!,1)


parange = Dict(:priceCombustionVehicle => 5000:30000,:priceElectricVehicle => 5000:30000,:fuelCostKM=>range(0.05,0.5;step=0.05),:powerCostKM=>range(0.05,0.5;step=0.05))

adata = [(:vehicleValue, mean), (:vehicle, mean)]
alabels = ["vehicleValue", "avg. vehicle"]

vehiclecolor(a) = a.vehicle == 1 ? :orange : :blue
vehiclemarker(a) = a.vehicle == 1 ? :circle : :rect

scene, adf, modeldf = abm_data_exploration(gaiaOeconomicus, agent_step!, model_step!, parange;
                ac = vehiclecolor, am = vehiclemarker,as = 4, adata = adata, alabels = alabels)
