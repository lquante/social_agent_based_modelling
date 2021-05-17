using Agents
using Statistics
using InteractiveDynamics
using GLMakie

parange = Dict(
    :priceCombustionVehicle => 5000:100000,
    :priceElectricVehicle => 5000:100000,
    :fuelCostKM => range(0.05, 0.5; step = 0.025),
    :powerCostKM => range(0.05, 0.5; step = 0.025),
)

adata = [(:vehicleValue, mean), (:state, mean), (:vehicleAge, mean),(:affinity, mean)]
alabels = ["vehicleValue", "avg. vehicle", "avg. vehicle age","avg. affinity"]

vehiclecolor(a) = a.state == 0 ? :orange : :blue
vehiclemarker(a) = a.state == 0 ? :circle : :rect

"creates an interactive simulation to explore parameter settings"
function interactive_simulation(model,agent_step!,model_step!)

    scene, adf, modeldf = abm_data_exploration(
        model,
        agent_step!,
        model_step!,
        parange;
        ac = vehiclecolor,
        am = vehiclemarker,
        as = 4,
        adata = adata,
        alabels = alabels,
    )

end
