module DasKapital

"""
DasKapital

Module wrapping the local implementation of the simulation.
Use `using .DasKapital` after including this file to access the API.
"""

using Agents
using DataFrames
using Graphs
using Random
using Statistics: mean

# Include implementation files (kept in `src/`)
include(joinpath(@__DIR__, "worker.jl"))
include(joinpath(@__DIR__, "capital.jl"))
include(joinpath(@__DIR__, "capital_formulas.jl"))
include(joinpath(@__DIR__, "model.jl"))
include(joinpath(@__DIR__, "methods.jl"))

# Export the main API
export initialize_model, Worker, Capital,
    get_model_properties, get_capitals_variable, get_workers_variable

end # module
