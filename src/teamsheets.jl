"""
    TeamSheet(StartName, StartPos, SubName, SubPos, PK, Tactic)

Immutable struct containing the teamsheet for a single team.

# Types
- `T1 <: SVector{11, String15}`
- `T2 <: SVector{NSUBS, String15}`

# Fields
- `StartName :: T1`       : Names of the starting players
- `StartPos  :: T1`       : Positions of the starting players
- `SubName   :: T2`       : Names of the sub players
- `SubPos    :: T2`       : Positions of the sub players
- `PK        :: String15` : Name of the designated penalty kicker
- `Tactic    :: String15` : Tactic used by the team

# See also 
- Uses    : [`NSUBS`](@ref)
- Used by : [`Team`](@ref), [`parse_teamsheet`](@ref), [`update_teamsheet`](@ref)
- Related : [`Roster`](@ref), [`Comms`](@ref), [`TeamVec`](@ref)
"""
@with_kw struct TeamSheet{T1 <: SVector{11, String15}, 
                          T2 <: SVector{NSUBS, String15}}
    StartName :: T1 = @SVector fill(String15(""), 11)
    StartPos  :: T1 = @SVector fill(String15(""), 11)
    SubName   :: T2 = @SVector fill(String15(""), NSUBS)
    SubPos    :: T2 = @SVector fill(String15(""), NSUBS)
    PK        :: String15 = String15("")
    Tactic    :: String15 = String15("")
end


"""
    readTeamSheet(fpath)

Reads a fixed-width teamsheet file into a vector of strings.

# Arguments
- `fpath :: String` : Path to the fixed-width teamsheet file

# Returns
A vector of strings. Each element is a row of the teamsheet.

# See also
- Uses    : [`FUNC`](@ref)
- Used by : [`parse_teamsheet`](@ref)
- Related : [`read_roster`](@ref)
"""
function readTeamSheet(fpath)
    io = open(fpath, "r")
        x = read(io, String)
    close(io)

    return split(x[1:(end - 2)], "\n")
end

"""
    parse_teamsheet(fpath)

Reads a fixed-width teamsheet file into a `TeamSheet` struct.

# Arguments
- `fpath :: String` : Path to the fixed-width teamsheet file

# Returns
An immutable `TeamSheet` struct, containing the lineup and tactics for that team.

# See also
- Uses    : [`readTeamSheet`](@ref), [`TeamSheet`](@ref), [`NSUBS`](@ref)
- Used by : [`init_tv`](@ref)
- Related : [`parse_roster`](@ref), [`parse_tactics`](@ref)
"""
function parse_teamsheet(fpath)
    tsDat = readTeamSheet(fpath)

    vals1 = SVector{11}((String15(tsDat[i][1:3]) for i in 4:14))
    idx1  = ifelse.(vals1 .== "GK ", 4, 5)
    vals2 = SVector{11}((String15(tsDat[i][idx1[i - 3]:end]) for i in 4:14))
    
    vals3 = SVector{NSUBS}((String15(tsDat[i][1:3]) for i in 16:(15 + NSUBS)))
    idx2  = ifelse.(vals3 .== "GK ", 4, 5)
    vals4 = SVector{NSUBS}((String15(tsDat[i][idx2[i - 15]:end]) for i in 16:(15 + NSUBS)))

    vals5 = String15(tsDat[22][5:end])
    vals6 = String15(tsDat[2][1:1])

    vals = (vals2, vals1, vals4, vals3, vals5, vals6)

    return TeamSheet(vals...)
end

"""
    ordinal_rank(ratings, fitness)

Ranks player ratings after adjusting for fitness/fatigue.

Implemented using `SVectors` for performance. See `StatsBase.ordinalrank`.

# Arguments
- `ratings :: SVector{Int16}` : A vector of player ratings
- `fitness :: SVector{Int16}` : A vector of player fitness

# Returns
An `SVector{Int64}` of ranks. Lower value = higher rank.

# See also
- Uses    : [`FUNC`](@ref)
- Used by : [`calc_ranks`](@ref), [`update_teamsheet`](@ref)
- Related : [`Roster`](@ref), [`chooseranks`](@ref)
"""
function ordinal_rank(ratings, fitness)
    rnks = @SVector fill(Int64(0), length(ratings))
    for i in eachindex(rnks)
        idx = findmax(ratings .* fitness)[2]
        @reset rnks[i]            = idx
        @reset fitness[idx] = 0
    end
    return rnks
end

"""
    calc_ranks(roster, fitness)

Ranks multiple player skill ratings in a `Roster` after adjusting each for fitness/fatigue.

In particular, it ranks the following elements of the roster:

- St = Shot-stopping (Goalkeeing)
- Tk = Tackling
- Ps = Passing
- Sh = Shooting

# Arguments
- `roster  :: Roster`         : An immutable `Roster` struct
- `fitness :: SVector{Int16}` : A vector of player fitness

# Returns
A named tuple of the rankings for each skill.

# See also
- Uses    : [`Roster`](@ref), [`ordinal_rank`](@ref)
- Used by : [`update_teamsheet`](@ref)
- Related : [`Roster`](@ref), [`chooseranks`](@ref)
"""
function calc_ranks(roster, fitness)
    st = ordinal_rank(roster.St, fitness)
    tk = ordinal_rank(roster.Tk, fitness)
    ps = ordinal_rank(roster.Ps, fitness)
    sh = ordinal_rank(roster.Sh, fitness)

    return (st = st, tk = tk, ps = ps, sh = sh)
