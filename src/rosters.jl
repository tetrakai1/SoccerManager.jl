"""
    RosterInfo(nchar, col_end, col_start, header_str, pl_fill)

Immutable struct containing some config values for reading/writing the fixed-width roster files.

# Types
- `T1 <: SVector{25, Int64}`
- `T2 <: SVector{2, String127}`
- `T3 <: SubString{String}`

# Fields
- `nchar      :: T1` : Number of characters for each (fixed-width) column
- `col_end    :: T1` : Index of last character for each column
- `col_start  :: T1` : Index of first character for each column
- `header_str :: T2` : Roster header
- `pl_fill    :: T3` : Placeholder values to pad roster if fewer than MAXPLAYERS

# See also
- Used by : [`ROSTINFO`](@ref), [`parse_roster`](@ref), [`write_roster`](@ref)
- Related : [`TeamSheetConfig`](@ref), [`UpdateConfig`](@ref), [`TacticsConfig`](@ref)
"""
@with_kw struct RosterInfo{T1 <: SVector{25, Int64}, 
                           T2 <: SVector{2, String127},
                           T3 <: SubString{String}}

    nchar      :: T1 = SVector{25, Int64}([13; 3; repeat([4], 2); repeat([3], 6); repeat([4], 15)])
    col_end    :: T1 = cumsum(nchar)
    col_start  :: T1 = col_end - nchar .+ 1
    header_str :: T2 = SVector{2, String127}(["Name         \
                                               Age Nat Prs St Tk Ps Sh Sm Ag KAb TAb PAb SAb \
                                               Gam Sav Ktk Kps Sht Gls Ass  DP Inj Sus Fit",
                                               "---------------------------------------------------\
                                               ---------------------------------------------------"])
    pl_fill    :: T3 = SubString{String}("PLACEHOLDER   00 xxx   C  \
                                          0  0  0  0  0  0 300 300 300 300   \
                                          0   0   0   0   0   0   0   0   0   0 100")
end


"""
    Roster(Name, Age, Nat, Prs, 
           St, Tk, Ps, Sh, Sm, Ag, 
           KAb, TAb, PAb, SAb, 
           Gam, Sav, Ktk, Kps, Sht, Gls, Ass, 
           DP, Inj, Sus, Fit) 

Immutable struct containing the roster of a single team.

# Types
- `T1 <: SVector{MAXPLAYERS, String15}`
- `T2 <: SVector{MAXPLAYERS, Int16}`

# Fields
## Player Info
- `Name :: T1` : Player Name
- `Age  :: T1` : Age
- `Nat  :: T1` : Nationality
- `Prs  :: T1` : Preferred side
## Ratings
- `St   :: T2` : Shot-stopping (Goalkeeping) skill
- `Tk   :: T2` : Tackling skill
- `Ps   :: T2` : Passing skill
- `Sh   :: T2` : Shooting skill
- `Sm   :: T2` : Stamina skill
- `Ag   :: T2` : Aggression skill
## Abilities
- `KAb  :: T2` : Shot-stopping (Goalkeeping) ability
- `TAb  :: T2` : Tackling ability
- `PAb  :: T2` : Passing ability
- `SAb  :: T2` : Shooting ability
## Stats
- `Gam  :: T2` : Games Played
- `Sav  :: T2` : Saves
- `Ktk  :: T2` : Key Tackles
- `Kps  :: T2` : Key Passes
- `Sht  :: T2` : Shots
- `Gls  :: T2` : Goals
- `Ass  :: T2` : Assists
- `DP   :: T2` : Disciplinary Points
- `Inj  :: T2` : Games remaining injured
- `Sus  :: T2` : Games remaining suspended
- `Fit  :: T2` : Fitness (fatigue). Fully rested = 100.

# See also 
- Uses    : [`MAXPLAYERS`](@ref)
- Used by : [`Team`](@ref), [`parse_roster`](@ref), [`update_roster`](@ref), [`write_roster`](@ref),  [`rost2df`](@ref), [`flatten_rosters`](@ref)
- Related : [`Comms`](@ref), [`TeamSheet`](@ref), [`TeamVec`](@ref)
"""
@with_kw struct Roster{T1 <: SVector{MAXPLAYERS, String15}, 
                       T2 <: SVector{MAXPLAYERS, Int16}}
    # Player Info
    Name :: T1 = @SVector fill(String15(""), MAXPLAYERS)
    Age  :: T1 = @SVector fill(String15(""), MAXPLAYERS)
    Nat  :: T1 = @SVector fill(String15(""), MAXPLAYERS)
    Prs  :: T1 = @SVector fill(String15(""), MAXPLAYERS)

    # Ratings
    St   :: T2 = @SVector fill(Int16(0), MAXPLAYERS)
    Tk   :: T2 = @SVector fill(Int16(0), MAXPLAYERS)
    Ps   :: T2 = @SVector fill(Int16(0), MAXPLAYERS)
    Sh   :: T2 = @SVector fill(Int16(0), MAXPLAYERS)
    Sm   :: T2 = @SVector fill(Int16(0), MAXPLAYERS)
    Ag   :: T2 = @SVector fill(Int16(0), MAXPLAYERS)

    # Abilities
    KAb  :: T2 = @SVector fill(Int16(0), MAXPLAYERS)
    TAb  :: T2 = @SVector fill(Int16(0), MAXPLAYERS)
    PAb  :: T2 = @SVector fill(Int16(0), MAXPLAYERS)
    SAb  :: T2 = @SVector fill(Int16(0), MAXPLAYERS)

    # Stats
    Gam  :: T2 = @SVector fill(Int16(0), MAXPLAYERS)
    Sav  :: T2 = @SVector fill(Int16(0), MAXPLAYERS)
    Ktk  :: T2 = @SVector fill(Int16(0), MAXPLAYERS)
    Kps  :: T2 = @SVector fill(Int16(0), MAXPLAYERS)
    Sht  :: T2 = @SVector fill(Int16(0), MAXPLAYERS)
    Gls  :: T2 = @SVector fill(Int16(0), MAXPLAYERS)
    Ass  :: T2 = @SVector fill(Int16(0), MAXPLAYERS)
    DP   :: T2 = @SVector fill(Int16(0), MAXPLAYERS)
    Inj  :: T2 = @SVector fill(Int16(0), MAXPLAYERS)
    Sus  :: T2 = @SVector fill(Int16(0), MAXPLAYERS)
    Fit  :: T2 = @SVector fill(Int16(0), MAXPLAYERS)
