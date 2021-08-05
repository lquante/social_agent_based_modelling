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
function find_state_clusters(stateMatrix;invert=false,connectedEdges=true)
    if invert
        stateMatrix = Matrix{Int64}(stateMatrix.==0)
    end
    labels = label_components(stateMatrix)
    if connectedEdges
        labels = label_connected_edges!(labels)
    end
    groups = collect_groups(labels)
    return labels, groups
end


"correct labelling for connected edges"
function label_connected_edges!(labelMatrix)
    numColumns = size(labelMatrix)[2]
    numRows = size(labelMatrix)[1]
    labelMatrix = equalize_edge_elementwise!(labelMatrix[:,1],labelMatrix[:,numColumns],labelMatrix)
    labelMatrix = equalize_edge_elementwise!(labelMatrix[1,:],labelMatrix[numRows,:],labelMatrix)
    labelMatrix = equalize_edge_elementwise!(labelMatrix[:,numColumns],labelMatrix[:,1],labelMatrix)
    labelMatrix = equalize_edge_elementwise!(labelMatrix[numRows,:],labelMatrix[1,:],labelMatrix)
    return labelMatrix
end

function equalize_edge_elementwise!(edge1,edge2,labelMatrix)
    print(size(edge1))
    for i in 1:size(edge1)[1]
        if (edge1[i]!=0 && edge2[i]!=0)
            labelMatrix[labelMatrix.==maximum((edge1[i],edge2[i]))].=minimum((edge1[i],edge2[i]))
        end
    end
    uniques = sort(unique(labelMatrix))
    previous_unique=0
    for i_unique in uniques
        if (i_unique==0)
            nothing
        end
        if (i_unique>previous_unique+1)
            labelMatrix[labelMatrix.>=i_unique].-=1
            uniques[uniques.>i_unique].-=1
        end
        previous_unique+=1
    end
    return labelMatrix
end

"returns vector of cluster sizes"
function cluster_sizes(groups)
    return length.(groups)
end
