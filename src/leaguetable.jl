
"""
    TeamStats(Pl, Team, P, W, D, L, GF, GA, GD, Pts)

Immutable struct containing the league table values for a single team.

# Fields
- `Pl   :: Int16   ` : Place
- `Team :: String15` : Team Name
- `P    :: Int16   ` : Games Played
- `W    :: Int16   ` : Wins
- `D    :: Int16   ` : Draws
- `L    :: Int16   ` : Losses
- `GF   :: Int16   ` : Goals For
- `GA   :: Int16   ` : Goals Against
- `GD   :: Int16   ` : Goal Difference
- `Pts  :: Int16   ` : Points (3*W + D)

# See also 
- Uses    : [`FUNC`](@ref)
- Used by : [`LgTable`](@ref), [`init_lgtble`](@ref)
- Related : [`FUNC`](@ref)
"""
@with_kw struct TeamStats
    Pl   :: Int16    = 0
    Team :: String15 = ""
    P    :: Int16    = 0
    W    :: Int16    = 0
    D    :: Int16    = 0
    L    :: Int16    = 0
    GF   :: Int16    = 0
    GA   :: Int16    = 0
    GD   :: Int16    = 0
    Pts  :: Int16    = 0
end

"""
    LgTable(v)

Mutable `FieldVector` containing a TeamStats struct for each team. 

Stores all the team-level stats for the league. Player-level stats are in the `TeamVec` vector.

# Fields
- `v :: MVector{nteams, TeamStats}` : `MVector` of `TeamStats` structs, each element contains the stats (wins, losses, etc) for that team

# See also 
- Uses    : [`TeamStats`](@ref)
- Used by : [`init_lgtble`](@ref)
- Related : [`TeamVec`](@ref)
"""
mutable struct LgTable{N, TeamStats} <: FieldVector{N, TeamStats}
    v :: MVector{N, TeamStats}
end
Base.getindex(v  :: LgTable, i :: Int)                 = getindex(v.v, i)
Base.setindex!(v :: LgTable, X :: TeamStats, i :: Int) = setindex!(v.v, X, i)



"""
    init_lgtble(teamnames)

Creates the league table, which contains all the team-level info about the league.

# Arguments
- `teamnames :: TeamNames` : Vector of team names

# Returns
A `LgTable` vector.

# See also 
- Uses    : [`TeamStats`](@ref), [`LgTable`](@ref), [`TeamNames`](@ref)
- Used by : [`FUNC`](@ref)
- Related : [`update_lgtble!`](@ref), [`lgrank!`](@ref), [`reset_lgtble!`](@ref), [`init_tv`](@ref)
"""
function init_lgtble(teamnames)
    nteams   = length(teamnames)
    lg_table = MVector{nteams}((TeamStats() for i in eachindex(teamnames)))
    for i in eachindex(lg_table) 
      lg_table[i] = @set $(lg_table[i]).Team = teamnames[i] 
    end
    return LgTable(lg_table)
end


"""
    update_lgtble!(lg_table, comms, idx1, idx2)

Updates the `lg_table` based on game results stored in `comms`.

# Arguments
- `lg_table :: LgTable`             : The league table (wins, losses, etc)
- `comms    :: Tuple{Comms, Comms}` : Pair of `Comms` structs containing results of the last game
- `idx1     :: Int`                 : Index of the league table for the home team
- `idx2     :: Int`                 : Index of the league table for the away team

# Returns
Nothing. Mutates a `LgTable` updated with the results of the last game.

# See also 
- Uses    : [`Comms`](@ref), [`LgTable`](@ref)
- Used by : [`playgames!`](@ref)
- Related : [`init_lgtble`](@ref), [`lgrank!`](@ref), [`reset_lgtble!`](@ref)
"""
function update_lgtble!(lg_table, comms, idx1, idx2)
    gls   = SVector{2}(sum(comms[1].Gls), sum(comms[2].Gls))
    gdiff = gls[1] - gls[2]
    idx   = SVector(idx1, idx2)

    if gdiff == 0
        lg_table[idx1] = @set $(lg_table[idx1]).D += Int16(1)
        lg_table[idx2] = @set $(lg_table[idx2]).D += Int16(1)
    elseif gdiff > 0
        lg_table[idx1] = @set $(lg_table[idx1]).W += Int16(1)
        lg_table[idx2] = @set $(lg_table[idx2]).L += Int16(1)
    else
        lg_table[idx1] = @set $(lg_table[idx1]).L += Int16(1)
        lg_table[idx2] = @set $(lg_table[idx2]).W += Int16(1)
    end

    lg_table[idx1] = @set $(lg_table[idx1]).GA += gls[2]
    lg_table[idx2] = @set $(lg_table[idx2]).GA += gls[1]
    for i in 1:2
        lg_table[idx[i]] = @set $(lg_table[idx[i]]).P   += Int16(1)
        lg_table[idx[i]] = @set $(lg_table[idx[i]]).GF  += gls[i]
        lg_table[idx[i]] = @set $(lg_table[idx[i]]).GD   = lg_table[idx[i]].GF  - lg_table[idx[i]].GA
        lg_table[idx[i]] = @set $(lg_table[idx[i]]).Pts  = 3*lg_table[idx[i]].W + lg_table[idx[i]].D
    end
    return nothing
end



