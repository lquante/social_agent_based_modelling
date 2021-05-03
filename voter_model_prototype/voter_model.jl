using Random
using Plots
using Colors
# very simple voter model
mutable struct Voter
    opinion::Bool
    mood::Float32
    inertia::Float32
end

function initalize_voter_network(voter_network, initial_mood, mean_inertia)
    for index = 1:length(voter_network)
        inertia = mean_inertia
        voter_network[index] = Voter(Bool(rand() < initial_mood[index]), initial_mood[index], inertia)
    end
    return voter_network
end

function iterate_voter_network(voter_network)
    pre_opinion_grid = get_opinion_grid(voter_network)
    for index = 1:length(voter_network)
        mood = get_local_mood(index, voter_network,pre_opinion_grid)
        voter_network[index] = Voter(Bool(rand() < mood), mood, voter_network[index].inertia)
    end
    return voter_network
end

function get_local_mood(voter_index, voter_network, opinion_grid)
    n_voters = length(voter_network)
    neighbours =
        max(1,Integer(voter_index - 0.05 * n_voters)):min(n_voters, Integer(voter_index + 0.05 * n_voters))
    local_opinion = 0.0
    for i_neighbour in neighbours
        local_opinion += opinion_grid[i_neighbour]
    end
    local_opinion /= length(neighbours)
    return (voter_network[voter_index].mood * (voter_network[voter_index].inertia)
    +local_opinion * (1-voter_network[voter_index].inertia))
end

function get_average_opinion(voter_network)
    opinion = 0.0
    for i_voter in voter_network
        opinion += i_voter.opinion
    end
    return opinion / length(voter_network)
end

function get_opinion_grid(voter_network)
    grid = fill(0.0, size(voter_network))
    for i_gridpoint = 1:length(grid)
        grid[i_gridpoint] = voter_network[i_gridpoint].opinion
    end
    return grid
end

function get_mood_grid(voter_network)
    grid = fill(0.0, size(voter_network))
    for i_gridpoint = 1:length(grid)
        grid[i_gridpoint] = voter_network[i_gridpoint].mood
    end
    return grid
end

function get_inertia_grid(voter_network)
    grid = fill(0.0, size(voter_network))
    for i_gridpoint = 1:length(grid)
        grid[i_gridpoint] = voter_network[i_gridpoint].inertia
    end
    return grid
end

function heatmap_from_grid(grid;args ...)
    heatmap(grid,aspect_ratio=1,
    fill_z=grid,showaxis=false,ticks=false,grid=false,clims=(0,1);args ...)
end

function replace_heatmap_from_grid(plotting_position,grid;args ...)
    heatmap!(plotting_position,
    grid,showaxis=false,xticks=false,yticks=false,grid=false,clims=(0,1);args ...)
end

voter_network = fill(Voter(0, 0, 0), (20, 20))
timeperiods = 1:100
Random.seed!(1234)

initial_mood = rand(Float16,size(voter_network))
print(initial_mood)
mean_inertia = 1
voter_network = initalize_voter_network(voter_network, initial_mood, mean_inertia)

public_opinion = zeros(length(timeperiods))
l = (1,2)
mood_hm = heatmap_from_grid(get_mood_grid(voter_network),legend=true,size=(500,500),title="voter mood")
opinion_hm = heatmap_from_grid(get_opinion_grid(voter_network),title="voter opinion",legend=false,size=(500,500))
p = plot(mood_hm,opinion_hm,layout = l,size=(1000,500))

anim = @animate for i_time in timeperiods
    public_opinion[i_time]= get_average_opinion(voter_network)
    replace_heatmap_from_grid(p[1],get_mood_grid(voter_network))
    replace_heatmap_from_grid(p[2],get_opinion_grid(voter_network))
    global voter_network = iterate_voter_network(voter_network)
end

gif(anim, "test_voter_opinion_random_initial_mood_100percent_inertia.gif", fps = 1)

plot(public_opinion, xlabel = "time", ylabel = "average opinion",legend=false)
