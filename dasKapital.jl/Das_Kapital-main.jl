# Use local version of Agents.jl
using Pkg
Pkg.activate(".")  # activa l'entorn del projecte actual
# Pkg.develop(path=".")

# # set local Agents.jl
# Pkg.develop(path="/home/joan/Documents/nextcloud/dev/julia/Agents.jl")

# # set upstream Agents.jl
# Pkg.rm("Agents")
# Pkg.add("Agents")

Pkg.status()
# include("src/DasKapital.jl")
using Revise
using DasKapital
using Agents
using DataFrames
using Graphs

g_cycle = cycle_graph(4)
g_bararasi_albert = barabasi_albert!(g_cycle, 16, 3);
# graphplot(g_bararasi_albert)
world_graph = g_bararasi_albert
world_size = 5


#############################
## Define gathered results ##
#############################

using Statistics: mean

isaworker(a) = a isa Worker
isacapital(a) = a isa Capital

# Aggregated data from agents  -> :time, data...
adata = [(isaworker, count), (isacapital, count), (:wealth, mean, isaworker), (:wealth, mean, isacapital)]
alabels = ["n Workers", "n Capitals", "Avg Wealth Workers", "Avg Wealth Capitals"]
# TODO: Notice: Aggregating only works if there are agents to be aggregated over.
#  If you remove agents during model run, you should modify the aggregating functions.
#  E.g. instead of passing mean, pass mymean(a) = isempty(a) ? 0.0 : mean(a).

# Aggregated data from the model
mdata = [:avg_profit_rate]
mlabels = ["Avg. profit rate"]


# adata = [:wealth]  # Data from agents -> :time, :id, data...
# mdata = [:total_wealth]  # TODO: Dades del model que volem recollir


####################
## Run simulation ##
####################

model = initialize_model(world_graph)
# model = initialize_model(world_size)

# model.commodities_demand = 10000


# n_steps = 2500
n_steps = 5

# agent_data: DataFrame containing data collected from agents during the simulation (agregated or for all agents (:id))
# model_data: DataFrame containing data collected from the model during the simulation
agent_data, model_data = run!(model, n_steps; adata=adata, mdata=mdata, showprogress=true) ## aggregated data for agents
# agent_data, model_data = run!(model, n_steps; adata=[:wealth], mdata=mdata, showprogress=true) ## data for individual agents

rename!(
    agent_data,
    :count_isaworker => :n_workers,
    :count_isacapital => :n_capitals,
    :mean_wealth_isaworker => :average_wealth_workers,
    :mean_wealth_isacapital => :average_wealth_capital
)

a = random_agent(model)
capitals = get_capitals_variable(model)
workers = get_workers_variable(model)
get_model_properties(model)


