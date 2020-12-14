using bearingDistributions
using Plots
using Test

const bd = bearingDistributions

@testset "bearingDistributions.jl" begin
    b1 = Bearing(atan(1,1),  .1, 0, 0);
    b2 = Bearing(atan(-1,1), .2, 0, 1);
    @test b1.x ≈ 0
    @test b1.y ≈ 0
    @test b1.θ ≈ atan(1,1)
    @test b1.σ ≈ .1
    @test b2.x ≈ 0
    @test b2.y ≈ 1
    @test b2.θ ≈ atan(-1,1)
    @test b2.σ ≈ .2
    @test bd.findIntersect(b1, b2) ≈ [.5;.5] 

    b1 = Bearing(0, 1, 0, 1);
    b2 = Bearing(π/2, .1, 1, 0);
    @test bd.boundingBox(b1, b2) ≈ [0 2; 0 2]

    b1 = Bearing(0, .2, 0, 1);
    b2 = Bearing(π/2, .2, 1, 0);
    box = bd.boundingBox(b1, b2);
    x,y = bd.rangeFromBox(box...; length = 51)

    display(contour(bd.probabilityGrid(b1,x,y)...))
    display(contour(bd.probabilityGrid(b2,x,y)...))
    display(contour(intersectGrid(b1, b2; length = 51)...))
end
