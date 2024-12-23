"""
    TeamNames(v)

Immutable `FieldVector` containing a TeamName struct for each team. 

Stores the team names for the league.

# Fields
- `v :: SVector{nteams, String15}` : `SVector` of the team names

# See also 
- Uses    : [`FUNC`](@ref)
- Used by : [`parse_league`](@ref), [`init_lgtble`](@ref), [`retrieve_rosters`](@ref), [`retrieve_teamsheets`](@ref), [`reset_lgtble!`](@ref), [`reset_all!`](@ref)
- Related : [`Sched`](@ref)
"""
struct TeamNames{N, String15} <: FieldVector{N, String15}
    v :: SVector{N, String15}
end
Base.getindex(v  :: TeamNames, i :: Int)                = getindex(v.v, i)
Base.setindex!(v :: TeamNames, X :: String15, i :: Int) = setindex!(v.v, X, i)

"""
    Team(roster, teamsht, comm)

Mutable struct containing the `Roster`, `TeamSheet`, and `Comms` structs for a single team.

# Fields
- `roster  :: Roster`    : An immutable `Roster` struct
- `teamsht :: TeamSheet` : An immutable `Teamsheet` struct
- `comm    :: Comms`     : A mutable `Comms` struct

# See also 
- Uses    : [`MAXPLAYERS`](@ref), [`NLINEUP`](@ref), [`Roster`](@ref), [`TeamSheet`](@ref), [`Comms`](@ref)
- Used by : [`TeamVec`](@ref), [`init_tv`](@ref)
- Related : [`FUNC`](@ref)
"""
@with_kw mutable struct Team
    roster  :: Roster{SVector{MAXPLAYERS, String15}, SVector{MAXPLAYERS, Int16}}

    teamsht :: TeamSheet{SVector{11, String15}, SVector{NSUBS, String15}}

    comm    :: Comms{SVector{NLINEUP, String15}, SVector{NLINEUP, Int16},
                     SVector{NLINEUP, Float32},  SVector{NLINEUP, Bool}}
end

"""
    TeamVec(v)

Immutable `FieldVector` containing a `Team` struct for each team. 

Stores all the info (stats, ratings, teamsheets, etc) about the players in the league. Team-level stats are in the `LgTable`.

# Fields
- `v :: SVector{nteams, Team}` : `SVector` of the `Team` structs, each element contains the player info for that team

# See also 
- Uses    : [`Team`](@ref)
- Used by : [`init_tv`](@ref)
- Related : [`LgTable`](@ref)
"""

struct TeamVec{N, Team} <: FieldVector{N, Team}
    v :: SVector{N, Team}
end
Base.getindex(v  :: TeamVec, i :: Int)            = getindex(v.v, i)
Base.setindex!(v :: TeamVec, X :: Team, i :: Int) = setindex!(v.v, X, i)

"""
    LeagueData(tv, lg_table, teamnames, schedule)

Immutable struct containing `TeamVec`, `LgTable`, `TeamNames`, and `Sched` structs for an entire league.

# Fields
- `tv        :: TeamVec`   : Contains `Roster`, `TeamSheet`, and `Comms` structs for each team
- `lg_table  :: LgTable`   : The league table (wins, losses, etc)
- `teamnames :: TeamNames` : Vector of team names
- `schedule  :: Sched`     : The league schedule

# See also 
- Uses    : [`TeamVec`](@ref), [`Team`](@ref), [`LgTable`](@ref), [`TeamStats`](@ref)
- Used by : [`init_league`](@ref)
- Related : [`FUNC`](@ref)
"""
@with_kw struct LeagueData{nteams}
    tv        :: TeamVec{nteams,   Team}
    lg_table  :: LgTable{nteams,   TeamStats}
    teamnames :: TeamNames{nteams, String15}
    schedule  :: Sched
end


