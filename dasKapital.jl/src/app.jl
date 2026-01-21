# https://juliadynamics.github.io/Agents.jl/stable/examples/agents_visualizations/#GraphSpace-models

using Agents # upstream version
using GraphMakie # for graph plots
using GLMakie # for interactive plots
# using DataFrames
# using Random

include("src/DasKapital.jl")
using .DasKapital

function app(model)


g_cyle = cycle_graph(4)
g_bararasi_albert = barabasi_albert!(g_cyle, 16, 3);
graphplot(g_bararasi_albert)
world_graph = g_bararasi_albert

model = initialize_model(world_graph)

function node_color(agents_here)
    n_agents_here = length(agents_here)
    n_capital = count(a isa Capital for a in agents_here)
    n_workers = count(a isa Worker for a in agents_here)

    return RGB(n_capital / n_agents_here, n_workers / n_agents_here, 0)
end

node_size(agents_here) = length(agents_here) * 1

# BUG: https://github.com/JuliaDynamics/Agents.jl/issues/1035
# TODO: remove agent_size as a workaround to avoid errors in functions for color, maker
# plotkwargs = (;
#     agent_color, agent_size, agent_marker, offset, heatarray
# )
plotkwargs = (;
    node_color, agent_marker
)

plotkwargs = (;
    agent_color = node_color, agent_size = node_size
)


###########################
## Interactive ABM plots ##
###########################

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

mdata = [:avg_profit_rate]
mlabels = ["Avg. profit rate"]


## Interactive ABM plot with aggregated scatterplots

model = initialize_model(world_graph)
fig_exp, abmobs = abmexploration(model;
    params, plotkwargs...,
    adata, alabels, mdata, mlabels
)
fig_exp ## BOOKMARK: looks good!


## Interactive ABM plot with custom plots
# https://juliadynamics.github.io/Agents.jl/stable/examples/agents_visualizations/#Creating-custom-ABM-plots

abmobs = ABMObservable(model; adata, mdata)
