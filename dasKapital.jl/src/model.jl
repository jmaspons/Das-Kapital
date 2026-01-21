using Agents
using DataFrames
using Graphs
using Random

include("worker.jl")
include("capital.jl")
include("capital_formulas.jl")


## DEFAULT PARAMETERS
######################
# https://juliadynamics.github.io/Agents.jl/stable/performance_tips/#Use-Type-stable-containers-for-the-model-properties

@kwdef mutable struct World
    natural_resources::Vector{Float64}
    n_workplaces::Vector{UInt}
    n_workers::Vector{UInt}

    function World(n = 25)
        natural_resources = Vector{Float64}(undef, n)
        n_workplaces = Vector{UInt}(undef, n)
        n_workers = Vector{UInt}(undef, n)
        new(natural_resources, n_workplaces, n_workers)
    end
end
World() = World(25)

@kwdef mutable struct ModelParameters # TODO: const non tunnable parameters
    life_cost::Float64 = 1
    max_age::UInt = 65
    min_working_age::UInt = 6
    min_reproductive_age::UInt = 18
    max_reproductive_age::UInt = 65
    workers_t0::UInt = 5
    wage::Float64 = 2.5 #1.8
    autonomous_working_hours::Float64 = 10
    commodities_demand::Float64 = 2000000
    avg_profit_rate::Float64 = 0
    tech_cost_base::Int = 5
    tech_productivity_increase::Float64 = 2.0
    world::World = World(0)

    function ModelParameters(world_size = 10)
        world = World(world_size)
        new(1, 65, 6, 18, 65, 5, 2.5, 10, 2000000, 0, 5, 2, world)
    end
end
ModelParameters() = ModelParameters(10)


# Funció per inicialitzar el model
function initialize_model(world_graph::Graphs.AbstractGraph = Graphs.complete_graph(10); num_workers=5, num_capitalists=1)
    space = GraphSpace(world_graph)

    properties = ModelParameters(nv(world_graph))
    fill!(properties.world.natural_resources, 100)
    fill!(properties.world.n_workplaces, 20) # for communal lands
    fill!(properties.world.n_workers, 0)

    # Definim les funcions de pas dels agents i del model
    model = StandardABM(
        Union{Worker, Capital}, space;
        properties=properties, model_step! = model_step!
    )

    # Add workers
    for _ in 1:(num_workers * npositions(model))
        age = rand(abmrng(model), 1:50)
        wealth = 1 + rand(1:5)
        if age < properties.min_working_age
            status = Child
            wealth += properties.min_working_age - age
        else
            status = Autonomous
        end
        add_agent!(Worker, model, age=age, wealth=wealth, status=status)
    end

    # Add Capital to first row only
    for i in 1:Int(round(sqrt(nv(model)))) # TODO: leave empty spaces for communal land
        for _ in 1:num_capitalists
            add_agent!(i, Capital, model, wealth=1 + rand(abmrng(model), 1:500))
        end
    end

    return model
end

function initialize_model(world_size::Integer = 10; num_workers = 5, num_capitalists = 1)
    return initialize_model(Graphs.complete_graph(world_size); num_workers = num_workers, num_capitalists = num_capitalists)
end


"""
    schedule_work(model::StandardABM)

Returns a scheduler that updates Capital agents first, then Worker agents sorted by status: Employed, Autonomous, Unemployed.
"""
function schedule_work(model::StandardABM)
    st = Schedulers.ByType((Capital, Worker),  false)
    s_by_type = st(model)

    # sort Workers by status and remove Child
    status = [Agents.get_data(model[id], :status) for id in s_by_type.it.iter[2]]
    want_job = findall(x -> x in [Employed, Unemployed, Autonomous], status)
    s_by_type.it.iter[2] = s_by_type.it.iter[2][want_job]
    if (length(want_job) > 0)
        status = status[want_job]

        # sort by status 
        order = [Employed, Autonomous, Unemployed]
        order_dict = Dict(value => index for (index, value) in enumerate(order))
        function compare_enum(a, b)
            return order_dict[a] < order_dict[b]
        end
        sort_workers = sortperm(status, by = x -> order_dict[x])

        s_by_type.it.iter[2] = s_by_type.it.iter[2][sort_workers]
    end

    return s_by_type
end


"""
    schedule_sell(model::StandardABM)

Returns a scheduler that updates Capital agents sorted by unitary production cost (lowest first).
"""
function schedule_sell(model::StandardABM)
    capital_ids = filter(i -> model[i] isa Capital && model[i].commodities > 0, allids(model))
    capital_ids = convert.(Int, capital_ids)
    prod_cost = [model[i].unitary_production_cost for i in capital_ids]
    capital_ids = capital_ids[sortperm(prod_cost)]
    
    return Iterators.Stateful(capital_ids)
