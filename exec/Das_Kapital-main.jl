using Agents
# using CairoMakie # for abmplot
using GLMakie # for interactive plots
using DataFrames
# using Random
using Plots  # Importem la llibreria de gràfics

include("Das_Kapital-model.jl")

world_size = (5, 5)
world_size = (10, 10)


###########################
## Interactive ABM plots ##
###########################


## Color dels agents en funció del tipus
agent_color(a) = a isa Worker ? :red : :blue
agent_color(a) = a isa Capital ? :blue :
    a.status == Employed ? :red : 
    a.status == Unemployed ? :black :
    a.status == Autonomous ? :green : :yellow
agent_size(a) = a isa Worker ? 20 : 40
# agent_marker(a) = a isa Worker ? '🙂' : '🏭' # https://docs.julialang.org/en/v1/manual/unicode-input/
agent_marker(a) = a isa Worker ? '☻' : '𝓒'
offset(a) = a isa Worker ? Tuple(0.1 * randn(2)) : (0, 0)
heatarray(model) = model.world.n_workplaces

# BUG: https://github.com/JuliaDynamics/Agents.jl/issues/1035
# TODO: remove agent_size as a workaround to avoid error functions for color, maker
# plotkwargs = (;
#     agent_color, agent_size, agent_marker, offset, heatarray
# )
plotkwargs = (;
    agent_color, agent_marker, offset, heatarray
)


params = Dict(
    :wage => 1.5:0.1:3,
    :life_cost => 0.5:0.1:2,
    :min_working_age => 6:1:16,
    :commodities_demand => 100000:100000:3000000,
    :tech_cost_base => 2:1:8
)


using Statistics: mean

isaworker(a) = a isa Worker
isacapital(a) = a isa Capital
# adata = [(isaworker, count), (isacapital, count), (:wealth, mean)] # Aggregated data from agents  -> :time, data...
adata = [(isaworker, count), (isacapital, count), (:wealth, mean, isaworker), (:wealth, mean, isacapital)] # Aggregated data from agents  -> :time, data...
alabels = ["n Workers", "n Capitals", "Avg Wealth Workers", "Avg Wealth Capitals"]

profit_rate(model) = mean(model.profit_rate)
mdata = [:profit_rate]
mlabels = ["Profit rate"]

model = initialize_model(world_size)

fig, ax, abmobs = abmplot(model; plotkwargs...)
fig


## TODO: Error in callback:
# DimensionMismatch: arrays could not be broadcast to a common size: a has axes Base.OneTo(130) and b has axes Base.OneTo(162)
fig_int, ax, abmobs = abmplot(
    model; add_controls=true, plotkwargs..., params
)
fig_int


fig_int_data, ax, abmobs = abmplot(
    model; add_controls=true, plotkwargs..., params, adata, mdata
)
fig_int_data

step_abm!(abmobs)


## Interactive ABM plot with aggregated scatterplots

model = initialize_model(world_size)
fig_exp, abmobs = abmexploration(model;
    params, plotkwargs...,
    adata, alabels, mdata, mlabels
)
fig_exp


## Interactive ABM plot with custom plots

abmobs = ABMObservable(model; adata, mdata)


####################
## Run simulation ##
####################
model = initialize_model(world_size)

model.commodities_demand = 10000

adata = [:wealth]  # Data from agents -> :time, :id, data...
mdata = [:total_wealth]  # TODO: Dades del model que volem recollir
n_steps = 2500
# n_steps = 5
isaworker(a) = a isa Worker
isacapital(a) = a isa Capital
adata = [(isaworker, count), (isacapital, count), (:wealth, mean, isaworker), (:wealth, mean, isacapital)] # Aggregated data from agents  -> :time, data...
# TODO: Notice: Aggregating only works if there are agents to be aggregated over. If you remove agents during model run, you should modify the aggregating functions. E.g. instead of passing mean, pass mymean(a) = isempty(a) ? 0.0 : mean(a).

# profit_rate(model) = mean(model.profit_rate)
mdata = [:profit_rate]


# agent_data: DataFrame containing data collected from agents during the simulation (agregated or for all agents (:id))
# model_data: DataFrame containing data collected from the model during the simulation
agent_data, model_data = run!(model, n_steps; adata=adata, mdata=mdata, showprogress=true)
agent_data, model_data = run!(model, n_steps; adata=[:wealth], mdata=mdata, showprogress=true)

rename!(
    agent_data,
    :mean_wealth_isaworker => :average_wealth_workers,
    :mean_wealth_isacapital => :average_wealth_capital
)

dfa_id = init_agent_dataframe(model, [:wealth])
dfa_aggr = init_agent_dataframe(model, adata)
dfm = init_model_dataframe(model, mdata)


# Plots

Plots.plot(
    Plots.plot(
        steps, [agent_data[:, :average_wealth_workers], agent_data[:, :average_wealth_capital]],
        label=["Workers" "Capitalists"], xlabel="Time (steps)", ylabel="Average wealth",
        title="Average wealth", linecolor=[:red :blue]
    ),
    Plots.plot(
        steps, [agent_data[:, :count_isaworker], agent_data[:, :count_isacapital]],
        label=["Workers" "Capitalists"], xlabel="Time (steps)", ylabel="n agents",
        title="Population size", linecolor=[:red :blue]
    ),
    layout=(2, 1)
)

## Data plot
using Statistics: mean
# Preparem les dades per a la gràfica
steps = 0:n_steps  # Passos de la simulació

grouped_data = groupby(agent_data, [:agent_type, :time])

total_data = combine(grouped_data, :wealth => sum => :total_wealth)
wealth_class = groupby(total_data, :agent_type)

average_data = combine(grouped_data, :wealth => mean => :average_wealth)
average_wealth_class = groupby(average_data, :agent_type)

## Creem la gràfica
Plots.plot(steps, [log.(average_wealth_class[(:Worker,)][:, :average_wealth]), log.(average_wealth_class[(:Capital,)][:, :average_wealth])],
    label=["Treballadors" "Capitalistes"],
    xlabel="Temps (passos)", ylabel="log riquesa mitjana",
    title="Evolució de la riquesa mitjana",
    linecolor=[:red :blue]
)

Plots.plot(steps, [average_wealth_class[(:Worker,)][:, :average_wealth], average_wealth_class[(:Capital,)][:, :average_wealth]],
    label=["Treballadors" "Capitalistes"],
    xlabel="Temps (passos)", ylabel="Riquesa mitjana",
    title="Evolució de la riquesa mitjana",
    linecolor=[:red :blue]
)

Plots.plot(steps, [wealth_class[(:Worker,)][:, :total_wealth], wealth_class[(:Capital,)][:, :total_wealth]],
    label=["Treballadors" "Capitalistes"],
    xlabel="Temps (passos)", ylabel="Riquesa total",
    title="Evolució de la riquesa total",
    linecolor=[:red :blue]
)
Plots.plot(steps, [log.(wealth_class[(:Worker,)][:, :total_wealth]), log.(wealth_class[(:Capital,)][:, :total_wealth])],
    label=["Treballadors" "Capitalistes"],
    xlabel="Temps (passos)", ylabel="Riquesa total",
    title="Evolució del logaritme de la riquesa total",
    linecolor=[:red :blue]
)


