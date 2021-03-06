using DrWatson
@quickactivate "Social Agent Based Modelling"
using Random
using Serialization
using DataFrames,DataFramesMeta
using CSV
using Plots
using Distributions
using ProgressMeter
using Glob

"plots a histogram of the no share distribution
the path needs to be specified with .png at the end"
function plot_share_histogram(pNo, path)
    Plots.histogram(pNo_range,xlabel="p_CombustionShare",ylabel="Count" )
    png(path)
end

"determine whether or not the grid already converged
input is a vector of mean states of a model as collected in agents_df"
function check_conversion(state_vec,period=1)
        return sum(diff(state_vec[1:period:end]))==0
end
function check_conversion_all(state_vec,period=1)
        x = state_vec[1:period:end]
        return all(y->y==first(x), x)
end

@inline function allequal_fast(x) #https://stackoverflow.com/questions/47564825/check-if-all-the-elements-of-a-julia-array-are-equal
    length(x) < 2 && return true
    e1 = x[1]
    @inbounds for i=2:length(x)
        x[i] == e1 || return false
    end
    return true
end

@inline function allequal_approx(x) #https://stackoverflow.com/questions/47564825/check-if-all-the-elements-of-a-julia-array-are-equal
    length(x) < 2 && return true
    e1 = x[1]
    @inbounds for i=2:length(x)
        x[i] ≈ e1 || return false
    end
    return true
end

function check_conversion_allequal(state_vec,period=1)
        return allequal_fast(state_vec[1:period:end])
end

function check_conversion_approx(state_vec,period=1)
        return allequal_approx(state_vec[1:period:end])
end

"Recursive conversion checker which can account for oscillating behaviour up to a period p, defaults to 5, pmax=1 gives check_conversion"
function check_conversion_osc_recursive(state_vec;pstart=1,pmax=5)
        if check_conversion_approx(state_vec,pstart)
                return true
        end
        if pstart > pmax
                return false
        else
                check_conversion_osc_recursive(state_vec,pstart=pstart+1,pmax=pmax)
        end
end

function check_conversion_osc(state_vec,pmax=5)
        conv=false
        p=1
        while (conv==false) && (p<=pmax)
                conv = check_conversion_allequal(state_vec,p)
                p+=1
        end
        return conv
end

"generates an ensemble of starting models
# Arguments
-'pNo_range': set of probabilities specifying the likelihood for no decision
-'summary_results_directory': where the summaries of the ensemble runs should be stored
-'step_length': how many steps each model should take before checking conversion
-'gridsize': size of the considered grid, number of agents is gridsize squared
-'models_per_p': how many different models should be considered per p in pNo
-'seeds': set of seeds to generate models_per_p different grid population -> reused for each p
To always get the same seeds insert them manually and specify Random.seed!(XXXX)
-'store_model': if the models should be stored (serialized) to be used as a starting ensemble later
-'model_directory': the directory for the storage of the models. If store_model is true and no path is specified there will be an error"
function generate_ensemble(pNo_range,summary_results_directory;space= Agents.GridSpace((gridsize, gridsize); periodic = true, metric = :euclidean), step_length=50,gridsize = 30, models_per_p = 100,seeds = rand(1234:9999,100),store_model = true, model_directory = "")
        if store_model==true && model_directory == ""
                return("Error: Please specify a model storage path!")
        end
        @showprogress 1 "P Variation..." for pNo in pNo_range
                ensemble_results = DataFrame(Seed = seeds, P_Combustion = pNo, Final_State_Average = -9999.0 , Final_Affinity_Average = -9999.0)
                @showprogress 1 "Seed Variation..." for i = 1:models_per_p

                        decisionModel = model_decision_agents(mixed_population;kwargsPlacement=(noShare=pNo,),seed = seeds[i],space=space,socialInfluenceFactor=0.5,externalRationalInfluence=0.5,neighbourShare=0.05)
                        converged = false
                        agent_df, model_df = run!(decisionModel, agent_step!,model_step!, step_length; adata = [(:state, mean),(:affinity,mean)])
                        converged= check_conversion_osc_recursive(agent_df[end-step_length:end,"mean_affinity"])
                        while converged == false
                                agent_df, model_df = run!(decisionModel, agent_step!,model_step!, step_length; adata = [(:state, mean),(:affinity,mean)])
                                converged= check_conversion_osc_recursive(agent_df[end-step_length:end,"mean_affinity"])
                        end

                        #add final values to dataframe
                        ensemble_results[ensemble_results.Seed .== seeds[i],:Final_State_Average].= agent_df[end,"mean_state"]
                        ensemble_results[ensemble_results.Seed .== seeds[i],:Final_Affinity_Average].= agent_df[end,"mean_affinity"]
                        #store model
                        if store_model == true
                                parameters = (pNo=pNo,seed=seeds[i])
                                filename = savename("model",parameters,"bin",digits=10)
                                storage_path=joinpath(model_directory,filename)
                                mkpath(model_directory)
                                serialize(storage_path, decisionModel)
                        end
                end
                min_seed= minimum(seeds)
                max_seed= maximum(seeds)
                params = @ntuple pNo min_seed max_seed
                filename = savename("ensemble_overview",params,".csv",digits=10)
                storage_path=joinpath(summary_results_directory,filename)
                mkpath(summary_results_directory)
                CSV.write(storage_path, ensemble_results)
        end
