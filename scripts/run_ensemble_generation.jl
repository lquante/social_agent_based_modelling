using DrWatson
@quickactivate "Social Agent Based Modelling"
include(srcdir("agentFunctions.jl"))
include(srcdir("modelling.jl"))
include(srcdir("populationCreation.jl"))
include(srcdir("visualization.jl"))
include(srcdir("hysteresisFunctions.jl"))


Random.seed!(1234)
seeds = rand(1234:9999,100)

#set combustion share
#sample p_combustion from uniform distribution
#p_combustion_range=range(0, 1, length=50)
#sample p_combustion from normal distribution
p_normal_dist = truncated(Normal(0.5, 0.05), 0.3, 0.6)
p_combustion_range = rand(p_normal_dist, 100)

plot_combustion_share_histogram(p_combustion_range, plotsdir("histogram_p_combustion.png"))

generate_ensemble(p_combustion_range,datadir();step_length=50,gridsize = 30, models_per_p = 100,seeds = rand(1234:9999,100),store_model = false, model_directory = "")

##load results and make some plots
ensemble_data = load_results_data("C:\\Users\\stecheme\\Documents\\Social_Modelling\\ensemble_granular_oscillation_convergence_normal_dist_3\\")

plot_scatter(ensemble_data, "C:\\Users\\stecheme\\Documents\\Social_Modelling\\ensemble_granular_oscillation_convergence_normal_dist_3\\test_state.png")
plot_scatter(ensemble_data, "C:\\Users\\stecheme\\Documents\\Social_Modelling\\ensemble_granular_oscillation_convergence_normal_dist_3\\test_affinity.png"; variable = ensemble_data.Final_Affinity_Average,y_lab = "Final Affinity Average")

plot_histogram(ensemble_data, "C:\\Users\\stecheme\\Documents\\Social_Modelling\\ensemble_granular_oscillation_convergence_normal_dist_3\\test_hist_state.png")
plot_histogram(ensemble_data, "C:\\Users\\stecheme\\Documents\\Social_Modelling\\ensemble_granular_oscillation_convergence_normal_dist_3\\test_hist_affinity.png"; variable = ensemble_data.Final_Affinity_Average,y_lab = "Final Affinity Average")
