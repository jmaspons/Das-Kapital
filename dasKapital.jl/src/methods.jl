using Agents
using DataFrames

function agent2string(agent::A) where {A<:AbstractAgent}
    agentstring = "▶ $(nameof(A))\n"

    agentstring *= "id: $(getproperty(agent, :id))\n"

    if hasproperty(agent, :pos)
        pos = getproperty(agent, :pos)
        if pos isa Union{NTuple{<:Any, <:AbstractFloat},SVector{<:Any, <:AbstractFloat}}
            pos = round.(pos, sigdigits=2)
        elseif pos isa Tuple{<:Int, <:Int, <:AbstractFloat}
            pos = (pos[1], pos[2], round(pos[3], sigdigits=2))
        end
        agentstring *= "pos: $(pos)\n"
    end

    for field in fieldnames(A)[3:end]
        val = getproperty(agent, field)
        if val isa AbstractFloat
            val = round(val, sigdigits=2)
        elseif val isa AbstractArray{<:AbstractFloat}
            val = round.(val, sigdigits=2)
        elseif val isa NTuple{<:Any, <:AbstractFloat}
            val = round.(val, sigdigits=2)
        end
        agentstring *= "$(field): $val\n"
    end

    return agentstring
end

function Base.show(io::IO, a::AbstractAgent)
    agentstring = agent2string(a)
    print(io, agentstring)
end


function Base.show(io::IO, p::ModelParameters)
    println(io, typeof(p), "(")
    for field in fieldnames(typeof(p))
        val = getfield(p, field)
        println(io, "  ", rpad(string(field), 20), " = ", val)
    end
    println(io, ")")
end


#############
## Getters ##
#############

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


function get_model_properties(model::AgentBasedModel)
    abmproperties(model)
end