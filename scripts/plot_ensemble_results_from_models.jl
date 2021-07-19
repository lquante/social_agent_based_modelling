using Distributed
@everywhere using DrWatson
@everywhere @quickactivate "Social Agent Based Modelling"
@everywhere include(srcdir("hysteresisFunctions.jl"))
@everywhere include(srcdir("agentFunctions.jl"))
@everywhere include(srcdir("modelling.jl"))
path = ARGS[1] # get path via script argument

if (ispath(path)==false)
    warn("Please specify a valid path!")
end

model_files = get_model_files(path)

#calculate state average for each model
counter=1
hysteresis_results = DataFrame(Index = 1:length(model_files), Final_State_Average = NaN , Final_Affinity_Average = NaN,P_Combustion = NaN)
for i_model_file in model_files
    model_params = parse_savename(i_model_file)
    i_model=deserialize(i_model_file)
    agent_df_start, model_df_start = run!(i_model, agent_step!,model_step!, 0; adata = [(:state, mean),(:affinity,mean)])
    hysteresis_results[hysteresis_results.Index .== counter,:P_Combustion].=model_params[2]["p_combustion"]
    hysteresis_results[hysteresis_results.Index .== counter,:Final_State_Average].=agent_df_start[end,"mean_state"]
    hysteresis_results[hysteresis_results.Index .== counter,:Final_Affinity_Average].=agent_df_start[end,"mean_affinity"]
    global counter+=1
end
data = hysteresis_results
ensembleidentifier = ARGS[2]
plotpath = plotsdir(ensembleidentifier)
mkpath(plotpath)
plot_scatter(data,joinpath(plotpath,"scatter"))
plot_histogram(data,joinpath(plotpath,"histogram"))
