using DrWatson
@quickactivate "Social Agent Based Modelling"
using Agents, Random, DataFrames, LightGraphs
using Distributions: Poisson, DiscreteNonParametric
using CairoMakie
using LinearAlgebra: diagind
using GraphMakie
using DelimitedFiles
using GraphPlot


include(srcdir("agentFunctions.jl"))
include(srcdir("modelling.jl"))
include(srcdir("populationCreation.jl"))
include(srcdir("hysteresisFunctions.jl"))


function generate_ensemble(summary_results_directory;space= Agents.GraphSpace(SimpleGraph(100,300)), step_length=50, models_per_p = 100,seeds = rand(1234:9999,100),store_model = true, model_directory = "")
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
)
