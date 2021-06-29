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
using Distributions
#generate 100 random seeds
Random.seed!(1234)
seeds = rand(1234:9999,100)

#set combustion share
#sample p_combustion from uniform distribution
#p_combustion_range=range(0, 1, length=50)
#sample p_combustion from normal distribution
p_normal_dist = truncated(Normal(0.5, 0.05), 0.3, 0.6)
p_combustion_range = rand(p_normal_dist, 100)

#plot the distribution of the ps
Plots.histogram(p_combustion_range,xlabel="p_CombustionShare",ylabel="Count" )
png("C:\\Users\\stecheme\\Documents\\Social_Modelling\\ensemble_granular_oscillation_convergence_normal_dist_3\\histogram_p_combustion.png")


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

function check_conversion2(state_vec)
        diff_vec=diff(state_vec)
        if sum(diff_vec)==0
                return true
        else
                return false
        end
end

#conversion checker which can account for oscillating behaviour up to a period, pmax. setting pmax=1 gives same as above
function check_conversion_osc(state_vec,pmax=5)
        conv=false
        p=1
        while (conv==false) && (p<=pmax)
                diff_vec=diff(state_vec[1:p:end])
                if sum(diff_vec)==0
                        conv=true
                end
                p+=1
        end
        if conv==true
                return true
        else
                return false
        end
end

#initialize dataframe for storage of results

#generate models
#default is tau_social = 3, tau_rational = 6
for p_combustion in p_combustion_range
        print(p_combustion)
        ensemble_results = DataFrame(Seed = seeds, P_Combustion = p_combustion, Final_State_Average = -9999.0 , Final_Affinity_Average = -9999.0)
        for i = 1:100
                space = Agents.GridSpace((gridsize, gridsize); periodic = true, metric = :euclidean)
                mixedHugeGaia = model_car_owners(mixed_population;kwargsPlacement=(combustionShare=p_combustion,),seed = seeds[i],space=space,tauSocial=3,tauRational=6,fuelCostKM=0,powerCostKM=0,priceCombustionCar=5000,priceElectricCar=5000)
                converged = false
                #always do 50 steps, then check for conversion -> step length can be adjusted on top
                while converged == false
                        agent_df, model_df = run!(mixedHugeGaia, agent_step!,model_step!, step_length; adata = [(:state, mean),(:affinity,mean)])
                        converged= check_conversion_osc(agent_df[end-step_length:end,"mean_affinity"])
                end
                #get the average state in the last step
                final_status_average = agent_df[end,"mean_state"]
                #get the average affinity in the last step
                final_affinity_average = agent_df[end,"mean_affinity"]

                #add final values to dataframe
                ensemble_results[ensemble_results.Seed .== seeds[i],:Final_State_Average].=final_status_average
                ensemble_results[ensemble_results.Seed .== seeds[i],:Final_Affinity_Average].=final_affinity_average
                #store model
                storage_path=string("C:\\Users\\stecheme\\Documents\\Social_Modelling\\ensemble_granular_oscillation_convergence_normal_dist_2\\p_combustion=",p_combustion,"seed=",seeds[i],".bin")
                serialize(storage_path, mixedHugeGaia)
        end
        #store ensemble meta data dataframe
        CSV.write(string("C:\\Users\\stecheme\\Documents\\Social_Modelling\\ensemble_granular_oscillation_convergence_normal_dist_2\\Ensemble_overview_p_combustion=",p_combustion,".csv"), ensemble_results)
end
#note!!
#to load model again as a model use
#model = deserialize("C:\\Users\\stecheme\\Documents\\Social_Modelling\\ensemble_start\\model.bin")

## read all the different ensemble_result dataframes:
files=glob("*.csv", "C:\\Users\\stecheme\\Documents\\Social_Modelling\\ensemble_granular_oscillation_convergence_normal_dist_2\\")
ensemble_data_list = DataFrame.( CSV.File.( files ) )
ensemble_data = reduce(vcat, ensemble_data_list)

Plots.scatter(ensemble_data.P_Combustion,ensemble_data.Final_State_Average,marker_z = ensemble_data.P_Combustion, xlabel = "p_CombustionShare",ylabel="Final State Average")
png("C:\\Users\\stecheme\\Documents\\Social_Modelling\\ensemble_granular_oscillation_convergence_normal_dist_2\\final_state.png")

Plots.scatter(ensemble_data.P_Combustion,ensemble_data.Final_Affinity_Average,marker_z = ensemble_data.P_Combustion, xlabel = "p_CombustionShare",ylabel="Final Affinity Average")
png("C:\\Users\\stecheme\\Documents\\Social_Modelling\\ensemble_granular_oscillation_convergence_normal_dist_2\\final_affinity.png")

Plots.histogram(ensemble_data.P_Combustion,ensemble_data.Final_Affinity_Average,xlabel="p_CombustionShare",ylabel="Final Affinity Average" )
png("C:\\Users\\stecheme\\Documents\\Social_Modelling\\ensemble_granular_oscillation_convergence_normal_dist_2\\histogram_final_affinity.png")

Plots.histogram(ensemble_data.P_Combustion,ensemble_data.Final_State_Average,xlabel="p_CombustionShare",ylabel="Final State Average" )
png("C:\\Users\\stecheme\\Documents\\Social_Modelling\\ensemble_granular_oscillation_convergence_normal_dist_2\\histogram_final_state.png")
