using Agents
using DataFrames
using Random


@enum HumanType Unemployed Employed Autonomous Child
@agent struct Worker(GraphAgent)  # Heretem de GridAgent per a un espai 2D
    age::UInt8
    wealth::Float64
    status::HumanType = Autonomous
    capital_id::Int = -1
end


######################
## Worker functions ##
######################

# DEBUG: a = random_agent(model, a -> a isa Worker)
function worker_live!(a::Worker, model::StandardABM)
    a.age += 1
    a.wealth -= model.life_cost

    if a.age > model.max_age || a.wealth <= 0
        remove_agent!(a, model)
    end

    if a.age == model.min_working_age
        a.status = Unemployed
    end
end


# DEBUG: a = random_agent_in_position((1, 1), model, a -> a isa Worker) # Worker with Capital
# DEBUG: a = random_agent_in_position((1, 5), model, a -> a isa Worker) # Worker without Capital
function worker_work!(a::Worker, model::StandardABM)
    a_pos = agents_in_position(a, model)
    capital_id = filter(i -> model[i] isa Capital, a_pos.iter)
    
    if length(capital_id) > 0 # wage labour
        capital_id = Int(capital_id[1]) # Cast to atomic. Only one Capital agent per position
        capital = model[capital_id]
        if capital.n_workers < capital.max_n_workplaces &&
                rand(abmrng(model)) > 0.1 # Probability of losing the job TODO: parameter
            a.status = Employed
            a.wealth += capital.wage_hour * capital.working_hours
            a.capital_id = capital_id
            capital.n_workers += 1
            model.world.n_workers[capital.pos] += 1
        else
            a.status = Unemployed
            a.capital_id = -1
        end
    else ## communal lands
        a.capital_id = -1
        # TODO: check a.pos -> in model.world in plots: x, y -> lat, lon -> row, col
        if model.world.n_workers[a.pos] < model.world.n_workplaces[a.pos]
            a.status = Autonomous
            a.wealth += model.wage * model.life_cost
            model.world.n_workers[a.pos] += 1
        else
            a.status = Unemployed
        end
    end

    if a.status == Unemployed # find job
        # pos = (1,2) # TODO: find positions with model.world.n_workplaces > model.world.n_workers
        # move_agent!(a, pos, model)
        if a in allagents(model) ## TODO: necesary? error only for abmplot(interactive=true)
            # Error in callback: Tried to remove Worker(115, (4, 1), 0x1b, 4.0, Unemployed, -1) from the space, but that agent is not on the space
            # Stacktrace:
            # [1] error(s::LazyString)
            #     @ Base ./error.jl:35
            # [2] remove_agent_from_space!
            #     @ ~/.julia/packages/Agents/5MOkt/src/spaces/grid_multi.jl:99 [inlined]
            # [3] move_agent!(agent::Worker, pos::Tuple{Int64, Int64}, model::StandardABM{GridSpace{2, false}, Union{Capital, Worker}, Dict{Int64, Union{Capital, Worker}}, Tuple{DataType, DataType}, typeof(dummystep), typeof(model_step!), typeof(Agents.Schedulers.fastest), ModelParameters, TaskLocalRNG})
            #     @ Agents ~/.julia/packages/Agents/5MOkt/src/core/space_interaction_API.jl:128
            # [4] move_agent!(agent::Worker, model::StandardABM{GridSpace{2, false}, Union{Capital, Worker}, Dict{Int64, Union{Capital, Worker}}, Tuple{DataType, DataType}, typeof(dummystep), typeof(model_step!), typeof(Agents.Schedulers.fastest), ModelParameters, TaskLocalRNG})
            #     @ Agents ~/.julia/packages/Agents/5MOkt/src/core/space_interaction_API.jl:134
            # [5] worker_work!(a::Worker)
            #     @ Main ~/Documents/sync_nc/home/revolució/El Capital/Das-Kapital/exec/Das_Kapital.jl:402
            # [6] model_step!(model::StandardABM{GridSpace{2, false}, Union{Capital, Worker}, Dict{Int64, Union{Capital, Worker}}, Tuple{DataType, DataType}, typeof(dummystep), typeof(model_step!), typeof(Agents.Schedulers.fastest), ModelParameters, TaskLocalRNG})
            #     @ Main ~/Documents/sync_nc/home/revolució/El Capital/Das-Kapital/exec/Das_Kapital.jl:173
            # ...
            move_agent!(a, model)
        end
    end
end


function worker_reproduce!(a::Worker, model::StandardABM)
    add_agent!(
        a.pos, Worker, model;
        age=0,
        wealth=model.min_working_age * model.life_cost + rand(abmrng(model)) * 3,
        status=Child, capital_id=-1
    )
    a.wealth -= model.min_working_age * model.life_cost
end