"""
    lgrank!(lg_table, ::Val{N}) where {N}

Recalculates the place (ranks) of teams in the league. 

First according to `Pts`, then `GD `and `GF `as tiebreakers.

# Arguments
- `lg_table :: LgTable` : The league table (wins, losses, etc)
- `N        :: Val{N}`  : Number of teams

# Returns
Nothing. Mutates a `LgTable` updated with the latest team rankings.

# See also 
- Uses    : [`LgTable`](@ref)
- Used by : [`playseason!`](@ref)
- Related : [`init_lgtble`](@ref), [`update_lgtble!`](@ref), [`reset_lgtble!`](@ref)
"""
function lgrank!(lg_table, ::Val{N}) where {N}
    pts = MVector{N, Int16}(lg_table[i].Pts for i in eachindex(lg_table))
    gds = MVector{N, Int16}(lg_table[i].GD  for i in eachindex(lg_table))
    gfs = MVector{N, Int16}(lg_table[i].GF  for i in eachindex(lg_table))

    # Pad with one goal to avoid multiplying by zero
    gfs .+= 1

    @inbounds for i in eachindex(lg_table)
        flag1 = (pts .== maximum(pts))
        vals  = ifelse.(flag1, 0, 9999)
        flag2 = (gds .- vals)  .== maximum(gds .- vals)
        flag3 = (gfs .* flag2) .== maximum(gfs .* flag2)
        idx   = findmax(flag3)[2]

        pts[idx] = Int16(-9999)
        gds[idx] = Int16(-9999)
        gfs[idx] = Int16(-9999)
        lg_table[idx] = @set $(lg_table[idx]).Pl = Int16(i)
    end
    return nothing
end



"""
    reset_lgtble!(lg_table, teamnames)

Resets `lg_table` to default/zero values (ie, to play a new season).

# Arguments
- `lg_table  :: LgTable`   : The league table (wins, losses, etc)
- `teamnames :: TeamNames` : Vector of team names

# Returns
Nothing. Mutates a `LgTable` by resetting to default values.

# See also 
- Uses    : [`LgTable`](@ref), [`TeamStats`](@ref), [`TeamNames`](@ref)
- Used by : [`reset_all!`](@ref)
- Related : [`init_lgtble`](@ref), [`update_lgtble!`](@ref), [`lgrank!`](@ref)
"""
function reset_lgtble!(lg_table, teamnames)
    for i in eachindex(lg_table)
        lg_table[i] = TeamStats()
        lg_table[i] = @set $(lg_table[i]).Team = teamnames[i] 
    end
    return nothing
end


"""
    lgtble2df(lg_table)

Converts a `LgTable` to a `DataFrame`.

# Arguments
- `lg_table :: LgTable` : The league table (wins, losses, etc)

# Returns
A `DataFrame` containing the `LgTable`.

# See also 
- Uses    : [`LgTable`](@ref)
- Used by : [`write_lg_table`](@ref)
- Related : [`flatten_rosters`](@ref), [`rost2df`](@ref)

"""
function lgtble2df(lg_table)
    nteams = length(lg_table)
    df     = DataFrame(Pl   = MVector{nteams, Int16}(fill(Int16(0), nteams)), 
                       Team = MVector{nteams, String15}(fill(String15(""), nteams)), 
                       P    = MVector{nteams, Int16}(fill(Int16(0), nteams)), 
                       W    = MVector{nteams, Int16}(fill(Int16(0), nteams)), 
                       D    = MVector{nteams, Int16}(fill(Int16(0), nteams)), 
                       L    = MVector{nteams, Int16}(fill(Int16(0), nteams)), 
                       GF   = MVector{nteams, Int16}(fill(Int16(0), nteams)), 
                       GA   = MVector{nteams, Int16}(fill(Int16(0), nteams)), 
                       GD   = MVector{nteams, Int16}(fill(Int16(0), nteams)), 
                       Pts  = MVector{nteams, Int16}(fill(Int16(0), nteams)))

    fields = fieldnames(TeamStats)
    for i in eachindex(lg_table)
        for j in eachindex(fields)
            df[i, fields[j]] = getfield(lg_table[i], fields[j])
        end
    end
    return df
end


"""
    write_lg_table(fpath, lg_table)

Writes the `lg_table` to a fixed-width file.

# Arguments
- `fpath    :: String`  : Path of the new league table file
- `lg_table :: LgTable` : The league table (wins, losses, etc)

# Returns
Nothing.

# See also 
- Uses    : [`lgtble2df`](@ref)
- Used by : [`FUNC`](@ref)
- Related : [`FUNC`](@ref)
"""
function write_lg_table(fpath, lg_table)
    header_str = ("Pl   Team                    P    W   D   L    GF   GA   GD   Pts",
                  "-----------------------------------------------------------------")

    df = lgtble2df(lg_table)
    df = sort(df, :Pl)

    df.Pl   = padintm5.(df.Pl)
    df.Team = padstrm21.(df.Team)
    df.P    = padint4.(df.P)
    df.D    = padint4.(df.D)
    df.L    = padint4.(df.L)
    df.W    = padint5.(df.W)
    df.GA   = padint5.(df.GA)
    df.GD   = padint5.(df.GD)
    df.GF   = padint6.(df.GF)
    df.Pts  = padint6.(df.Pts)

    @views open(fpath, "w") do file
        println(file, header_str[1])
        println(file, header_str[2])
        for i in 1:size(df)[1]
            println(file, join(df[i, :]))
        end
        println(file, "")
    end
    return nothing
end