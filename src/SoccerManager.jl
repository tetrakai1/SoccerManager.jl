"""
A performant soccer simulator for gaming and ML.

The main data structure:
```
- LeagueData
    - TeamVec{nteams}
        - Team[1]
            - Roster
            - TeamSheet
            - Comms
        [...]
        - Team[nteams]
            - Roster
            - TeamSheet
            - Comms
    - LgTable
    - TeamNames
    - Schedule
```

Expected data directory structure:
```
- data
    - comms
        - [actively used comm *_*.txt files]
    - rosters
        - Rosters0
            - [clean roster *.txt files]
        - [actively used roster *.txt files]
    - teamsheets
        - Teamsheets0
            - [clean teamsheet *sht.txt files]
        - [actively used teamsheet *sht.txt files]
    - league.dat
    - tactics.dat
    - [actively used table.txt file]
```

"""
module SoccerManager

# Dependencies
using Accessors, Distributions, Format, InlineStrings, Parameters, StaticArrays, StatsBase
using DataFrames, Polyester, .Threads
using UnicodePlots: lineplot, lineplot!, hline!
using StatsPlots: plot, plot!, scatter

# Package Exports
export init_user_data_dir, get_data_paths, retrieve_rosters, retrieve_teamsheets
export LeagueData, Roster, TeamStats, TeamVec, LgTable
export parse_roster, parse_teamsheet, parse_league, update_teamsheet, update_roster, lgrank!
export init_tv, init_lgtble, init_league
export playgame!, playgames!, playseason!
export rost2df, lgtble2df, struct2df, comm2df, flatten_rosters
export reset_all!, save_rosters, write_roster, write_lg_table
export UpdateConfig, TeamSheetConfig, parse_tactics, makeschedule
export init_sims, calc_metric, reset_sims!, playreps!, update_ratings!
export init_rand_ratings!, init_ratings!, rand_ratings, equal_ratings, maxmin, init_percent_ratings!
export plotlog, printlog, stat_scatter, plot_error

# Allows passing an SVector to avoid allocations
StatsBase.weights(w::Weights) = w

"""
    Choose multi-threading library (`@batch` has less overhead but `@threads` is more composable)

# See `SoccerManager.jl`:
- var"@multi" = ifelse(false, var"@batch", var"@threads")
"""
const var"@multi" = ifelse(false, var"@batch", var"@threads")

"""
    Compile-time constants.

- `MAXPLAYERS :: Int` : Maximum number of players per team. A `Roster` must contain *exactly* this many entries. 
                        Teams with fewer players are padded with a placeholder
- `NSUBS      :: Int` : Number of subs *included in the teamsheet*
- `NLINEUP    :: Int` : Number of players in the teamsheet. Eleven starters plus NSUBS

# See also
- Uses    : [`FUNC`](@ref)
- Used by : [`Roster`](@ref), [`Team`](@ref), [`parse_roster`](@ref), [`reset_roster`](@ref), [`write_roster`](@ref), [`flatten_rosters`](@ref), [`parse_teamsheet`](@ref)
- Related : [`RosterInfo`](@ref), [`UpdateConfig`](@ref)
"""
MAXPLAYERS, NSUBS, NLINEUP

const MAXPLAYERS = 30
const NSUBS      = 5
const NLINEUP    = 11 + NSUBS
export MAXPLAYERS, NSUBS, NLINEUP

# Contain type definitions
include("comms.jl")
include("config.jl")
include("rosters.jl")
include("tactics.jl")
include("teamsheets.jl")
include("misc.jl")
include("leaguetable.jl")
include("league.jl")

# Other source
include("dirmanagement.jl")
include("game.jl")
include("gameutils.jl")
include("injury.jl")

# Machine learning utils
include("ML_Tools/mltools.jl")
include("ML_Tools/init_ratings.jl")
include("ML_Tools/metric.jl")
include("ML_Tools/sampler.jl")
include("ML_Tools/plots_logs.jl")

"""
    Path and file format constants

- `DATADIR0 :: String`     : Path to package data directory
- `ROSTINFO :: RosterInfo` : Immutable struct containing config values for reading/writing the fixed-width roster files

# See also
- Uses    : [`RosterInfo`](@ref)
- Used by : [`init_user_data_dir`](@ref)
- Related : [`FUNC`](@ref)
"""
DATADIR0, ROSTINFO

const DATADIR0 = joinpath(dirname(@__DIR__), "data")
const ROSTINFO = RosterInfo()
export DATADIR0, ROSTINFO


"""
    Runtime constants (defined later from file/scripts)

- `TACTICSCONF :: TacticsConfig`   : Immutable struct containing the tactics and bonus skill multipliers
- `TSCONF      :: TeamSheetConfig` : Immutable struct containing constants used to auto-generate teamsheets
- `UPDATECONF  :: UpdateConfig`    : Immutable struct containing various league constants

# See also
- Uses    : [`TacticsConfig`](@ref), [`TeamSheetConfig`](@ref), [`UpdateConfig`](@ref)
- Used by : [`getTactMult`](@ref), [`update_bonus!`](@ref), [`update_teamsheet`](@ref), [`rand_injury!`](@ref), [`update_roster`](@ref)
- Related : [`FUNC`](@ref)
"""
TACTICSCONF, TSCONF, UPDATECONF

const TACTICSCONF = Ref{TacticsConfig}()
const TSCONF      = Ref{TeamSheetConfig}()
const UPDATECONF  = Ref{UpdateConfig}()
export TACTICSCONF, TSCONF, UPDATECONF

"""
    FUNC()

Placeholder function
"""
function FUNC()
    return nothing
end
export FUNC

end # module