"""
    init_league(rpaths, tspaths, teamnames, schedule; usefile = true)

Initialize a `LeagueData` struct to hold all the player and team-level info for the league.

Contains `TeamVec`, `LgTable`, `TeamNames`, and `Sched` structs. Rosters are read from file, teamsheets can be either read from file or auto-generated from the rosters.

# Arguments
- `rpaths    :: Vector{String}` : Vector of paths to the fixed-width roster files
- `tspaths   :: Vector{String}` : Vector of paths to the fixed-width teamsheet files
- `teamnames :: TeamNames`      : Vector of team names
- `sched     :: Schedule`       : The league schedule

# Kwargs
- `usefile :: Bool` : Whether to read the teamsheets from file rather than auto-generate based on the rosters

# Returns
A mutable `LeagueData` struct.

# See also
- Uses    : [`TeamNames`](@ref), [`Sched`](@ref), [`LeagueData`](@ref), [`init_tv`](@ref), [`init_lgtble`](@ref)
- Used by : [`FUNC`](@ref)
- Related : [`FUNC`](@ref)
"""
function init_league(rpaths, tspaths, teamnames, schedule; usefile = true)
   return LeagueData(tv        = init_tv(rpaths, tspaths; usefile),
                     lg_table  = init_lgtble(teamnames),
                     teamnames = teamnames,
                     schedule  = schedule)
end

"""
    init_tv(rpaths, tspaths; usefile = true)

Creates a `TeamVec` vector, which contains all the player-level info about the league.

Reads rosters from file for each team. If `usefile = true` also read the `TeamSheet`, else generate one based on the `Roster`. Default `Comms` are then generated for each team.

# Arguments
- `rpaths  :: Vector{String}` : Paths to the roster files
- `tspaths :: Vector{String}` : Paths to the teamsheet files

# Kwargs
- `usefile :: Bool` : Whether to use teamsheet files or auto-generate based on the roster

# Returns
A `TeamVec` vector.

# See also 
- Uses    : [`Team`](@ref), [`TeamVec`](@ref), [`parse_roster`](@ref), [`parse_teamsheet`](@ref), [`update_teamsheet`](@ref)
- Used by : [`FUNC`](@ref)
- Related : [`init_lgtble`](@ref)
"""
function init_tv(rpaths, tspaths; usefile = true)
    nteams = length(rpaths)
    tv     = SizedVector{nteams, Team}(undef)

    @multi for i in eachindex(rpaths)
        roster  = parse_roster(rpaths[i])
        teamsht = ifelse(usefile, parse_teamsheet(tspaths[i]), update_teamsheet(roster))
        tv[i]   = Team(roster  = roster,
                       teamsht = teamsht,
                       comm    = Comms())
    end
    return TeamVec(SVector(tv))
end



"""
    reset_all!(lg_data)

Resets all stats (`tv` and `lg_table` elements of `lg_data`) to default values (ie, to play a new season).

`TeamSheets` are autogenerated based on rosters.

# Arguments
- `lg_data :: LeagueData` : Contains all the player and team-level info for the league

# Returns
Nothing. Mutates `lg_data` as reset to default values.

# See also 
- Uses    : [`LeagueData`](@ref), [`reset_roster`](@ref), [`update_teamsheet`](@ref), [`makecomm!`](@ref), [`reset_lgtble!`](@ref)
- Used by : [`FUNC`](@ref)
- Related : [`FUNC`](@ref)
"""
function reset_all!(lg_data)
    @unpack_LeagueData lg_data
    for i in eachindex(tv)
        tv[i].roster  = reset_roster(tv[i].roster)
        tv[i].teamsht = update_teamsheet(tv[i].roster; tactic = "N")
        makecomm!(tv[i].comm, tv[i].roster, tv[i].teamsht)
    end
    reset_lgtble!(lg_table, teamnames)

    return nothing
end



"""
    parse_league(path_league, nteams)

Reads the `league.dat` file and returns a vector of the first nteams after sorting.

# Arguments
- `path_league :: String` : Path to the `league.dat` file containing the team names
- `nteams      :: Int`    : Number of teams to use

# Returns
An immutable `TeamNames` struct of team names.

# See also
- Uses    : [`TeamNames`](@ref)
- Used by : [`FUNC`](@ref)
- Related : [`init_lgtble`](@ref), [`reset_lgtble!`](@ref), [`reset_all!`](@ref), [`flatten_players`](@ref),

"""
function parse_league(path_league, nteams)
    teamvec   = readlines(path_league)
    teamnames = String15.(sort(teamvec[1:nteams]))
    res       = MVector{length(teamnames), String15}(teamnames)

    return TeamNames(SVector(res))
end

