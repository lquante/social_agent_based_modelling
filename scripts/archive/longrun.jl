using DrWatson
using Printf
@quickactivate "Social Agent Based Modelling"

using Distributed
using Agents
using Random
using Graphs
using CSV
using Statistics
using DelimitedFiles

# path = $path    

include(srcdir("agentFunctions.jl"))
include(srcdir("modelling.jl"))
    
function calc_global_affinity_change(agents, previous_affinities)
    affinity_change = [abs(a.affinity - previous_affinities[i]) for (i, a) in enumerate(agents)]
    global_affinity_change = sum(affinity_change)
    std_affinity = std(affinity_change, corrected=false)
    max_affinity = maximum(affinity_change)
    min_affinity = minimum(affinity_change)
    return (global_affinity_change, std_affinity, max_affinity, min_affinity)
end

function write_global_affinity_change_to_file(agents, previous_affinities, step::Int, file::IO)
    global_affinity_change, std_affinity, maxa, mina = calc_global_affinity_change(agents, previous_affinities)
    write(file, "$step $global_affinity_change $std_affinity $maxa $mina\n")
end

function write_affinity_change_to_file(agents, previous_affinities, step::Int, file::IO)
    changes = [a.affinity - previous_affinities[i] for (i, a) in enumerate(agents)]    
    changes_r = reshape([step; changes], (1, size(changes, 1) + 1))
    writedlm(file, changes_r, ' ')
end

function write_affinities_to_file(agents, step::Int, file::IO)
    data = [a.affinity for a in agents]
    data_r = reshape([step; data], (1, size(data, 1) + 1))
    writedlm(file, data_r, ' ')
end

# initialize the model
model = initialize(seed=100)

fname = "data/tmp/affinity100.txt"
open(fname, "w") do file
    write(file, "")
end 

# Create a file to write the global absolute change of the affinity to
file = open(fname, "a")

#Define the number of steps
nsteps = 10000

# Run the model step function and save the global absolute change of the affinity to file
for step in 1:nsteps
    previous_affinities = [a.affinity for a in allagents(model)]
    step!(model, agent_step!, model_step!)

    write_global_affinity_change_to_file(allagents(model), previous_affinities, step, file)

    # write_affinity_change_to_file(allagents(model), previous_affinities, step, file)

    #if step > 7500 && step < 8000
    #    # write_affinities_to_file(allagents(model), step, file)
    #end
    
    #write_affinities_to_file(allagents(model), step, file)
end

# Close the file when you are done
close(file)

