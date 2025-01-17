"""
    NelsonAalen{S,T}

An immutable type containing cumulative hazard function estimates computed
using the Nelson-Aalen method.
The type has the following fields:

* `events`: An [`EventTable`](@ref) summarizing the times and events
  used to compute the estimates. The time values are of type `T`.
* `chaz`: Estimate of the cumulative hazard at each time. Values are of
  type `S`.
* `stderr`: Standard error of the cumulative hazard at each time. Values
  are of type `S`.

Use `fit(NelsonAalen, ...)` to compute the estimates as `Float64` values
and construct this type.
Alternatively, `fit(NelsonAalen{S}, ...)` may be used to request a
particular value type `S` for the estimates.
"""
struct NelsonAalen{S,T} <: NonparametricEstimator
    events::EventTable{T}
    chaz::Vector{S}
    stderr::Vector{S}
end

"""
To computes the cumulative hazard estimation at time `t` of a NelsonAalen fit you can use.

```julia
na = fit(NelsonAalen, ...)
t = 5
na(t) # evaluates the estimator at time 5
```
"""
function (na::NelsonAalen)(t::Real)
    time_points = na.events.time
    cumulative_hazard = na.chaz
    if t < time_points[1]
        return estimator_start(typeof(na))
    else
        id = findlast(x -> x <= t, time_points) 
        return cumulative_hazard[id]
    end
end

estimator_eltype(::Type{<:NelsonAalen{S}}) where {S} = S
estimator_eltype(::Type{NelsonAalen}) = Float64

estimator_start(T::Type{<:NelsonAalen}) = zero(estimator_eltype(T))
stderr_start(T::Type{<:NelsonAalen}) = zero(estimator_eltype(T))

estimator_update(::Type{<:NelsonAalen}, es, dᵢ, nᵢ) = es + dᵢ // nᵢ
stderr_update(::Type{<:NelsonAalen}, gw, dᵢ, nᵢ) = gw + dᵢ * (nᵢ - dᵢ) // (nᵢ^3)

"""
    confint(na::NelsonAalen; level=0.05)

Compute the pointwise confidence intervals for the cumulative hazard
function as a vector of tuples.
"""
function StatsAPI.confint(na::NelsonAalen; level::Real=0.05)
    q = quantile(Normal(), 1 - level/2)
    return map(na.chaz, na.stderr) do srv, se
        srv - q * se, srv + q * se
    end
end

"""
    fit(NelsonAalen, times, status) -> NelsonAalen

Given a vector of times to events and a corresponding vector of indicators that
denote whether each time is an observed event or is right censored, compute the
Nelson-Aalen estimate of the cumulative hazard rate function.
"""
StatsAPI.fit(::Type{NelsonAalen}, times, status)

"""
    fit(NelsonAalen, ets) -> NelsonAalen

Compute the Nelson-Aalen estimate of the cumulative hazard rate function from a
vector of [`EventTime`](@ref) values.
"""
StatsAPI.fit(::Type{NelsonAalen}, ets)
