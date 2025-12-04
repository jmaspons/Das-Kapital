using Agents
using DataFrames


#############
## Getters ##
#############

function Base.show(io::IO, a::Worker)
    print(Agents.agent2string(a))
end

function Base.show(io::IO, a::Capital)
    print(Agents.agent2string(a))
end

function Base.show(io::IO, a::AbstractAgent)
    print(Agents.agent2string(a))
end

function Base.show(io::IO, p::ModelParameters)
    println(io, typeof(p), "(")
    for field in fieldnames(typeof(p))
        val = getfield(p, field)
        println(io, "  ", rpad(string(field), 20), " = ", val)
    end
    println(io, ")")
end


function get_capitals_variable(model::AgentBasedModel, variable::Symbol)
    capital_ids = filter(id -> model[id] isa Capital, allids(model))
    vals = Vector(undef, length(capital_ids))
    for (i, id) in enumerate(capital_ids)
        vals[i] = getproperty(model[id], variable)
    end

    return vals
end


function get_workers_variable(model::AgentBasedModel, variable::Symbol)
    workers_ids = filter(id -> model[id] isa Worker, allids(model))
    vals = Vector(undef, length(workers_ids))
    for (i, id) in enumerate(workers_ids)
        vals[i] = getproperty(model[id], variable)
    end

    return vals
end


function get_capitals_variable(model::AgentBasedModel)
    capital_ids = filter(id -> model[id] isa Capital, allids(model))
    a = model[first(capital_ids)]
    cols = fieldnames(typeof(a))
    df = DataFrame(
        [getproperty(model[id], col) for id in capital_ids, col in cols],
        collect(cols)
    )
    
    # Set types
    for (i, type) in enumerate(fieldtypes(typeof(a)))
        df[!, i] = convert(Vector{type}, df[!, i])
    end

    return df
end


function get_workers_variable(model::AgentBasedModel)
    workers_ids = filter(id -> model[id] isa Worker, allids(model))
    a = model[first(workers_ids)]
    cols = fieldnames(typeof(a))
    df = DataFrame(
        [getproperty(model[id], col) for id in workers_ids, col in cols],
        collect(cols)
    )

    # Set types
    for (i, type) in enumerate(fieldtypes(typeof(a)))
        df[!, i] = convert(Vector{type}, df[!, i])
    end

    return df
end