end

#gets all .bin files from the folder that holds the pre-converged models
function get_model_files(path)
        file_list = glob("*.bin",path)
        return(file_list)
end


#some plotting helper functions

function load_results_data(path)
        files=glob("*.csv", path)
        ensemble_data_list = DataFrame.( CSV.File.( files ) )
        ensemble_data = reduce(vcat, ensemble_data_list)
        return(ensemble_data)
end

function plot_scatter(ensemble_data, path; variable = ensemble_data.Final_State_Average, y_lab = "Final State Average")
        Plots.scatter(ensemble_data.P_Combustion,variable,marker_z = ensemble_data.P_Combustion, xlabel = "p_CombustionShare",ylabel=y_lab)
        png(path)
end

function plot_histogram(ensemble_data, path; variable = ensemble_data.Final_State_Average, y_lab = "Final State Average")
        Plots.histogram(ensemble_data.P_Combustion,variable, xlabel = "p_CombustionShare",ylabel=y_lab)
        png(path)
end

"performs incentive hysteresis
# Arguments
-'all_model_files': File names of the preconverged models
-'incentive variable': model property that is to be changed
-'incentive': value the incentive variable is to be changed to
-'results_storage_path': directory path where the final csv should be stored
-'step_length': how many steps each model should take before checking conversion"

function perform_incentive_hysteresis(all_model_files,incentive_variable, incentive, results_storage_path; step_length = 50,batch_number = 1)
    hysteresis_results = DataFrame(Index = 1:length(all_model_files), Start_State_Average = -9999.0, Start_Affinity_Average = -9999.0, Final_State_Average = -9999.0 , Final_Affinity_Average = -9999.0,incentive_variable = incentive_variable, incentive = incentive)
    step_length = 50
    counter = 1
    print("I got here")
    print(all_model_files)
    print(typeof(all_model_files))
    @showprogress for f in all_model_files
        model=deserialize(f)
        #Call the model with 0 steps to get the current state and affinity. This is a bit hacky maybe there is a better way? Couldn't think of one for now
        agent_df_start, model_df_start = run!(model, agent_step!,model_step!, 0; adata = [(:state, mean),(:affinity,mean)])
        hysteresis_results[hysteresis_results.Index .== counter,:Start_State_Average].=agent_df_start[end,"mean_state"]
        hysteresis_results[hysteresis_results.Index .== counter,:Start_Affinity_Average].=agent_df_start[end,"mean_affinity"]
        #set incentive using meta programming
        if (incentive_variable == "externalRationalInfluence")
                model.properties.externalRationalInfluence=incentive
        else
                return("Error: Not yet implemented incentive!")
        end
        #let it converge
        converged = false
        agent_df, model_df = run!(model, agent_step!,model_step!, step_length; adata = [(:state, mean),(:affinity,mean)])
        while converged == false
                        agent_df, model_df = run!(model, agent_step!,model_step!, step_length; adata = [(:state, mean),(:affinity,mean)])
                        converged= check_conversion_osc_recursive(agent_df[end-step_length:end,"mean_affinity"])
        end

        hysteresis_results[hysteresis_results.Index .== counter,:Final_State_Average].=agent_df[end,"mean_state"]
        hysteresis_results[hysteresis_results.Index .== counter,:Final_Affinity_Average].=agent_df[end,"mean_affinity"]
        counter = counter +1
    end
    filename = "hysteresis_overview_incentive_variable_"* string(incentive_variable)*"_incentive_"*string(convert(Int,incentive))*"_batch_"*string(batch_number)*".csv"
    storage_path=joinpath(results_storage_path,filename)
    mkpath(results_storage_path)
    CSV.write(storage_path, hysteresis_results)
end

#utility function, splits an array into n chunks
chunk(arr, n) = [arr[i:min(i + n - 1, end)] for i in 1:n:length(arr)]
