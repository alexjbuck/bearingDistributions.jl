module bearingDistributions
using Distributions
using LinearAlgebra
using NLsolve
using Plots


export Bearing, intersectGrid

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
y = y1 + x*tan(θ1) - x1*tan(θ2)
y = y2 + x*tan(θ2) - x2*tan(θ2)

y - x*tan(θ1) = y1 - x1*tan(θ1)
y - x*tan(θ2) = y2 - x2*tan(θ2)

[-tan(θ1) 1]   [x]  = [y1 - x1*tan(θ1)]
[-tan(θ2) 1] * [y]  = [y2 - x2*tan(θ2)]

[x] = inv( [-tan(θ1) 1] ) * [y1 - x1*tan(θ1)]
[y] =      [-tan(θ2) 1]     [y2 - x2*tan(θ2)]

"""
function findIntersect(b1::Bearing, b2::Bearing)
    if mod(b1.θ-b2.θ,2π)≈π
        point = ([b1.x;b1.y] + [b2.x;b2.y])/2
        return point
    end

    A = [-tan(b1.θ) 1;
         -tan(b2.θ) 1];

    B = [(b1.y - b1.x*tan(b1.θ));
         (b2.y - b2.x*tan(b2.θ))]

    point = inv(A) * B;
end

function boundingBox(b1::Bearing, b2::Bearing)
    pᵢ = findIntersect(b1, b2);
    p₁ = [b1.x;b1.y];
    p₂ = [b2.x;b2.y];
    d₁ = pᵢ - p₁;
    d₂ = pᵢ - p₂;
    D₁ = norm(d₁);
    D₂ = norm(d₂);
    D = max(D₁, D₂);
    box = pᵢ .+ 1*[-D D;-D D];
end

function rangeFromBox(box::Array{Number,2}; length = 51)
    x,y = rangeFromBox(box...; length)
    return x,y
end

function rangeFromBox(x1,y1,x2,y2; length)
    x = range(x1, x2; length);
    y = range(y1, y2; length);
    return x,y
end

function probabilityGrid(b::Bearing, x::AbstractArray, y::AbstractArray)
    D = Normal(b.θ, b.σ);
    if mod.(b.θ,2π)<π/2 || mod(b.θ,2π)>3*π/2
        Θ = atan.(y .- b.y, x' .- b.x);
    else
        Θ = mod.(atan.(y .- b.y, x' .- b.x),2π);
    end
    P = pdf.(D, Θ);
    ΔA = convert(Float64,x.step * y.step);
    P = P./sum(P[:])/ΔA;
    return x, y, P
end

function intersectGrid(b1::Bearing, b2::Bearing; length = 51)
    box = boundingBox(b1, b2);
    x,y = rangeFromBox(box...; length)
    _,_,P₁ = probabilityGrid(b1, x, y);
    _,_,P₂ = probabilityGrid(b2, x, y);
    Pᵢ = P₁ .* P₂
    ΔA = convert(Float64,x.step * y.step);
    Pᵢ = Pᵢ ./ sum(Pᵢ[:])/ΔA;
    return x, y, Pᵢ, P₁, P₂
end

function plotProbabilityGrids(x,y,P...)
    p = contour(;aspect_ratio=:equal);
    for P in P
        contour!(x,y,P)
    end
    display(p)
end

function plotConfidenceInterval(α,x,y,P...)
    plot = contour(;aspect_ratio=:equal);
    ΔA = convert(Float64,x.step*x.step);
    sol = [nlsolve( (p) -> sum(ΔA*P[P .> p])-α, [0.0]; iterations = 50, method = :anderson, ftol = 1e-3) for P in P]
    zeros = [sol.zero for sol in sol]
    for (i,P) in enumerate(P)
        contour!(x,y,P; levels=zeros[i])
    end
    display(plot)
end
    
end