end

"""
    chooseranks(pos, rnks)

Chooses which skill ranks to use based on the position.

In particular:
- GK : St (Shot-stopping)
- DF : Tk (Tackling)
- MF : PS (Passing)
- FW : Sh (Shooting)

Other positions default to Ps (Passing).

# Arguments
- `pos  :: String15`                   : The position
- `rnks :: NamedTuple{SVector{Int16}}` : `NamedTuple` of skill ranks

# Returns
An `SVector{Int64}` of ranks. Lower value = higher rank.

# See also
- Uses    : [`FUNC`](@ref)
- Used by : [`update_teamsheet`](@ref)
- Related : [`calc_ranks`](@ref), [`ordinal_rank`](@ref)
"""
function chooseranks(pos, rnks)
    rnk = ifelse(pos == "GK", rnks.st,
                  ifelse(pos == "DF", rnks.tk,
                         ifelse(pos == "MF", rnks.ps,
                                ifelse(pos == "FW", rnks.sh, rnks.ps))))
    return rnk
end

"""
    update_teamsheet(roster; tactic = N)

Updates a teamsheet based on the skill ratings, fitness, and availability (injury/suspension) in the roster.

Defaults to side = Center, like in ESMS.

# Arguments
- `roster :: Roster` : An immutable `Roster` struct

# Kwargs
- `tactic :: String` : The team tactic. Defaults to `N` (Normal)

# Returns
An immutable `TeamSheet` struct based on the current roster.

# See also
- Uses    : [`Roster`](@ref), [`TeamSheetConfig`](@ref), [`TeamSheet`](@ref), [`ordinal_rank`](@ref), [`calc_ranks`](@ref), [`chooseranks`](@ref)
- Used by : [`playgames!`](@ref), [`init_tv`](@ref), [`reset_all!`](@ref)
- Related : [`makecomm!`](@ref), [`update_roster`](@ref)
"""
function update_teamsheet(roster; tactic = "N")
    @unpack_TeamSheetConfig TSCONF[]

    teamsheet     = TeamSheet()
    avail_fitness = roster.Fit .* (roster.Inj .== 0) .* (roster.Sus .== 0)

    # Choose best shooter as penalty kicker
    @reset teamsheet.PK = roster.Name[ordinal_rank(roster.Sh, avail_fitness)[1]]

    # Set tactic
    @reset teamsheet.Tactic = tactic

    cnt1 = 1
    cnt2 = 1
    for j in eachindex(Pos)
        pos  = Pos[j]
        rnks = calc_ranks(roster, avail_fitness)
        choserank = chooseranks(pos, rnks)

        nstart = Nstarters[j]
        ntot   = nstart + Nsubs[j]
        # Choose starters
        for i in 1:nstart
            idx = choserank[i]
            @reset teamsheet.StartName[cnt1] = roster.Name[idx]
            # @reset teamsheet.StartPos[cnt1]  = pos*roster.Prs[idx][4:4]
            @reset teamsheet.StartPos[cnt1]  = pos*ifelse(j == 1, String15(" "), String15("C"))
            @reset avail_fitness[idx]        = 0
            cnt1 += 1
        end
        # Choose subs
        for i in (nstart + 1):ntot
            idx = choserank[i]
            @reset teamsheet.SubName[cnt2] = roster.Name[idx]
            @reset teamsheet.SubPos[cnt2]  = pos*ifelse(j == 1, String15(" "), String15("C"))
            @reset avail_fitness[idx]      = 0
            cnt2 += 1
        end
    end

    return teamsheet
end

"""
    write_teamsheet(fpath, teamsheet)

Writes the teamsheet to a fixed-width file.

# Arguments
- `fpath     :: String`    : Path to the fixed-width teamsheet file
- `teamsheet :: TeamSheet` : An immutable `TeamSheet` struct

# Returns
Nothing.

# See also
- Uses    : [`TeamSheet`](@ref)
- Used by : [`FUNC`](@ref)
- Related : [`write_roster`](@ref), [`write_comms`](@ref)
"""
function write_teamsheet(fpath, teamsheet)
    str1 = ifelse.(teamsheet.StartPos .== "GK ", String15(""), String15(" "))
    str2 = ifelse.(teamsheet.SubPos   .== "GK ", String15(""), String15(" "))
    mat1 = teamsheet.StartPos .* str1 .* teamsheet.StartName
    mat2 = teamsheet.SubPos   .* str2 .* teamsheet.SubName

    open(fpath, "w") do file
        write(file, teamname*"\n")
        write(file, teamsheet.Tactic*"\n")
        write(file, "\n")
        for i in 1:size(mat1)[1]
            write(file, mat1[i]*"\n")
        end
        write(file, "\n")
        for i in 1:size(mat2)[1]
            write(file, mat2[i]*"\n")
        end
        write(file, "\n")
        write(file, "PK: "*rstrip(teamsheet.PK)*"\n")
        write(file, "\n")
    end
    return nothing
end


