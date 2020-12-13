module bearingDistributions
using Distributions
using LinearAlgebra
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
    box = pᵢ .+ 2*[-D D;-D D];
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
    Θ = atan.(y .- b.y, x' .- b.x);
    P = pdf.(D, Θ);
    return x, y, P
end


function intersectGrid(b1::Bearing, b2::Bearing; length = 51)
    box = boundingBox(b1, b2);
    x,y = rangeFromBox(box...; length)
    _,_,P₁ = probabilityGrid(b1, x, y);
    _,_,P₂ = probabilityGrid(b2, x, y);
    Pᵢ = P₁ .* P₂
    return x, y, Pᵢ
end

end