end


"""
    read_roster(fname)

Reads a fixed-width roster file into a vector of strings.

# Arguments
- `fpath :: String` : Path to the fixed-width roster file

# Returns
A vector of strings. Each element is a row of the roster.

# See also 
- Uses    : [`FUNC`](@ref)
- Used by : [`parse_roster`](@ref)
- Related : [`readTeamSheet`](@ref)
"""
function read_roster(fpath)
    io = open(fpath, "r")
        seek(io, 206)
        x = read(io, String)
    close(io)

    return split(x[1:(end - 2)], "\n")
end


"""
    get_strvals(strvec, idx, col_start, col_end)

Extracts/parses string columns from a roster file.

# Arguments
- `strvec    :: Vector{String}`     : Vector of strings, each element is a row of the roster
- `idx       :: Int`                : Indices of columns to extract
- `col_start :: SVector{25, Int64}` : Index of first character for each column
- `col_end   :: SVector{25, Int64}` : Index of last character for each column

# Returns
A generator used to extract the string columns.

# See also 
- Used by : [`parse_roster`](@ref)
- Related : [`get_intvals`](@ref)
"""
function get_strvals(strvec, idx, col_start, col_end)
    res = (String15(strvec[j][col_start[idx]:col_end[idx]]) for j in eachindex(strvec))

    return res
end

"""
    get_intvals(strvec, idx, col_start, col_end)

Extracts/parses integer columns from a roster file.

# Arguments
- `strvec    :: Vector{String}`     : Vector of strings, each element is a row of the roster
- `idx       :: Int`                : Indices of columns to extract
- `col_start :: SVector{25, Int64}` : Index of first character for each column
- `col_end   :: SVector{25, Int64}` : Index of last character for each column

# Returns
A generator used to extract the integer columns.

# See also 
- Used by : [`parse_roster`](@ref)
- Related : [`get_strvals`](@ref)
"""
function get_intvals(strvec, idx, col_start, col_end)
    res = (parse(Int16, strvec[j][col_start[idx]:col_end[idx]]) for j in eachindex(strvec))

    return res
end


"""
    parse_roster(fname)

Reads a fixed-width roster file into a `Roster` struct.

# Arguments
- `fname :: String` : Path to the roster file

# Returns
An immutable `Roster` struct, containing the player info for that team.

# See also 
- Uses    : [`RosterInfo`](@ref), [`Roster`](@ref), [`read_roster`](@ref), [`get_strvals`](@ref), [`get_intvals`](@ref)
- Used by : [`init_tv`](@ref)
- Related : [`parse_teamsheet`](@ref), [`parse_tactics`](@ref)
"""
function parse_roster(fname)
    @unpack_RosterInfo ROSTINFO

    # TODO: catch error if > MAXPLAYERS or < NLINEUP
    strvec = read_roster(fname)
    n2fill = MAXPLAYERS - length(strvec)
    strvec = [strvec; fill(pl_fill, n2fill)]

    vals1 = (SVector{MAXPLAYERS}(get_strvals(strvec, idx, col_start, col_end)) for idx in 1:4)
    vals2 = (SVector{MAXPLAYERS}(get_intvals(strvec, idx, col_start, col_end)) for idx in 5:25)

    vals = (vals1..., vals2...)
    roster = Roster(vals...)
    @reset roster.Name = rstrip.(roster.Name)

    return roster
