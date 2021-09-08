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
        @test typeof(test_model) == AgentBasedModel{GridSpace{2, true, Nothing}, DecisionAgent, typeof(Agents.Schedulers.fastest), ModelParameters, MersenneTwister}
        @test typeof(tagent) == DecisionAgent
    end
end

spaceDims = (50,50)
test_model = initialize(;seed=1234,space=Agents.GridSpace(spaceDims;periodic=true,metric = :euclidean))
@testset "agentFunctions.jl" begin
    for i_agent in rand(test_model.agents,100)
        tagent = i_agent[2]
            test_iterations  = 100
            for state in [0,1]
                set_state!(state,tagent)
                @test tagent.state == state
            end
    end
end
