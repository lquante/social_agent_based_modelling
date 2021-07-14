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
using ProgressMeter

##function definition space
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
## load some models that have been predefined

files=glob("*.bin", "C:\\Users\\stecheme\\Documents\\Social_Modelling\\ensemble_granular_oscillation_convergence_normal_dist_3\\")

step_length=100

hysteresis_results = DataFrame(Index = 1:length(files), Start_State_Average = -9999.0, Start_Affinity_Average = -9999.0, Final_State_Average = -9999.0 , Final_Affinity_Average = -9999.0)
#findall( x -> occursin("seed=5412", x), files)
counter = 1
for f in files
    model=deserialize(f)
    #Call the model with 0 steps to get the current state and affinity. This is a bit hacky maybe there is a better way? Couldn't think of one for now
    agent_df_start, model_df_start = run!(model, agent_step!,model_step!, 0; adata = [(:state, mean),(:affinity,mean)])
    hysteresis_results[hysteresis_results.Index .== counter,:Start_State_Average].=agent_df_start[end,"mean_state"]
    hysteresis_results[hysteresis_results.Index .== counter,:Start_Affinity_Average].=agent_df_start[end,"mean_affinity"]
    #set very small incentive
    model.properties[:priceCombustionCar  ] = 5050
    #let it converge
    converged = false
    while converged == false
                    agent_df, model_df = run!(model, agent_step!,model_step!, step_length; adata = [(:state, mean),(:affinity,mean)])
                    converged= check_conversion_osc(agent_df[end-step_length:end,"mean_affinity"])
    end

    hysteresis_results[hysteresis_results.Index .== counter,:Final_State_Average].=agent_df[end,"mean_state"]
    hysteresis_results[hysteresis_results.Index .== counter,:Final_Affinity_Average].=agent_df[end,"mean_affinity"]
    #store model
    #storage_path=string("C:\\Users\\stecheme\\Documents\\Social_Modelling\\ensemble_granular_oscillation_convergence_normal_dist_3\\p_combustion=",p_combustion,"seed=",seeds[i],".bin")
    #serialize(storage_path, mixedHugeGaia)
    counter = counter +1
end
CSV.write(string("C:\\Users\\stecheme\\Documents\\Social_Modelling\\ensemble_granular_oscillation_convergence_normal_dist_3\\Hysteresis_model_set_3_priceCombustionCar_5050.csv"), hysteresis_results)

Plots.scatter(hysteresis_results.Start_State_Average,hysteresis_results.Final_State_Average, xlabel = "Starting_State",ylabel="Final State")
png("C:\\Users\\stecheme\\Documents\\Social_Modelling\\ensemble_granular_oscillation_convergence_normal_dist_3\\hysteresis_final_state_priceCombustionCar_5050.png")