end



"""
    match_comms(roster, comms)

Finds the roster index of the players in comms.

# Arguments
- `roster :: Roster` : An immutable `Roster` struct
- `comm   :: Comms`  : A mutable `Comms` struct

# Returns
A vector of roster indices, each corresponding a player found in comms.

# See also
- Uses    : [`Roster`](@ref), [`Comms`](@ref)
- Used by : [`update_roster`](@ref)
- Related : [`FUNC`](@ref)
"""
function match_comms(roster, comms)
    idx_in = @SVector fill(0, NLINEUP)
    for j in eachindex(comms.Name)
        for i in eachindex(roster.Name)
            if roster.Name[i] == comms.Name[j]
                @reset idx_in[j] = i
                break
            end
        end
    end
    return idx_in
end


"""
    update_roster(roster, comms)

Updates the stats in roster with the game results in comms.

# Arguments
- `roster :: Roster` : An immutable `Roster` struct
- `comms  :: Comms`  : A mutable `Comms` struct

# Returns
A `Roster` struct updated with the data from the last game.

# See also
- Uses    : [`Roster`](@ref), [`Comms`](@ref), [`UpdateConfig`](@ref), [`match_comms`](@ref)
- Used by : [`playgames!`](@ref)
- Related : [`makecomm!`](@ref), [`update_teamsheet`](@ref)
"""
function update_roster(roster, comms)
    @unpack_UpdateConfig UPDATECONF[]

    idx = match_comms(roster, comms)
    DP0 = floor.(roster.DP ./ sus_margin)
    for i in eachindex(idx)
        @reset roster.Gam[idx[i]] += comms.Min[i] > 0
        @reset roster.Sav[idx[i]] += comms.Sav[i]
        @reset roster.Ktk[idx[i]] += comms.Ktk[i]
        @reset roster.Kps[idx[i]] += comms.Kps[i]
        @reset roster.Sht[idx[i]] += comms.Sht[i]
        @reset roster.Gls[idx[i]] += comms.Gls[i]
        @reset roster.Ass[idx[i]] += comms.Ass[i]
        @reset roster.DP[idx[i]]  += comms.Yel[i]*Int16(dp_yel) + comms.Red[i]*Int16(dp_red)
        @reset roster.Inj[idx[i]] += comms.Inj[i]*rand(Int16(0):Int16(max_inj))
        @reset roster.Fit[idx[i]]  = convert(Int16, floor(100 * comms.Fat[i])) 
    end
    DPF    = floor.(roster.DP ./ sus_margin)
    newSus = DPF .> DP0
    @reset roster.Sus += newSus .* Int16.(DPF)

    # Update fitness, etc for next game
    @reset roster.Fit .= min.(Int16(100), roster.Fit .+ Int16(fit_gain))
    @reset roster.Fit .= ifelse.(roster.Inj .== 1, fit_after_inj, roster.Fit)
    @reset roster.Sus .= max.(Int16(0), roster.Sus .- Int16(1))
    @reset roster.Inj  = max.(Int16(0), roster.Inj .- Int16(1))

    # Addressess a bug in the original ESMS
    if any(roster.Sav .> Int16(999)) @reset roster.Sav = min.(roster.Sav, Int16(999)) end
    if any(roster.Ktk .> Int16(999)) @reset roster.Ktk = min.(roster.Ktk, Int16(999)) end
    if any(roster.Kps .> Int16(999)) @reset roster.Kps = min.(roster.Kps, Int16(999)) end
    if any(roster.Sht .> Int16(999)) @reset roster.Sht = min.(roster.Sht, Int16(999)) end
    if any(roster.Gls .> Int16(999)) @reset roster.Gls = min.(roster.Gls, Int16(999)) end

    return roster
end

"""
    reset_roster(roster)

Resets the roster to default values (ie, to play a new season).

# Arguments
- `roster :: Roster` : An immutable `Roster` struct

# Returns
An updated `Roster` struct.

# See also
- Uses    : [`Roster`](@ref)
- Used by : [`reset_all!`](@ref)
- Related : [`reset_lgtble!`](@ref)
"""
function reset_roster(roster)
    statvals = @SVector zeros(Int16, MAXPLAYERS)
    abvals   = @SVector fill(Int16(300), MAXPLAYERS) 

    @reset roster.Gam = statvals
    @reset roster.Sav = statvals
    @reset roster.Ktk = statvals
    @reset roster.Kps = statvals
    @reset roster.Sht = statvals
    @reset roster.Gls = statvals
    @reset roster.Ass = statvals
    @reset roster.DP  = statvals
    @reset roster.Inj = statvals
    @reset roster.Fit = @SVector fill(Int16(100), MAXPLAYERS) 
    @reset roster.KAb = abvals 
    @reset roster.TAb = abvals 
    @reset roster.PAb = abvals 
    @reset roster.SAb = abvals 

    return roster
