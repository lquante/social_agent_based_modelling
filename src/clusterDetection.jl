using DrWatson
@quickactivate "Social Agent Based Modelling"
using Images


"help function to collect groups from label_components result, https://stackoverflow.com/a/32778103"
function collect_groups(labels)
    groups = [Int[] for i = 1:maximum(labels)]
    for (i,l) in enumerate(labels)
        if l != 0
            push!(groups[l], i)
        end
    end
    return groups
end

"labelling groups of connected identical state and returning a matrix of labels as well as an vector of vectors with group indizes.
N.B. to detect clusters of state 0, set invert to true"
function find_state_clusters(stateMatrix;invert=false)
    if invert
        stateMatrix = Matrix{Int64}(stateMatrix.==0)
    end
    labels = label_components(stateMatrix)
    groups = collect_groups(labels)
    return labels, groups
end

"returns vector of cluster sizes"
function cluster_sizes(groups)
    return length.(groups)
end
