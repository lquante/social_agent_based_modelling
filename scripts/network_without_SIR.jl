using Agents, Random, DataFrames, LightGraphs
using Distributions: Poisson, DiscreteNonParametric
using DrWatson: @dict
using CairoMakie
using LinearAlgebra: diagind
using GraphMakie
using DrWatson
using DelimitedFiles
@quickactivate "Social Agent Based Modelling"
include(srcdir("agentFunctions.jl"))
include(srcdir("modelling.jl"))
include(srcdir("populationCreation.jl"))
include(srcdir("hysteresisFunctions.jl"))


mutable struct DecisionAgent <: AbstractAgent
    id:: Int
    pos:: Int
    internalRationalInfluence::Float64
    state::Int
    state_old::Int
    affinity::Float64
    affinity_old::Float64
    rationalOptimum::Int
end

function randomInternalRational(model,distribution=Beta(2,5))
    return 1-rand(model.rng,distribution)
end

function create_agent(model;initializeInternalRational=randomInternalRational,initializeAffinity=randomAffinity)
    initialInternalRational=initializeInternalRational(model)
    initialAffinity = initialInternalRational
    initialState = 0
    add_agent_single!(
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

function mixed_population_network(model)
    for node in 1:length(model.space.s)
		create_agent(model)
    end
end

function initialize(;args ...)
    return model_decision_agents(mixed_population_network;args ...)
end

function model_decision_agents(placementFunction;seed=1234,
    space = Agents.GraphSpace(SimpleGraph(5,5)),
    kwargsPlacement = (),
    #general parameters
	externalRationalInfluence = 0.5,
	neighbourShare = 0.1, # share of neighbours to be considered of sqrt(numberAgents)
	socialInfluenceFactor = 0.5, #weight of social influence
    switchingBias=1.0, #bias to switching, if <1, bias towards state 1, if >1, bias towards state 0
    switchingBoundary=0.5, # bound for affinity to switch state
    lowerAffinityBound = 0.0,
    upperAffinityBound = 1.0,
    scenario=0.,
    timepoint=0.)

	properties = ModelParameters(
            externalRationalInfluence,
			neighbourShare,
            socialInfluenceFactor,
            switchingBias,
            switchingBoundary,
            lowerAffinityBound,
            upperAffinityBound,
            scenario,
            timepoint
    )
    model = ABM(
        DecisionAgent,
        space;rng=(Random.seed!(seed)),
        properties = properties
    )
    placementFunction(model;kwargsPlacement...)
    return model
end

function rational_influence(agent::DecisionAgent,model)
    rationalAffinity = internalRational(agent,model)
    return (rationalAffinity-agent.affinity_old)
end

function combined_social_influence(agent::DecisionAgent, model::AgentBasedModel)
    #calculate neighbours maximum distance based on
    combinedSocialInfluence = 0.0
    numberNeighbours = 0
    @inbounds for n in nearby_agents(agent,model,1)
        combinedSocialInfluence += ((n.affinity_old-agent.affinity_old)+(n.state_old-agent.affinity_old))
        numberNeighbours =+1
    end
    combinedSocialInfluence /= numberNeighbours # mean of neighbours opinion
    combinedSocialInfluence /= neighbour_distance(model) #such that the maximum social influence is -1/1
    return combinedSocialInfluence * model.socialInfluenceFactor
end

#external rational influence has no meaning here as it is not used
function generate_ensemble(summary_results_directory;space= Agents.GridSpace((gridsize, gridsize); periodic = true, metric = :euclidean), step_length=50, models_per_p = 100,seeds = rand(1234:9999,100),store_model = true, model_directory = "")
        if store_model==true && model_directory == ""
                return("Error: Please specify a model storage path!")
        end
                ensemble_results = DataFrame(Index = 1:models_per_p,Seed = -9999.0, Start_State_Average = -9999.0, Start_Affinity_Average = -9999.0,Final_State_Average = -9999.0 , Final_Affinity_Average = -9999.0)
				index_counter = 1
				@showprogress 1 "Seed Variation..." for i = 1:models_per_p

                        decisionModel = model_decision_agents(mixed_population_network;space=Agents.GraphSpace(karate_g),seed = seeds[i],socialInfluenceFactor=2)
                        converged = false
                        agent_df, model_df = run!(decisionModel, agent_step!,model_step!, 0; adata = [(:state, mean),(:affinity,mean)])
						ensemble_results[ensemble_results.Index .== index_counter,:Start_State_Average].= agent_df[end,"mean_state"]
 					   	ensemble_results[ensemble_results.Index .== index_counter,:Start_Affinity_Average].= agent_df[end,"mean_affinity"]
						ensemble_results[ensemble_results.Index .== index_counter,:Seed].= seeds[i]
						total_steps=1
                        while converged == false && total_steps<11
                                agent_df, model_df = run!(decisionModel, agent_step!,model_step!, step_length; adata = [(:state, mean),(:affinity,mean)])
                                converged= check_conversion_osc_recursive(agent_df[end-step_length:end,"mean_affinity"])
								total_steps = total_steps+1
                        end

                        #add final values to dataframe
						ensemble_results[ensemble_results.Index .== index_counter,:Final_State_Average].= agent_df[end,"mean_state"]
 					   	ensemble_results[ensemble_results.Index .== index_counter,:Final_Affinity_Average].= agent_df[end,"mean_affinity"]
						ensemble_results[ensemble_results.Index .== index_counter,:Seed].= seeds[i]
						index_counter = index_counter+1
                        #store model
                        if store_model == true
                                parameters = (seed=seeds[i])
                                filename = savename("model",parameters,"bin",digits=10)
                                storage_path=joinpath(model_directory,filename)
                                mkpath(model_directory)
                                serialize(storage_path, decisionModel)
                        end
                end
                min_seed= minimum(seeds)
                max_seed= maximum(seeds)
                params = @ntuple min_seed max_seed
                filename = savename("ensemble_overview",params,".csv",digits=10)
                storage_path=joinpath(summary_results_directory,filename)
                mkpath(summary_results_directory)
                CSV.write(storage_path, ensemble_results)
end


p_beta_dist = Beta(2,5)
p_range = rand(p_beta_dist, 100)


network_model = initialize(;seed=1234)

agent_df, model_df = run!(network_model, agent_step!,model_step!, 10; adata = [(:state, mean),(:affinity,mean)])

graphplot(test.space.graph)

p_normal_dist = truncated(Normal(0.5, 0.05), 0.3, 0.6)
p_range = rand(p_normal_dist, 2)

karate_am = readdlm("C:\\Users\\stecheme\\Documents\\Social_Modelling\\karate.txt")
karate_g = Graph(karate_am)

graphplot(karate_g)

generate_ensemble("C:\\Users\\stecheme\\Documents\\Social_Modelling\\network_test";space = Agents.GraphSpace(karate_g),model_directory="C:\\Users\\stecheme\\Documents\\Social_Modelling\\network_test")

decisionModel = model_decision_agents(mixed_population_network;space=Agents.GraphSpace(karate_g),seed = seeds[i],socialInfluenceFactor=2)