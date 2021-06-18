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

#list of random seeds as used in starting_ensemble_generation
Random.seed!(1234)
seeds = rand(1234:9999,100)

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

#very tightly bound conversion checker, might miss oscillating stability
function check_conversion2(state_vec)
        diff_vec=diff(state_vec)
        if sum(diff_vec)==0
                return true
        else
                return false
        end
end

#conversion checker which can account for oscillating behaviour up to a period, pmax. setting pmax=1 gives same as above
function check_conversion_osc(state_vec,pmax=2)
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

#models with starting configuration generated from a certain proportion of combustion vehicles
p_combustion=0.5

#set price of combustion car for rational incentive
priceCombustion=4980

#data frame for results
ensemble_results = DataFrame(Seed = seeds, P_Combustion = p_combustion, priceCombustion=priceCombustion, Initial_State_Average = -9999.0, InititalAffinity_Average=-9999.0, Final_State_Average = -9999.0 , Final_Affinity_Average = -9999.0)

for i = 1:100
        #load models as stored after running starting_ensemble_generation.jl
        model = deserialize(string("/Users/maximiliankotz/iCloud Drive (Archive)/Documents/PIK/DeMo/ensemble_start/p_combustion=",p_combustion,"seed=",seeds[i],".bin"))

        model.priceCombustionCar=priceCombustion
        while converged == false
                agent_df, model_df = run!(model, agent_step!,model_step!, step_length; adata = [(:state, mean),(:affinity,mean)])
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
        storage_path=string("/Users/maximiliankotz/iCloud Drive (Archive)/Documents/PIK/DeMo/ensemble_finish/p_combustion=",p_combustion,"seed=",seeds[i],"priceComust",priceCombustion,".bin")
        serialize(storage_path, mixedHugeGaia)
end

#store ensemble meta data dataframe
CSV.write(string("/Users/maximiliankotz/iCloud Drive (Archive)/Documents/PIK/DeMo/ensemble_finish/Ensemble_overview_p_combustion=",p_combustion,".csv"), ensemble_results)
