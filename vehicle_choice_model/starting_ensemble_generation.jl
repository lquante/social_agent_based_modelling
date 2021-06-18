# example script to show basic model setup
include("agentFunctions.jl")
include("modelling.jl")
include("populationCreation.jl")
include("visualization.jl")
using Random
using Serialization
using DataFrames,DataFramesMeta
using CSV
using Glob
using Plots
#generate 100 random seeds
Random.seed!(1234)
seeds = rand(1234:9999,100)

#set combustion share
p_combustion=0.9
step_length=50
gridsize = 30

#determine whether or not the grid already converged
#principle: Compute the difference in average affinity between one step and the next
# if all of these differences are smaller than 0.01 we say the grid has converged
function check_conversion(state_vec)
        diff_vec = diff(state_vec)
        if (sum(diff_vec.>=-0.01)==length(diff_vec))&&(sum(diff_vec.<=0.01) == length(diff_vec))
                return true
        else
                return false
        end
end
#initialize dataframe for storage of results
ensemble_results = DataFrame(Seed = seeds, P_Combustion = p_combustion, Final_State_Average = -9999.0 , Final_Affinity_Average = -9999.0)

#generate models
#default is tau_social = 3, tau_rational = 6
for i = 1:100
        space = Agents.GridSpace((gridsize, gridsize); periodic = true, metric = :euclidean)
        mixedHugeGaia = model_car_owners(mixed_population;kwargsPlacement=(combustionShare=p_combustion,),seed = seeds[i],space=space,tauSocial=3,tauRational=6,fuelCostKM=0,powerCostKM=0,priceCombustionCar=5000,priceElectricCar=5000)
        converged = false
        #always do 50 steps, then check for conversion -> step length can be adjusted on top
        while converged == false
                agent_df, model_df = run!(mixedHugeGaia, agent_step!,model_step!, step_length; adata = [(:state, mean),(:affinity,mean)])
                converged= check_conversion(agent_df[end-step_length:end,"mean_affinity"])
        end
        #get the average state in the last step
        final_status_average = agent_df[end,"mean_state"]
        #get the average affinity in the last step
        final_affinity_average = agent_df[end,"mean_affinity"]

        #add final values to dataframe
        ensemble_results[ensemble_results.Seed .== seeds[i],:Final_State_Average].=final_status_average
        ensemble_results[ensemble_results.Seed .== seeds[i],:Final_Affinity_Average].=final_affinity_average
        #store model
        storage_path=string("C:\\Users\\stecheme\\Documents\\Social_Modelling\\ensemble_start\\p_combustion=",p_combustion,"seed=",seeds[i],".bin")
        serialize(storage_path, mixedHugeGaia)
end

#store ensemble meta data dataframe
CSV.write(string("C:\\Users\\stecheme\\Documents\\Social_Modelling\\ensemble_start\\Ensemble_overview_p_combustion=",p_combustion,".csv"), ensemble_results)

#note!!
#to load model again as a model use
#model = deserialize("C:\\Users\\stecheme\\Documents\\Social_Modelling\\ensemble_start\\model.bin")

## read all the different ensemble_result dataframes:
files=glob("*.csv", "C:\\Users\\stecheme\\Documents\\Social_Modelling\\ensemble_start\\")
ensemble_data_list = DataFrame.( CSV.File.( files ) )
ensemble_data = reduce(vcat, dfs)

Plots.scatter(ensemble_data.P_Combustion,ensemble_data.Final_State_Average,marker_z = ensemble_data.P_Combustion, xlabel = "p_CombustionShare",ylabel="Final State Average")
png("C:\\Users\\stecheme\\Documents\\Social_Modelling\\ensemble_start\\final_state.png")

Plots.scatter(ensemble_data.P_Combustion,ensemble_data.Final_Affinity_Average,marker_z = ensemble_data.P_Combustion, xlabel = "p_CombustionShare",ylabel="Final State Average")
png("C:\\Users\\stecheme\\Documents\\Social_Modelling\\ensemble_start\\final_affinity.png")
