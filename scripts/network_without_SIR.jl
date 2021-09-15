using DrWatson
@quickactivate "Social Agent Based Modelling"
using Agents, Random, DataFrames, LightGraphs
using Distributions: Poisson, DiscreteNonParametric
using CairoMakie
using LinearAlgebra: diagind
using GraphMakie
using DelimitedFiles
using GraphPlot
using SNAPDatasets

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

include(srcdir("agentFunctions.jl"))
include(srcdir("modelling.jl"))
include(srcdir("populationCreation.jl"))
include(srcdir("hysteresisFunctions.jl"))




"get random personal opionon on decision, skewed by inverted beta dist"
function randomInternalRational(model,distribution=Beta(2,5))
    return 1-rand(model.rng,distribution)
end

function create_agent(model,node;initializeInternalRational=randomInternalRational,initializeAffinity=randomAffinity)
    initialInternalRational=initializeInternalRational(model)
    initialAffinity = initializeInternalRational(model)
    initialState = initialAffinity>model.switchingBoundary ? 1 : 0
    add_agent!(
		node,
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
		create_agent(model,node)
    end
end

function initialize(;args ...)
    return model_decision_agents(mixed_population_network;args ...)
end

function model_decision_agents(placementFunction;seed=1234,
    space = Agents.GraphSpace(SimpleGraph(1000,2000)),
    kwargsPlacement = (),
    #general parameters
	externalRationalInfluence = 0.5,
	neighbourShare = 0.1, # share of neighbours to be considered of sqrt(numberAgents)
	socialInfluenceFactor = 2, #weight of social influence
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
    return (rationalAffinity-agent.affinity)
end

function combined_social_influence(agent::DecisionAgent, model::AgentBasedModel)
    #calculate neighbours maximum distance based on
    combinedSocialInfluence = 0.0
    numberNeighbours = 0
    @inbounds for n in nearby_agents(agent,model,1)
        combinedSocialInfluence =+ ((n.affinity_old-agent.affinity)*0+(n.state_old-agent.state))
        numberNeighbours =+1
    end
	if numberNeighbours > 0
    	combinedSocialInfluence /= numberNeighbours # mean of neighbours opinion
	end
    return combinedSocialInfluence * model.socialInfluenceFactor
end

function state_social_influence(agent::DecisionAgent, model::AgentBasedModel)
    #calculate neighbours maximum distance based on
    combinedSocialInfluence = 0.0
    numberNeighbours = 0
    @inbounds for n in nearby_agents(agent,model,1)
        combinedSocialInfluence =+ n.state_old-agent.state
        numberNeighbours =+1
    end
	if numberNeighbours > 0
    	combinedSocialInfluence /= numberNeighbours # mean of neighbours opinion
	end
    return combinedSocialInfluence * model.socialInfluenceFactor
end

#external rational influence has no meaning here as it is not used
function generate_ensemble(summary_results_directory;space= Agents.Graphspace(SimpleGraph(100,300)), step_length=50, models_per_p = 100,seeds = rand(1234:9999,100),store_model = true, model_directory = "")
        if store_model==true && model_directory == ""
                return("Error: Please specify a model storage path!")
        end
                ensemble_results = DataFrame(Index = 1:models_per_p,Seed = -9999.0, Start_State_Average = -9999.0, Start_Affinity_Average = -9999.0,Final_State_Average = -9999.0 , Final_Affinity_Average = -9999.0)
				index_counter = 1
				@showprogress 1 "Seed Variation..." for i = 1:models_per_p

                        decisionModel = model_decision_agents(mixed_population_network;space=space,seed = seeds[i],socialInfluenceFactor=2,switchingBoundary=0.5)
                        converged = false
                        agent_df, model_df = run!(decisionModel, agent_step!,model_step!, 0; adata = [(:state, mean),(:affinity,mean)])
						ensemble_results[ensemble_results.Index .== index_counter,:Start_State_Average].= agent_df[end,"mean_state"]
 					   	ensemble_results[ensemble_results.Index .== index_counter,:Start_Affinity_Average].= agent_df[end,"mean_affinity"]
						ensemble_results[ensemble_results.Index .== index_counter,:Seed].= seeds[i]
						total_steps=1
                        while converged == false
							#&& total_steps<11
                                agent_df, model_df = run!(decisionModel, agent_step!,model_step!, step_length; adata = [(:state, mean),(:affinity,mean)])
                                converged= check_conversion_osc_recursive(agent_df[end-step_length:end,"mean_affinity"])
								#total_steps = total_steps+1
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


p_beta_dist = Beta(3,2)
x = rand(p_beta_dist,100)
histogram(x)

#test with simple 5 node graph
network_model = initialize(;socialInfluenceFactor=2,switchingBoundary=0.9,seed=5421)
agent_df, model_df = run!(network_model, agent_step!,model_step!, 100; adata = [(:state, mean),(:affinity,mean)])

# test with karate club network
karate_am = readdlm(datadir("karate.txt"))
karate_g = Graph(karate_am)
gplot(karate_g)

seeds = rand(0:1000,100)
decisionModel = model_decision_agents(mixed_population_network;space=Agents.GraphSpace(karate_g),seed = seeds[1],socialInfluenceFactor=2)

generate_ensemble(datadir("network_test");space = Agents.GraphSpace(karate_g),model_directory=datadir("network_test"))

# test with small network from facebook data (standford SNAP)
fb = loadsnap(:facebook_combined)
generate_ensemble(datadir("facebook_test");models_per_p = 10,space = Agents.GraphSpace(fb),model_directory=datadir("facebook_test"))

decisionModel = model_decision_agents(mixed_population_network;space=Agents.GraphSpace(fb),seed = seeds[1],socialInfluenceFactor=2)

function plot_scatter(ensemble_data, path; variable = ensemble_data.Final_State_Average, y_lab = "Final State Average")
        Plots.scatter(ensemble_data.P_Combustion,variable,marker_z = ensemble_data.P_Combustion, xlabel = "p_CombustionShare",ylabel=y_lab)
        png(path)
end

function plot_histogram(ensemble_data, path; variable = ensemble_data.Final_State_Average, y_lab = "Final State Average")
        Plots.histogram(ensemble_data.P_Combustion,variable, xlabel = "p_CombustionShare",ylabel=y_lab)
        png(path)
end