end


"""
    write_roster(fpath, roster)

Writes the roster to a fixed-width file.

# Arguments
- `fpath  :: String` : Path to the fixed-width roster file
- `roster :: Roster` : An immutable `Roster` struct

# Returns
Nothing.

# See also
- Uses    : [`Roster`](@ref), [`getfield_unroll`](@ref), [`padint3`](@ref), [`padint4`](@ref)
- Used by : [`save_rosters`](@ref)
- Related : [`read_roster`](@ref), [`parse_roster`](@ref), [`write_comms`](@ref), [`write_teamsheet`](@ref)
"""
function write_roster(fpath, roster)
    @unpack_RosterInfo ROSTINFO
    pl_fields = fieldnames(Roster)

    rostvec1 = [getfield_unroll(roster, pl_fields[i]) for i in 1:4]
    rostvec2 = [getfield_unroll(roster, pl_fields[i]) for i in 5:10]
    rostvec3 = [getfield_unroll(roster, pl_fields[i]) for i in 11:25]

    mat        = @MMatrix fill(String15(""), MAXPLAYERS, 26)
    mat[:, 1]  = rostvec1[1]
    mat[:, 2]  = ' '.^(13 .- length.(rostvec1[1]))

    for i in 3:5   mat[:, i] = rostvec1[i - 1]            end
    for i in 6:11  mat[:, i] = padint3.(rostvec2[i - 5])  end
    for i in 12:26 mat[:, i] = padint4.(rostvec3[i - 11]) end

    @views open(fpath, "w") do file
        println(file, header_str[1])
        println(file, header_str[2])
        for i in 1:size(mat)[1]
            println(file, join(mat[i, :]))
        end
        println(file, "")
    end
    return nothing
end


"""
    save_rosters(fpaths, tv)

Writes all the rosters in a league to fixed-width files.

# Arguments
- `fpaths :: Vector{String}` : Paths to the fixed-width roster files
- `tv     :: TeamVec`        : Contains `Roster`, `TeamSheet`, and `Comms` structs for each team

# Returns
Nothing.

# See also
- Uses    : [`write_roster`](@ref)
- Used by : [`FUNC`](@ref)
- Related : [`FUNC`](@ref)
"""
function save_rosters(fpaths, tv)
    @multi for i in eachindex(fpaths)
        write_roster(fpaths[i], tv[i].roster)
    end
    return nothing
end


"""
    rost2df(roster)

Converts a Roster struct to a `DataFrame`.

# Arguments
- `roster :: Roster` : An immutable `Roster` struct

# Returns
A `DataFrame` containing the roster data.

# See also
- Uses    : [`Roster`](@ref), [`getfield_unroll`](@ref)
- Used by : [`FUNC`](@ref)
- Related : [`flatten_rosters`](@ref), [`lgtble2df`](@ref)
"""
function rost2df(roster)
    fields  = SVector(fieldnames(Roster))
    rostvec = [getfield_unroll(roster, fields[i]) for i in eachindex(fields)]

    return DataFrame(rostvec, fields)
end


"""
    flatten_rosters(lg_data, N)

Flattens all the rosters in the `TeamVec` into a single `DataFrame`.

# Arguments
- `lg_data :: LeagueData` : Contains all the player and team-level info for the league
- `N       :: Val{N}`     : The number of teams

# Returns
A `DataFrame` with one player from the league in each row.

# See also
- Uses    : [`LeagueData`](@ref), [`Roster`](@ref), [`getfield_unroll`](@ref), [`MAXPLAYERS`](@ref)
- Used by : [`FUNC`](@ref)
- Related : [`rost2df`](@ref), [`lgtble2df`](@ref)
"""
function flatten_rosters(lg_data, ::Val{N}) where {N}
    tv        = lg_data.tv
    teamnames = lg_data.teamnames

    fields = SVector(fieldnames(Roster))
    T1     = SVector{N, SVector{MAXPLAYERS, String15}}
    T2     = SVector{N, SVector{MAXPLAYERS, Int16}}
    T      = [fill(T1, 4); fill(T2, 21)]

    rostvec = [reduce(vcat, T[j](getfield_unroll(tv[i].roster, fields[j]) for i in 1:N)) for j in 1:25]

    df = DataFrame(rostvec, fields)
    insertcols!(df, 1, :Team => repeat(teamnames, inner = MAXPLAYERS))

    return df
end
