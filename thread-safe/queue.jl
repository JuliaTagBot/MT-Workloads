import Base.push!, Base.pop!
using Base.Threads

type tsqueue{T} <: AbstractArray{T,1}
	data::Vector{T}
	lock::SpinLock
end

function push!{T}(a::tsqueue{T}, b::T)
	lock!(a.lock)
	push!(a.data, b)
	unlock!(a.lock)
end

function tsqueue{T}(a::Vector{T})
	s = SpinLock()
	tsqueue(a,s)
end

function pop!{T}(a::tsqueue{T})
	lock!(a.lock)
	pop!(a.data)
	unlock!(a.lock)
end
