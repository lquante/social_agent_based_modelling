using DrWatson
using Printf
@quickactivate "Social Agent Based Modelling"

using Agents
using Random
using Graphs
using CSV
using Base
using DelimitedFiles
using DataFrames

include(srcdir("agentFunctions.jl"))
include(srcdir("modelling.jl"))

mdata = [:seed,:tauSocial]
adata = [:affinity, :avantgarde,:affinityGoal]

steps = 501
    
function ApplyShock(model, n_agents)
    # get n_agents
    ids = shuffle!(model.rng, collect(keys(model.agents)))
    i = 0
    while i < n_agents
        i += 1
        rn = rand(model.rng, Uniform(0, 1))
        model[ids[i]].affinityGoal = rn
    end
end    

function ApplyLocalShock(model, n_agents)
    center_agent = random_agent(model) 

    # get radius
    r = 1
    while (2*r+1) * (2*r+1) < 2 * n_agents
        r += 1
    end

    # get nearby agent ids
    ids = shuffle!(model.rng, collect(keys(collect(nearby_agents(center_agent.pos, model, r)))))
    i = 0
    while i < n_agents
        i += 1
        model[ids[i]].affinityGoal = 1.0 #rand(model.rng, Uniform(0, 1))
    end
end

# get arguments
#p = parse(Int, ARGS[2])
seed = parse(Int, ARGS[1])
    
model = initialize(seed=seed)

#agent_df, model_df = run!(model, agent_step!, model_step!, steps; adata=adata, when=shouldSaveData)
#
#stringkey = "data_uni"
#
#filename = "agent_" * stringkey * ".csv" 
#CSV.write(datadir("tmp", filename), agent_df)

# clear file
fname = @sprintf "data_A_seed%d.csv" seed
path = datadir("uniform", fname)
open(path, "w") do f
    write(f, "")
end

file = open(path, "a")

s = 0
while s < steps
    global s
    #global p
    
    if s < 200 || s % 10 == 0
        # save to file
        df = init_agent_dataframe(model, adata)
        collect_agent_data!(df, model, adata, s)

        data = convert(Array, df[:, :affinity])
        data_t = reshape(data, (1, size(data, 1)))
        writedlm(file, data_t, " ")
    end

    #if s == 399
    #    ApplyShock(model, p)
    #end
    
    step!(model, agent_step!, model_step!, 1)
    global s += 1
end    

close(file)


