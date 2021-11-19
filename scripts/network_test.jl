using DrWatson
@quickactivate "Social Agent Based Modelling"
using Agents, Random, Graphs, GraphIO
using GraphPlot
using CSV

include(srcdir("agentFunctions.jl"))
include(srcdir("modelling.jl"))

seed = 1234

"remove isolated nodes"
function strip_isolates!(g)
    isolates=reverse(findall(x->x==0, Graphs.outdegree(g)))
    for i in isolates
        rem_vertex!(g,i)
    end
    return g
end

watts_networks = watts_strogatz(1000,10,0.8)

#TODO: calibrate barabasi albert space creation
bara_albert = barabasi_albert(1000,5,5,seed=1234)
strip_isolates!(bara_albert)
test_space = Agents.GraphSpace(bara_albert)


#demonstrating export using GraphIO
savegraph(open(datadir("test.net");write=true),bara_albert,"test",NETFormat())

testModel = model_decision_agents_SIR(mixed_population;space=test_space,seed = seed,tauRational=1,tauSocial=1, switchingLimit=2,detectionTime = 7,
	initialInfected = 0.005,
	deathRate = 0.03,
	reinfectionProtection = 180,
	infectionPeriod=30,
	transmissionUndetected = 1.1,
	transmissionDetected = 0.05,
	detectionProbability = 0.03) #according to Gutenberg study of U Mainz, 42.4% undetected overall ==> since multiple days of possible detection, lower individual detection probability.
	#  0.963^23 approx 0.42
	#TODO calibrate parameters properly


test_agent_df, model_df = run!(testModel, agent_step_SIR_latent!,model_step!, 1; adata = [:affinity,:SIR_status],parallel=true)
CSV.write(datadir("test_network_data.csv"),test_agent_df)

#write degree into seperate dataframe to avoid repeating data for each timestep
CSV.write(datadir("degree_distribution.csv"),DataFrame(pos=range(1,testModel.agents.count,step=1),degree=degree(testModel.space.graph)))
