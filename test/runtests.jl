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

    b1 = Bearing(0, .1, 0, 0);
    b2 = Bearing(π, .1, 1, 0);
    @test bd.findIntersect(b1, b2) ≈ [.5, 0]

    b1 = Bearing(π, .1, 0, 0);
    b2 = Bearing(π/2, .1, 1, 0);
    @test bd.findIntersect(b1, b2) ≈ [.5, 0]

    b1 = Bearing(0, 1, 0, 1);
    b2 = Bearing(π/2, .1, 1, 0);
    @test bd.boundingBox(b1, b2) ≈ [0 2; 0 2]

    @test bd.rangeFromBox([0 2; 0 2]; length = 2) ≈ ([0,2],[0,2])

    @test isnan(bisectionRoots((x)-> x.^2+1, -1, 1, 100))

    @test bisectionRoots((x) -> x+1, -2, 0; xtol = 1e-9) ≈ -1

    @test bisectionRoots((x) -> x+1, -1, 0) ≈ -1
    @test bisectionRoots((x) -> x+1, -2, -1) ≈ -1

    b1 = Bearing(0, .1, 0, 1);
    b2 = Bearing(π/2, .1, 1, 0);
    len = 11;
    α = .95;
    @test typeof(plotConfidenceInterval(α,bd.intersectGrid(b1, b2; length=len)...)) <: AbstractPlot

    @test typeof(App.app([]) <: Widgets.Widget{:manipulate,Any}

    t = App.launchApp(8001)
    @test typeof(t) <: Task
    @test t.state = :runnable
    t.state = :done
    @test t.state = :done

    @test julia_main() == 0
end