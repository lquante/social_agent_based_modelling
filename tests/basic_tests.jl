using DrWatson
@quickactivate "Social Agent Based Modelling"
using Test
using Random
include(srcdir("agentFunctions.jl"))
include(srcdir("modelling.jl"))
include(srcdir("populationCreation.jl"))
include(srcdir("hysteresisFunctions.jl"))


@testset "model creation" begin
    for i in 1:100
        spaceDims = (i,i)
        test_model = initialize(;seed=1234,space=Agents.GridSpace(spaceDims;periodic=true,metric = :euclidean))
        tagent=rand(test_model.agents)[2]
        @test typeof(test_model) == AgentBasedModel{GridSpace{2, true, Nothing}, CarOwner, typeof(Agents.Schedulers.fastest), ModelParameters, MersenneTwister}
        @test typeof(tagent) == CarOwner
    end
end

spaceDims = (50,50)
test_model = initialize(;seed=1234,space=Agents.GridSpace(spaceDims;periodic=true,metric = :euclidean))
@testset "agentFunctions.jl" begin
    for i_agent in rand(test_model.agents,100)
        tagent = i_agent[2]
        @testset "getters and setters" begin
            @test get_car_price(0,test_model) ==test_model.priceCombustionCar
            @test get_car_price(1,test_model) ==test_model.priceElectricCar
            test_iterations  = 100
            for state in [0,1]
                set_state!(state,tagent)
                @test tagent.state == state
            end
            for carValue in rand(0:0.5:10000,test_iterations)
                set_carValue!(carValue,tagent)
                @test tagent.carValue == carValue
                set_purchaseValue!(carValue,tagent)
                @test tagent.purchaseValue == carValue
            end
            for carAge in rand(0:100,test_iterations)
                set_carAge!(carAge,tagent)
                @test tagent.carAge == carAge
            end
            for budgetChange in rand(0:10000,test_iterations)
                previousBudget = tagent.budget
                update_budget!(budgetChange,tagent)
                @test tagent.budget == previousBudget-budgetChange
            end
            for new_budget in rand(0:0.25:10000,test_iterations)
                set_budget!(new_budget,tagent)
                @test tagent.budget == new_budget
            end
        end
    end
end

@testset "cost functions" begin
    random_agents = rand(test_model.agents,1000)
    for i_agent in random_agents
        i_agent = i_agent[2]
        fuelCostKM = (i_agent.state ===0 ? test_model.fuelCostKM : test_model.powerCostKM)
        maintenanceCostKM = (i_agent.state ===0 ? test_model.maintenanceCostCombustionKM : test_model.maintenanceCostElectricKM)
        yearly_cost = yearly_car_cost(i_agent.kilometersPerYear,i_agent.carAge,fuelCostKM,maintenanceCostKM)
        @test yearly_cost >= 0
        usageYears=25
        multi_year_cost = multi_year_car_cost(i_agent.kilometersPerYear,usageYears,i_agent.carAge,i_agent.state,test_model)
        @test multi_year_cost >= yearly_cost*(usageYears-i_agent.carAge)
        average_cost = average_car_cost(i_agent.kilometersPerYear, usageYears,i_agent.carAge, i_agent.state, test_model)
        @test multi_year_cost/(usageYears-i_agent.carAge) == average_cost
        @test depreciate_car_value(i_agent,test_model) <= i_agent.carValue
    end
end
