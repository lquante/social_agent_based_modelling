# example script to show basic model setup
include("agentFunctions.jl")
include("modelling.jl")
include("populationCreation.jl")
include("visualization.jl")

#set a range of taus to explore
tau_social_range = 1:15
tau_rational_range = 1:15
carcolor(a) = a.state == 0 ? :orange : :blue
carmarker(a) = a.state == 0 ? :circle : :rect

for tau_social in tau_social_range
  for tau_rational in tau_rational_range
     space = Agents.GridSpace((30, 30); periodic = true, metric = :euclidean)
     mixedHugeGaia = model_car_owners(mixed_population;space=space,tauSocial=tau_social,tauRational=tau_rational,fuelCostKM=0,powerCostKM=0,priceCombustionCar=5000,priceElectricCar=5000)
     #set seed to make sure that we always
     seed!(mixedHugeGaia,18936171601132517)
     ## take 100 steps to reach stable configuration for mixed equal opportunity world
     agent_df, model_df = run!(mixedHugeGaia, agent_step!,model_step!, 100; adata = [:state_old,:state,:rationalOptimum,:carAge,:affinity])
     #look at last step that was taken
     step100=agent_df[agent_df.step .== 100,:]
     ##print how many agents changed status
     agent_change = size(step100[step100.state_old .!= step100.state,:])[1]
     print("after 100 steps")
     print(agent_change)
     print("switched their state")
     #store a snapshot
     fig,abmstepper = abm_plot(mixedHugeGaia, ac=carcolor, am=carmarker)
     Label(fig[1, 1, Top()], "Steps:100, Incentive:None", padding = (0, 0, 10, 0))
     display(fig)
     #set very small incentive towards electric cars
     mixedHugeGaia.properties[:priceCombustionCar] = 5010
     # take another 50 steps
     agent_df, model_df = run!(mixedHugeGaia, agent_step!,model_step!, 50; adata = [:state_old,:state,:rationalOptimum,:carAge,:affinity])
     ## get the average status after step 50
     step50=agent_df[agent_df.step .== 50,:]
     average_agent_status = mean(step50.state)
     agent_change = size(step50[step50.state_old .!= step50.state,:])[1]
     print("after 50 steps with small incentive the average status is")
     print(average_agent_status)
     print("Agents that changed their status:")
     print(agent_change)
  end
end


Agents.step!(abm_plot(mixedHugeGaia)[2], mixedHugeGaia, agent_step!, model_step!, 0)




space = Agents.GridSpace((30, 30); periodic = true, metric = :euclidean)
mixedHugeGaia = model_car_owners(mixed_population;space=space,tauSocial=4,tauRational=6,fuelCostKM=0,powerCostKM=0,priceCombustionCar=5000,priceElectricCar=5000)
seed!(mixedHugeGaia,18936171601132517)
interactive_simulation(mixedHugeGaia,agent_step!,model_step!)

agent_df, model_df = run!(mixedHugeGaia, agent_step!,model_step!, 300; adata = [:state_old,:state,:rationalOptimum,:carAge,:affinity]
)
