module bearingDistributions
using Distributions
using LinearAlgebra
using Plots

include("App.jl")
using .App

export Bearing, intersectGrid, bisectionRoots, plotConfidenceInterval, App

"""
Bearing object.

Defined by a mean direction θ, a standard deviation of direction σ, and a position (x,y).
"""
struct Bearing
    θ
    σ
    x
    y
end

"""
findIntersect(b1::Bearing, b2::Bearing)

This solves the simultaneous equations of the two paramterized lines as below:
    x₁ + cos(θ₁)t₁ = x₂ + cos(θ₂)t₂
    y₁ + sin(θ₁)t₁ = y₂ + sin(θ₂)t₂

    x₁ - x₂ = -cos(θ₁)t₁ + cos(θ₂)t₂
    y₁ - y₂ = -sin(θ₁)t₁ + sin(θ₂)t₂

    This can be represented in matrix form as:
    b = Ax̄
    
    where:
    x̄ = [t₁, t₂]
    A = |-cos(θ₁) cos(θ₂)|
        |-sin(θ₁) sin(θ₂)|
        
    b = [x₁ - x₂, y₁ - y₂]

    Solved by:
    x̄ = A⁻¹ ⋅ b

    This matrix is singular when θ₁ and θ₂ are parallel, i.e.  mod(θ₁,π) == mod(θ₂,π)
    In this case, there is a heuristic that sets the "intersection" as the midpoint between the two points.

    Furthermore, if tᵢ<0 then there is no defined intersection point (lines pointed away from each other)
"""
function findIntersect(b1::Bearing, b2::Bearing)
    if mod(b1.θ-b2.θ,π)≈0 
        point = ([b1.x;b1.y] + [b2.x;b2.y])/2
        return point
    end

    A = [-cos(b1.θ) cos(b2.θ);
         -sin(b1.θ) sin(b2.θ)]

    b = [b1.x - b2.x, b1.y - b2.y];
    
    t = inv(A) * b;
    if any(t .< 0)
        point = ([b1.x;b1.y] + [b2.x;b2.y])/2
        return point
    end
    point = [b1.x, b1.y] + [cos(b1.θ), sin(b1.θ)]*t[1];
    return point
end


"""
boundingBox(b1::Bearing, b2::Bearing)    
    Return the box [xₗ xᵤ;yₗ yᵤ] around the intersection of two bearings.

    Size the box such that the origin of the bearings will always be included in the box.
"""
function boundingBox(b1::Bearing, b2::Bearing)
    pᵢ = findIntersect(b1, b2);
    p₁ = [b1.x;b1.y];
    p₂ = [b2.x;b2.y];
    d₁ = pᵢ - p₁;
    d₂ = pᵢ - p₂;
    D₁ = norm(d₁);
    D₂ = norm(d₂);
    D = 1.5*max(D₁, D₂);
    box = pᵢ .+ 1*[-D D;-D D];
    box
end

"""
rangeFromBox(box::Array{Number,2}; length = 51)

    Wrapper to splat out the box array.
"""
function rangeFromBox(box::Array{Number,2}; length = 51)
    x,y = rangeFromBox(box...; length)
    return x,y
end


"""
rangeFromBox(x1,y1,x2,y2; length)

    convert `x1`:`x2` and `y1`:`y2` into ranges of length `length`
"""
function rangeFromBox(x1,y1,x2,y2; length)
    x = range(x1, x2; length);
    y = range(y1, y2; length);
    return x,y
end

"""
probabilityGrid(b::Bearing, x::AbstractArray, y::AbstractArray)

    Compute the probability grid over ranges `x` and `y` of bearing `b`
"""
function probabilityGrid(b::Bearing, x::AbstractArray, y::AbstractArray)
    θ = mod(b.θ + π,2π) - π
    D = Normal(0, b.σ);
    Θ = atan.(y .- b.y, x' .- b.x) .- θ;
    Θ = mod.(Θ .+ π, 2π) .-π
    P = pdf.(D, Θ);
    ΔA = convert(Float64,x.step * y.step);
    P = P./sum(P[:])/ΔA;
    return x, y, P
end

"""
intersectGrid(b1::Bearing, b2::Bearing; length = 51)

    Compute the probability grid of the intersection of `b1` and `b2` over ranges `x` and `y`

    Return the probability grids for `b1`, `b2`, and the intersection.

"""
function intersectGrid(b1::Bearing, b2::Bearing; length = 51)
    box = boundingBox(b1, b2);
    x,y = rangeFromBox(box...; length)
    _,_,P₁ = probabilityGrid(b1, x, y);
    _,_,P₂ = probabilityGrid(b2, x, y);
    Pᵢ = P₁ .* P₂
    ΔA = convert(Float64,x.step * y.step);
    Pᵢ = Pᵢ ./ sum(Pᵢ[:])
    Pᵢ = Pᵢ ./ ΔA;
    return x, y, Pᵢ, P₁, P₂
end

"""
plotProbabilityGrids(x::AbstractArray, y::AbstractArray, P...)

    Plot of tuple of probability grids `P` on ranges x and y with the default contour levels
"""
function plotProbabilityGrids(x::AbstractArray, y::AbstractArray, P...)
    p = contour(;aspect_ratio=:equal);
    for P in P
        contour!(x,y,P)
    end
    display(p)
end

"""
plotConfidenceInterval(α::Number, x::AbstractArray, y::AbstractArray, P...)

    Plot the tuple of probability grids `P` on ranges x and y at the defined confidence interval `α`
"""
function plotConfidenceInterval(α::Number, x::AbstractArray, y::AbstractArray, P...)
    handle = contour(;aspect_ratio=:equal);
    ΔA = convert(Float64,x.step*y.step);
    zeros = [bisectionRoots((p) -> ΔA*sum(Pⱼ[Pⱼ .> p]) - α, minimum(Pⱼ),maximum(Pⱼ)) for Pⱼ in P]
    for (i,P) in enumerate(P)
        contour!(x,y,P; levels=[zeros[i]])
    end
    return handle
end

"""
bisectionRoots(f::Function,xₗ::Number,xᵤ::Number; max_iteration = 100, xtol = 1e-3)

    Computes the root of function `f(x)` on the bounded range `[xₗ xᵤ]` with the Bisection algorithm.

    Exit condition is defined by xᵤ-xₗ < xtol
"""
function bisectionRoots(f::Function,xₗ::Number,xᵤ::Number; max_iteration = 100, xtol = 1e-3)
    fₗ  = f(xₗ);
    fᵤ = f(xᵤ);

    if fₗ == 0
        return xₗ
    elseif fᵤ == 0
        return xᵤ
    end

    if (fₗ<0 && fᵤ<0) || (fₗ>0 && fᵤ>0)
        error("There is no root of the given function on the given range")
        return
    end

    xᵢ = (xₗ + xᵤ)/2;
    iter = 1;

    while abs(xᵤ-xₗ) > xtol
        iter > max_iteration ? break : iter+=1;
        if sign(f(xᵢ))==sign(fₗ)
            xₗ = xᵢ
            xᵢ = (xᵢ + xᵤ)/2
        else
            xᵤ = xᵢ
            xᵢ = (xₗ + xᵢ)/2
        end
    end
    return xᵢ
end



end