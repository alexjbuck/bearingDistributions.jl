module App

using bearingDistributions
using WebSockets
using Sockets
using Interact
using Blink
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
        t = launchApp(8000)
    catch
        Base.invokelatest(Base.display_error, Base.catch_stack())
        t.state = :done
        return 1
    end
    t.state = :done
    return 0
end

"""
    launchApp(port)

    Serves up the application via Interact.WebIO
"""
function launchApp(port)
    WebIO.webio_serve(page("/", app), port)
end

"""
    app(req)

    The main application. Implements sliders that set parameters for the contour graphs.
"""
function app(req)
    θᵣ = 0:π/100:2π;
    Δθᵣ = .02:.01:.2;
    αᵣ = .5:.01:1
    len = 101:100:1001
    @manipulate throttle = .1 for x₁=slider(0:.1:1.4; value = 0, label = "x₁"),
        x₂=slider(1.5:.1:3.0; value = 3, label = "x₂"),
        θ₁=slider(θᵣ; value = π/4, label = "θ₁"),
        θ₂=slider(θᵣ; value = 3π/4, label = "θ₂"),
        Δθ₁=slider(Δθᵣ; value = .18, label = "Δθ₁"),
        Δθ₂=slider(Δθᵣ; value = .18, label = "Δθ₂"),
        α=slider(αᵣ; value = .95, label = "α"),
        len=slider(len; value = 101, label = "Resolution")

        b1 = Bearing(θ₁, Δθ₁, x₁, 0);
        b2 = Bearing(θ₂, Δθ₂, x₂, 0);
        x,y,Pᵢ,P₁,P₂ = intersectGrid(b1, b2; length=len);
        P = (Pᵢ,P₁,P₂)
        handle = plotConfidenceInterval(α,x,y,P...)
    end
end

function blinkApp()
    θᵣ = 0:π/100:2π;
    Δθᵣ = .02:.01:.2;
    αᵣ = .5:.01:1
    len = 101:100:1001
    ui = @manipulate throttle = .1 for x₁=slider(0:.1:1.4; value = 0, label = "x₁"),
        x₂=slider(1.5:.1:3.0; value = 3, label = "x₂"),
        θ₁=slider(θᵣ; value = π/4, label = "θ₁"),
        θ₂=slider(θᵣ; value = 3π/4, label = "θ₂"),
        Δθ₁=slider(Δθᵣ; value = .18, label = "Δθ₁"),
        Δθ₂=slider(Δθᵣ; value = .18, label = "Δθ₂"),
        α=slider(αᵣ; value = .95, label = "α"),
        len=slider(len; value = 101, label = "Resolution")

        b1 = Bearing(θ₁, Δθ₁, x₁, 0);
        b2 = Bearing(θ₂, Δθ₂, x₂, 0);
        x,y,Pᵢ,P₁,P₂ = intersectGrid(b1, b2; length=len);
        P = (Pᵢ,P₁,P₂)
        handle = plotConfidenceInterval(α,x,y,P...)
    end
    w = Window()
    body!(w, ui)
    return w
end


end
