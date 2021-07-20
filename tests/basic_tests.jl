test_modelusing DrWatson
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
        tagent=test.agents[23]
        @test typeof(test_model) ==AgentBasedModel{GridSpace{2, true, Nothing}, CarOwner, typeof(Agents.Schedulers.fastest), ModelParameters, MersenneTwister}
        @test typeof(tagent) == CarOwner
    end

end
spaceDims = (50,50)
test_model = initialize(;seed=1234,space=Agents.GridSpace(spaceDims;periodic=true,metric = :euclidean))
tagent=test.agents[23]
@testset "agentFunctions.jl" begin
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

@testset "cost functions" begin
    fuelCostKM = (tagent.state ===0 ? model.fuelCostKM : model.powerCostKM)
    maintenanceCostKM = (tagent.state ===0 ? model.maintenanceCostCombustionKM : model.maintenanceCostElectricKM)
    @test yearly_car_cost(tagent.kilometersPerYear,tagent.carAge,fuelCostKM,maintenanceCostKM) >= 0
end
