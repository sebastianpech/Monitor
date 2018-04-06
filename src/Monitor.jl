module Monitor

export monitor, attach_monitor
using Caching

const init_size = 1000000

type monitor{TL,TV}
    fetch_function::Function
    label_function::Function

    labels::Vector{TL}
    values::Vector{TV}
    unique_only::Bool
end

function monitor(TL::Type,TV::Type,fetch_function::Function,label_function::Function;unique_only=true)
    new = monitor(fetch_function,label_function,Vector{TL}(),Vector{TV}(),unique_only)
    sizehint!(new.labels,init_size)
    sizehint!(new.values,init_size)
end

function monitor(TV::Type,fetch_function::Function;unique_only=true)
    monitor(fetch_function,Monitor.counter(),Vector{Int}(),Vector{TV}(),unique_only)
end

function monitor(TV::Type;unique_only=true)
    monitor(()->nothing,Monitor.counter(),Vector{Int}(),Vector{TV}(),unique_only)
end

function attach_monitor{TL,TV}(m::monitor{TL,TV},original_function::Function)
    prev_calls = Vector{UInt}()
    sizehint!(prev_calls,init_size)
    function(args...)
        if m.unique_only && !(hashkeys((args...)) in prev_calls)
            push!(m.labels,m.label_function()::TL)
            push!(m.values,m.fetch_function()::TV)
            push!(prev_calls,hashkeys((args...)))
        end
        original_function(args...)
    end
end

function counter(init::Int=0)
    function()
        init::Int+=1
        return init
    end
end

function hashkeys(tup::Tuple)
    hash(map(tup) do xi
        hash(xi)
    end)
end

end
