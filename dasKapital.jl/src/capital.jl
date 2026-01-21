using Agents
using DataFrames
# using Random


@agent struct Capital(GraphAgent)  # Heretem de GridAgent per a un espai 2D
    wealth::Float64 = 1.0 # capital inicial
    commodities::Float64 = 0
    # work_intensity::Float64
    work_productivity::Float64 = 1
    working_hours::Float64 = 12
    variable_capital::Float64 = 1
    constant_capital::Float64 = 1
    occ::Float64 = -1  # organic composition of capital
    unitary_production_cost::Float64 = NaN
    n_workers::UInt = 0
    n_workplaces::UInt = 0
    max_n_workplaces::UInt = 2
    surplus::Float64 = 0
    exploitation_rate::Float64 = 0
    profit_rate::Float64 = 0
    wage_hour::Float64 = NaN
end


#######################
## Capital functions ##
#######################

# DEBUG: a = random_agent(model, a -> a isa Capital)
function capital_plan!(a::Capital, model::StandardABM)
    a.n_workers = 0 # anually hire workers
    a.commodities = 0 # no stocks
    a.unitary_production_cost = 0
    a.wage_hour = model.life_cost * model.wage / a.working_hours
    a.n_workplaces = min(floor(a.wealth / (a.wage_hour * a.working_hours)), a.max_n_workplaces)
    a.n_workers * a.work_productivity * a.working_hours * 0.2 # TODO 0.2 # 20% as the cost of the means of production

    if a.n_workplaces < 0
        a.n_workplaces = 0
    end

    model.world.n_workplaces[a.pos] = a.n_workplaces
end


function capital_produce!(a::Capital)
    a.variable_capital = a.wage_hour * a.n_workers * a.working_hours
    a.commodities = a.n_workers * a.work_productivity * a.working_hours
    a.constant_capital = a.commodities * 0.2 # TODO 0.2 # 20% as the cost of the raw materials (circulating capital)
    production_cost = a.constant_capital + a.variable_capital

    if production_cost > a.wealth # not enough capital to produce at full capacity # TODO: loans
        occ = a.constant_capital / a.variable_capital
        a.variable_capital = a.wealth / (1 + occ)
        a.constant_capital = occ * a.variable_capital # a.wealth * occ / (occ + 1)
        
        a.n_workers = floor(Int, (a.wealth - a.constant_capital) / (a.wage_hour * a.working_hours))
        if a.n_workers < 0
            a.n_workers = 0
        end
        a.commodities = a.n_workers * a.work_productivity * a.working_hours
        a.variable_capital = a.wage_hour * a.n_workers * a.working_hours
        a.constant_capital = a.commodities * 0.2 # TODO 0.2 # 20% as the cost of the raw materials (circulating capital)
    end
    

    if a.commodities > 0
        a.unitary_production_cost = (a.variable_capital + a.constant_capital) / a.commodities
    else
        a.unitary_production_cost = Inf
    end

    a.wealth -= a.variable_capital + a.constant_capital
    if a.wealth < 0
        a.wealth = 0
    end
end


function capital_sell!(a::Capital, exchange_value, commodities_pending_demand)
    sold_commodities = min(a.commodities, commodities_pending_demand)
    a.commodities -= sold_commodities
    money = sold_commodities * exchange_value
    a.wealth += money
    commodities_pending_demand -= sold_commodities
    ## TODO: a.commodities -= sold_commodities (storage)

    a.surplus = money - a.variable_capital # TODO: Marx 1867. Capital Book 1 Part V Ch. 18 formulae I.
    a.profit_rate = a.surplus / (a.variable_capital + a.constant_capital)
    if a.variable_capital == 0
        a.exploitation_rate = 0
    else
        a.exploitation_rate = a.surplus / a.variable_capital
    end
end


function capital_develop_means_of_production!(a::Capital, model, exchange_value, new_tech_pos)
    new_tech_cost = model.tech_cost_base ^ log2(a.max_n_workplaces) # TODO graph pos
    # new_tech_pos = (a.pos[1], a.pos[2] + 1)
    # new_tech_exist = any(agent -> agent isa Capital, agents_in_position(new_tech_pos, model))
    new_capital = nothing
    if a.wealth > new_tech_cost * 2
        a.wealth -= new_tech_cost * 1 # Fix capital
        new_capital = add_agent!(
            new_tech_pos, Capital, model;
            wealth = new_tech_cost * 2,
            work_productivity = model.tech_productivity_increase * a.work_productivity,
            max_n_workplaces = model.tech_productivity_increase * a.max_n_workplaces
        )
        new_capital.occ =  a.max_n_workplaces * a.work_productivity * a.working_hours * 0.2 / # constant capital # TODO 0.2 # 20% as the cost of the raw materials (circulating capital)
             (a.wage_hour * a.n_workers * a.working_hours) # variable capital
    end

    if a.unitary_production_cost > exchange_value && !isnothing(new_capital) # non profitable mode of production
        new_capital.wealth += a.wealth # tranfer capital to new means of production
        # TODO: 
        remove_agent!(a, model)
        # a.wealth = 0
        # a.n_workers = 0
        # a.n_workplaces = 0
        # a.max_n_workplaces = 0
        # a.commodities = -1
    end
end
