"""
    UpdateConfig(dp_yel, dp_red, max_inj, sus_margin, fit_gain, fit_after_inj, max_subs)

Immutable struct containing various league constants.

# Fields
- `dp_yel        :: Int16` : Disciplinary points per yellow card
- `dp_red        :: Int16` : Disciplinary points per red card
- `max_inj       :: Int16` : Max injury length
- `sus_margin    :: Int16` : Number of DPs accumulated (since last suspension) to trigger suspension
- `fit_gain      :: Int16` : Fitness gain between each game (ie, fatigue recovery)
- `fit_after_inj :: Int16` : Fitness after returning from an injury
- `max_subs      :: Int16` : Maximum number of substitutions per game

# See also 
- Uses    : [`FUNC`](@ref)
- Used by : [`UPDATECONF`](@ref), [`update_roster`](@ref)
- Related : [`TeamSheetConfig`](@ref), [`TacticsConfig`](@ref), [`RosterInfo`](@ref)
"""
@with_kw struct UpdateConfig
    dp_yel        :: Int16 = 4
    dp_red        :: Int16 = 10
    max_inj       :: Int16 = 9
    sus_margin    :: Int16 = 10
    fit_gain      :: Int16 = 20
    fit_after_inj :: Int16 = 80
    max_subs      :: Int16 = 3
end


"""
    TeamSheetConfig(Pos, Nstarters, Nsubs)

Immutable struct containing constants used to auto-generate teamsheets.

Postion abbreviations:
- GK = Goalkeeper
- DF = Defender
- DM = Defensive Midfielder
- MF = Midfielder
- AM = Attacking Midfielder
- FW = Forward

# Fields
- `Pos       :: SVector{6, String15}` : Valid Positions
- `Nstarters :: SVector{6, Int16}`    : Number of starters at each position
- `Nsubs     :: SVector{6, Int16}`    : Number of subs at each position

# See also 
- Uses    : [`FUNC`](@ref)
- Used by : [`TSCONF`](@ref), [`UpdateTeamSheet`](@ref)
- Related : [`UpdateConfig`](@ref), [`RosterInfo`](@ref)
"""
@with_kw struct TeamSheetConfig
    Pos       :: SVector{6, String15} = SVector{6, String15}("GK", "DF", "DM", "MF", "AM", "FW")
    Nstarters :: SVector{6, Int16}    = SVector{6, Int16}(1, 4, 0, 4, 0, 2)
    Nsubs     :: SVector{6, Int16}    = SVector{6, Int16}(1, 1, 0, 2, 0, 1)
end

