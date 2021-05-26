using Agents
using Statistics
using InteractiveDynamics
using GLMakie

parange = Dict(
    :priceCombustionCar => 5000:100000,
    :priceElectricCar => 5000:100000,
    :fuelCostKM => range(0.05, 0.5; step = 0.025),
    :powerCostKM => range(0.05, 0.5; step = 0.025),
)

adata = [(:state, mean),(:rationalOptimum, mean), (:carAge, mean),(:affinity, mean)]
alabels = ["avg. car", "avg. rational car", "avg. car age","avg. affinity"]

carcolor(a) = a.state == 0 ? :orange : :blue
carmarker(a) = a.state == 0 ? :circle : :rect

"creates an interactive simulation to explore parameter settings"
function interactive_simulation(model,agent_step!,model_step!)

    scene, adf, modeldf = abm_data_exploration(
        model,
        agent_step!,
        model_step!,
        parange;
        ac = carcolor,
        am = carmarker,
        as = 4,
        adata = adata,
        alabels = alabels,
    )

end
