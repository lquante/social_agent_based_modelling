using DrWatson
@quickactivate "Social Agent Based Modelling"
include(srcdir("agentFunctions.jl"))
include(srcdir("modelling.jl"))
include(srcdir("populationCreation.jl"))
include(srcdir("hysteresisFunctions.jl"))

#set price for incentive
incentive_variable = :priceCombustionCar
incentive = 5050
#data frame for results

all_model_files = get_model_files("C:/Users/stecheme/Documents/Social_Modelling/ensemble_granular_oscillation_convergence_normal_dist_3/")

perform_incentive_hysteresis(all_model_files,incentive_variable,incentive,"C:/Users/stecheme/Documents/Social_Modelling/ensemble_granular_oscillation_convergence_normal_dist_3/")

Plots.scatter(hysteresis_results.Start_State_Average,hysteresis_results.Final_State_Average, xlabel = "Starting_State",ylabel="Final State")
png("C:\\Users\\stecheme\\Documents\\Social_Modelling\\ensemble_granular_oscillation_convergence_normal_dist_3\\hysteresis_final_state_priceCombustionCar_5050.png")