end

# Funció per actualitzar els agents (treballadors i capitalistes)
# function agent_step!(agent::Worker, model)
#     # Els treballadors produeixen riquesa
#     worker_live(agent)
#     worker_work(agent)
# end


# Funcions per actualitzar el model en cada pas
function model_step!(model::StandardABM)
    # https://juliadynamics.github.io/Agents.jl/stable/api/#Schedulers
    # https://juliadynamics.github.io/Agents.jl/stable/api/#Advanced-scheduling
    # https://juliadynamics.github.io/Agents.jl/stable/api/#Discrete-time-models

    # Reset capitals and assign worker's status

    fill!(model.world.n_workers, 0)

    sch_work = schedule_work(model)
    for id in sch_work
        a = model[id]
        if a isa Worker
            worker_work!(a, model)
        elseif a isa Capital
            capital_plan!(a, model)
        end
    end


    # Produce commodities and live
    
    for a in allagents(model)
        if a isa Worker
            worker_live!(a, model)
        elseif a isa Capital && a.wealth > 0
            capital_produce!(a)
        end
    end


    # Sell commodities

    commodities_pending_demand::Float64 = model.commodities_demand
    total_commodities::Float64 = 0
    total_commodities_cost::Float64 = 0
    for a in allagents(model)
        if a isa Capital && a.commodities > 0
            total_commodities += a.commodities
            total_commodities_cost += a.commodities * a.unitary_production_cost
        end
    end

    if total_commodities > 0
        exchange_value::Float64 = 2 * total_commodities_cost / total_commodities

        sch_sell = schedule_sell(model)
        for id in sch_sell
            a = model[id]
            capital_sell!(a, exchange_value, commodities_pending_demand)
        end


        # Develop means of production

        capital_dev = filter(
            i -> model[i] isa Capital &&
            model[i].wealth > 0,
            allids(model)
        )
        for i in capital_dev
            new_pos = no_capital_nearby(model[i], model)
            if !isnothing(new_pos)
                capital_develop_means_of_production!(model[i], model, exchange_value, new_pos)
            end
            
        end
    end


    # Workers reproduce

    workers_repr = filter(
        i -> model[i] isa Worker &&
          model[i].age > model.min_reproductive_age &&
          model[i].age < model.max_reproductive_age &&
          model[i].wealth > (model.min_working_age - 2) * model.life_cost + rand() * 4,
        allids(model)
    )
    for id in workers_repr
        worker_reproduce!(model[id], model)
    end


    # Agregate data at model level

    model.avg_profit_rate = mean(a.profit_rate for a in allagents(model) if a isa Capital && a.wealth > 0)
    # total_surplus = sum(a.surplus for a in allagents(model) if a isa Capital)
    # total_variable_capital = sum(a.variable_capital for a in allagents(model) if
    #     a isa Capital && a.variable_capital > 0
    # )
    # if total_variable_capital > 0
    #     model.avg_profit_rate = mean(
    #         a.profit_rate for a in allagents(model) if a isa Capital && a.variable_capital > 0
    #     )
    # else
    #     model.profit_rate = 0
    # end


    # # Redistribució de la riquesa (simplificada)
    # total_wealth = sum(a.wealth for a in allagents(model))
    # mean_wealth = total_wealth / nagents(model)
    # redistribution_pool = 0.0

    # for agent in allagents(model)
    #     if agent.wealth < mean_wealth * 0.2
    #         redistribution_amount = (mean_wealth - agent.wealth) * 0.1
    #         agent.wealth += redistribution_amount
    #         redistribution_pool -= redistribution_amount
    #     elseif agent.wealth > mean_wealth * 100
    #         redistribution_amount = (agent.wealth - mean_wealth) * 0.1
    #         agent.wealth -= redistribution_amount
    #         redistribution_pool += redistribution_amount
    #     end
    # end

    # # Redistribuir la riquesa acumulada en el pool
    # for agent in allagents(model)
    #     if redistribution_pool > 0 && agent.wealth < mean_wealth * 0.2
    #         redistribution_amount = min(redistribution_pool, (mean_wealth - agent.wealth) * 0.1)
    #         agent.wealth += redistribution_amount
    #         redistribution_pool -= redistribution_amount
    #     end
    # end
end


function no_capital_nearby(a, model)
    for pos in nearby_positions(a, model)
        if !any(id -> model[id] isa Capital, agents_in_position(pos, model).iter)
            return pos
        end
    end

    return nothing
end
