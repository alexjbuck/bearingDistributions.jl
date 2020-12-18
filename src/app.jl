module App

using bearingDistributions
using Interact
using Plots
using Mux

const bd = bearingDistributions

export julia_main

"""
    julia_main()

    Wrapper for PackageCompiler.jl
"""
function julia_main()
    try
        launchApp(8000)
    catch
        Base.invokelatest(Base.display_error, Base.catch_stack())
        return 1
    end
    return 0
end

"""
    launchApp(port)

    Serves up the application via Interact.WebIO
"""
function launchApp(port)
    WebIO.webio_serve(page("/", App), port)
end

"""
    app(req)

    The main application. Implements sliders that set parameters for the contour graphs.
"""
function app(req)
    θᵣ = 0:.1:2π;
    Δθᵣ = .02:.01:.2;
    αᵣ = .5:.01:1
    len = 501
    @manipulate for x₁=slider(0:.1:1.4; value = 0, label = "x₁"),
        x₂=slider(1.5:.1:3.0; value = 3, label = "x₂"),
        θ₁=slider(θᵣ; value = π/4, label = "θ₁"),
        θ₂=slider(θᵣ; value = 3π/4, label = "θ₂"),
        Δθ₁=slider(Δθᵣ; value = .18, label = "Δθ₁"),
        Δθ₂=slider(Δθᵣ; value = .18, label = "Δθ₂"),
        α=slider(αᵣ; value = .95, label = "α")

        b1 = Bearing(θ₁, Δθ₁, x₁, 0);
        b2 = Bearing(θ₂, Δθ₂, x₂, 0);
        x,y,Pᵢ,P₁,P₂ = intersectGrid(b1, b2; length=len);
        P = (Pᵢ,P₁,P₂)
        handle = plotConfidenceInterval(α,x,y,P...)
        # ΔA = convert(Float64,x.step*y.step);
        # zeros = [bisectionRoots((p) -> ΔA*sum(Pⱼ[Pⱼ .> p]) - α, minimum(Pⱼ),maximum(Pⱼ)) for Pⱼ in P]
        # contour(x,y,Pᵢ; levels=[zeros[1]])
        # contour!(x,y,P₁; levels=[zeros[2]])
        # contour!(x,y,P₂; levels=[zeros[3]])
    end
end


end