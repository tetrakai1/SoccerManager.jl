include(joinpath(pwd(), "scripts/autodoc.jl"))
using .AutomaticDocstrings

autodoc(joinpath(pwd(), "src/league.jl"))
# autodoc(joinpath(pwd(), "src/SoccerManager.jl"))
# autodoc(joinpath(pwd(), "scripts/scratch.jl"))