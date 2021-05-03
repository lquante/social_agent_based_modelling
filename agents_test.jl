using Agents
using Statistics
using InteractiveDynamics
using GLMakie


sqrt_population = 20
space = Agents.GridSpace((sqrt_population,sqrt_population);periodic=false, metric = :euclidean)

@agent IouAgent GridAgent{2} begin
    inertia::Float64 #inertia to keep own opinion
    old_mood::Float64
    new_mood::Float64
    previous_mood::Float64
    old_utility::Float64
    new_utility::Float64
    previous_utility::Float64
    old_opinion::Bool # yes or no opinion
    new_opinion::Bool
    previous_opinion::Bool
end

function iou_model(space;numagents=sqrt_population*sqrt_population,opinion_range=5,inertia=0.5,initial_utility=0.0,utility_growth=0.0)
    local model = ABM(IouAgent,space,scheduler=Agents.fastest,properties = Dict(:opinion_range => opinion_range,:inertia => inertia,:utility_growth => utility_growth))
    for i in 1:numagents
        mood = rand(model.rng)
        initial_opinion = rand(model.rng)<mood
        add_agent_single!(model,inertia,mood,mood,mood,
        initial_utility,initial_utility,initial_utility
        ,initial_opinion,initial_opinion,initial_opinion)
    end
    return model
end



function agent_step!(agent,model)
    agent.previous_mood = agent.old_mood
    agent.previous_opinion = agent.old_opinion
    agent.previous_utility = agent.old_utility

    agent.inertia = model.inertia
    neighborsOpinion = 0.0
    neighborCount = 0
    for neighbor in nearby_agents(agent, model,model.opinion_range)
        neighborsOpinion += neighbor.previous_opinion
        neighborCount+=1
    end
    utility_mood = min(1,agent.previous_mood + agent.previous_utility)
    if neighborCount>0
        neighborsOpinion /= neighborCount
        agent.new_mood = (1-agent.inertia)*neighborsOpinion+agent.inertia*utility_mood
    else
        agent.new_mood = utility_mood
    end

    agent.new_opinion = rand(model.rng)<agent.new_mood
    agent.new_utility = min(1,max(-1,agent.previous_utility+rand(model.rng)*model.utility_growth))
end

function model_step!(model)
    for a in allagents(model)
        a.old_mood = a.new_mood
        a.old_opinion = a.new_opinion
        a.old_utility = a.new_utility
    end
end

test_model = iou_model(space,opinion_range=5)


Agents.step!(test_model,agent_step!,model_step!,1)


parange = Dict(:opinion_range => 0:20,:inertia => range(0,1;step=0.05),:utility_growth=>range(-0.5,0.5;step=0.05))

adata = [(:new_opinion, mean), (:new_mood, mean), (:new_utility, mean)]
alabels = ["agreeing", "avg. mood", "avg. utility"]

opinioncolor(a) = a.new_opinion == 1 ? :blue : :orange
opinionmarker(a) = a.new_opinion == 1 ? :circle : :rect

scene, adf, modeldf = abm_data_exploration(test_model, agent_step!, model_step!, parange;
                ac = opinioncolor, am = opinionmarker,as = 4, adata = adata, alabels = alabels)
