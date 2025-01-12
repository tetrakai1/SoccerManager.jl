"""
    Comms(Name, Pos, Prs,
          St, Tk, Ps, Sh, Sm, Ag,
          Ded, Act, Fat,
          Sh0, Ps0, Tk0, Shm, Psm, Tkm, 
          Gam, Sav, Ktk, Kps, Sht, Gls, Ass, DP , Inj, Sus, Fit,
          KAb, TAb, PAb, SAb,
          Pk, Gk, Tactic, SubCnt, Wts)

Mutable struct containing the commentary (game) data for a single team.

# Types
- `T1 <: SVector{NLINEUP, String15}`
- `T2 <: SVector{NLINEUP, Int16}`
- `T3 <: SVector{NLINEUP, Float32}`
- `T4 <: SVector{NLINEUP, Bool}`

# Fields
## Player Info
- `Name :: T1` : Player Name
- `Pos  :: T1` : Position
- `Prs  :: T1` : Preferred side
## Ratings
- `St   :: T2` : Shot-stopping (Goalkeeping) skill
- `Tk   :: T2` : Tackling skill
- `Ps   :: T2` : Passing skill
- `Sh   :: T2` : Shooting skill
- `Sm   :: T2` : Stamina skill
- `Ag   :: T2` : Aggression skill
## Fatigue Deduction
- `Ded  :: T3` : Fatigue Deduction
## Current State
- `Act  :: T4` : Currently active flag
- `Fat  :: T3` : Fatigue
## Ratings * sidefactor * tacticsmult
- `Sh0  :: T3` : Contribution to team shooting (before fatigue)
- `Ps0  :: T3` : Contribution to team passing  (before fatigue)
- `Tk0  :: T3` : Contribution to team takling  (before fatigue)
## Ratings * sidefactor * tacticsmult * fatigue
- `Shm  :: T3` : Contribution to team shooting (after fatigue)
- `Psm  :: T3` : Contribution to team passing  (after fatigue)
- `Tkm  :: T3` : Contribution to team takling  (after fatigue)
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
## Abilities
- `KAb  :: T2` : Shot-stopping (Goalkeeping) ability
- `TAb  :: T2` : Tackling ability
- `PAb  :: T2` : Passing ability
- `SAb  :: T2` : Shooting ability
## Penalty Kicker, Current Goal Keeper, and Tactic
- `Pk     :: Int`      : Index of penalty kicker
- `Gk     :: Int`      : Index of goalkeeper
- `Tactic :: String15` : Team tactic
## Num subs used and preallocated weight vector
- `SubCnt :: Int`      : Number of subsitutions so far during the game
- `Wts    :: Weights`  : Reusable Weights for weighted sampling of players (who takes a shot, etc)

# See also 
- Uses    : [`NLINEUP`](@ref)
- Used by : [`Team`](@ref), [`init_tv`](@ref) 
- Related : [`Roster`](@ref), [`TeamSheet`](@ref), [`TeamVec`](@ref)
"""
@with_kw mutable struct Comms{T1 <: SVector{NLINEUP, String15}, 
                              T2 <: SVector{NLINEUP, Int16},
                              T3 <: SVector{NLINEUP, Float32},
                              T4 <: SVector{NLINEUP, Bool}}
    # Player Info
    Name :: T1 = @SVector fill(String15(""), NLINEUP)
    Pos  :: T1 = @SVector fill(String15(""), NLINEUP)
    Prs  :: T1 = @SVector fill(String15(""), NLINEUP)

    # Ratings
    St :: T2 = @SVector fill(Int16(0), NLINEUP)
    Tk :: T2 = @SVector fill(Int16(0), NLINEUP)
    Ps :: T2 = @SVector fill(Int16(0), NLINEUP)
    Sh :: T2 = @SVector fill(Int16(0), NLINEUP)
    Sm :: T2 = @SVector fill(Int16(0), NLINEUP)
    Ag :: T2 = @SVector fill(Int16(0), NLINEUP)

    # Fatigue Deduction
    Ded :: T3 = @SVector fill(Float32(0), NLINEUP)

    # Current State
    Act :: T4 = @SVector fill(Bool(0),    NLINEUP)
    Fat :: T3 = @SVector fill(Float32(0), NLINEUP)

    # Ratings * sidefactor * tacticsmult
    Sh0 :: T3 = @SVector fill(Float32(0), NLINEUP)
    Ps0 :: T3 = @SVector fill(Float32(0), NLINEUP)
    Tk0 :: T3 = @SVector fill(Float32(0), NLINEUP)

    # Ratings * sidefactor * tacticsmult * fatigue
    Shm :: T3 = @SVector fill(Float32(0), NLINEUP)
    Psm :: T3 = @SVector fill(Float32(0), NLINEUP)
    Tkm :: T3 = @SVector fill(Float32(0), NLINEUP)

    # Stats
    Min :: T2 = @SVector fill(Int16(0), NLINEUP)
    Sav :: T2 = @SVector fill(Int16(0), NLINEUP)
    Ktk :: T2 = @SVector fill(Int16(0), NLINEUP)
    Kps :: T2 = @SVector fill(Int16(0), NLINEUP)
    Sht :: T2 = @SVector fill(Int16(0), NLINEUP)
    Gls :: T2 = @SVector fill(Int16(0), NLINEUP)
    Ass :: T2 = @SVector fill(Int16(0), NLINEUP)
    Yel :: T2 = @SVector fill(Int16(0), NLINEUP)
    Red :: T4 = @SVector fill(Bool(0),  NLINEUP)
    Inj :: T4 = @SVector fill(Bool(0),  NLINEUP)
    Fit :: T2 = @SVector fill(Int16(0), NLINEUP)

    # Abilities
    Kab :: T2 = @SVector fill(Int16(0), NLINEUP)
    Tab :: T2 = @SVector fill(Int16(0), NLINEUP)
    Pab :: T2 = @SVector fill(Int16(0), NLINEUP)
    Sab :: T2 = @SVector fill(Int16(0), NLINEUP)

    # Penalty Kicker, Current Goal Keeper, and Tactic
    Pk      :: Int64 = Int64(11)
    Gk      :: Int64 = Int64(1)
    Tactic  :: String15 = String15("N")

    # Num subs used and preallocated weight vector
    SubCnt  :: Int64   = Int64(0)
    Wts     :: Weights = Weights(@SVector fill(0.0, NLINEUP))
end

"""
    match_teamsheet(roster, teamsheet)

Finds the `roster` index of the players in `teamsheet`.

# Arguments
- `roster  :: Roster`    : An immutable `Roster` struct
- `teamsheet :: TeamSheet` : An immutable `TeamSheet` struct

# Returns
A vector of `roster` indices, each corresponding a player found in `teamsheet`.

# See also
- Uses    : [`Roster`](@ref), [`TeamSheet`](@ref), [`NLINEUP`](@ref) 
- Used by : [`makecomm!`](@ref)
- Related : [`match_comms`](@ref)
"""
function match_teamsheet(roster, teamsheet)
    idx_in = @SVector fill(0, NLINEUP)
    tsvec  = SVector{NLINEUP, String15}([teamsheet.StartName; teamsheet.SubName])
    for j in eachindex(tsvec)
        for i in eachindex(roster.Name)
            if roster.Name[i] == tsvec[j]
                @reset idx_in[j] = i
                break
            end
        end
    end
    return idx_in
end

"""
    makecomm!(comm0, roster, teamsht)

Uses roster and teamsht to populate comms0. 

The `Comms` struct then be updated throughout the game.

# Arguments
- `comm0   :: Comms`     : A mutable `Comms` struct
- `roster  :: Roster`    : An immutable `Roster` struct
- `teamsht :: TeamSheet` : An immutable `Teamsheet` struct

# Returns
Nothing. Mutates a `Comms` struct to contain the players in the `TeamSheet`.

# See also
- Uses    : [`Comms`](@ref), [`Roster`](@ref), [`TeamSheet`](@ref), [`match_teamsheet`](@ref) 
- Used by : [`playgame!`](@ref), [`reset_all!`](@ref)
- Related : [`update_roster`](@ref), [`update_teamsheet`](@ref)
"""
function makecomm!(comm0, roster, teamsheet)
    idx = match_teamsheet(roster, teamsheet)

    # Player Info
    comm0.Name = roster.Name[idx]
    comm0.Pos  = [teamsheet.StartPos; teamsheet.SubPos]
    comm0.Prs  = roster.Prs[idx]

    # Ratings
    comm0.St = roster.St[idx]
    comm0.Tk = roster.Tk[idx]
    comm0.Ps = roster.Ps[idx]
    comm0.Sh = roster.Sh[idx]
    comm0.Sm = roster.Sm[idx]
    comm0.Ag = roster.Ag[idx]

    # Fatigue Deduction (GK start at first index, and do not fatigue)
    comm0.Ded = 0.0031f0 .- 0.0022f0 .* Float32.(comm0.Sm .- 50) ./ 50f0
    comm0.Ded = @set $(comm0.Ded)[1] = 0.0f0

    # Current State
    comm0.Act = SVector{16, Bool}([@SVector ones(11); @SVector zeros(5)])
    comm0.Fat = roster.Fit[idx] ./ 100f0

    # Ratings * sidefactor * tacticsmult
    comm0.Sh0 = comm0.Sh
    comm0.Ps0 = comm0.Ps
    comm0.Tk0 = comm0.Tk

    # Stats
    comm0.Min = @SVector fill(Int16(0),   length(comm0.Name))
    comm0.Sav = @SVector fill(Int16(0),   length(comm0.Name))
    comm0.Ktk = @SVector fill(Int16(0),   length(comm0.Name))
    comm0.Kps = @SVector fill(Int16(0),   length(comm0.Name))
    comm0.Sht = @SVector fill(Int16(0),   length(comm0.Name))
    comm0.Gls = @SVector fill(Int16(0),   length(comm0.Name))
    comm0.Ass = @SVector fill(Int16(0),   length(comm0.Name))
    comm0.Yel = @SVector fill(Int16(0),   length(comm0.Name))
    comm0.Red = @SVector fill(Bool(0),    length(comm0.Name))
    comm0.Inj = @SVector fill(Bool(0),    length(comm0.Name))
    comm0.Fit = @SVector fill(Int16(100), length(comm0.Name))

    # Penalty Kicker, Current Goal Keeper, and Tactic
    comm0.Pk     = findfirst(teamsheet.PK .== comm0.Name)
    comm0.Gk     = Int64(1)
    comm0.Tactic = teamsheet.Tactic

    # Num subs used
    comm0.SubCnt = Int64(0)

    return nothing
end

"""
    calc_contribs!(comm, oppcomm)

Calculates the contributions of each player in comm. 

The contributions are the ratings adjusted for tactics, position, and fatigue. The fatigue adjustment is performed during the game loop by `recalc_data!`.

# Arguments
- `comm    :: Comms` : Current team's `Comms` struct
- `oppcomm :: Comms` : Opposing team's `Comms` struct

# Returns
Nothing. Mutates a `Comms` struct to contain adjusted contributions for each player.

# See also
- Uses    : [`Comms`](@ref), [`update_sidefactor!`](@ref), [`update_tactmult!`](@ref), [`update_bonus!`](@ref)
- Used by : [`playgame!`](@ref)
- Related : [`recalc_data!`](@ref)
"""
function calc_contribs!(comm, oppcomm)
    side_balance!(comm)
    for i in eachindex(comm.Name) update_sidefactor!(comm, i) end
    for i in eachindex(comm.Name) update_tactmult!(comm, i, comm.Tactic) end
    for i in eachindex(comm.Name) update_bonus!(comm, comm.Tactic, oppcomm.Tactic, i) end

    # Set GK contribs to zero
    comm.Sh0 = @set $(comm.Sh0)[comm.Gk] = 0f0
    comm.Ps0 = @set $(comm.Ps0)[comm.Gk] = 0f0
    comm.Tk0 = @set $(comm.Tk0)[comm.Gk] = 0f0

    return nothing
end


"""
    side_balance!(comm)

Adjusts the contribution of each player using the side balance at that position. 

Side balance is the number of players with the same position on the R, C, or L side of the field. Players are
penalized if the number of R players != to number of L players, or if there are >3 players in the center with 
none on the R or L sides.

# Arguments
- `comm :: Comms` : A mutable `Comms` struct

# Returns
Nothing. Mutates a `Comms` struct to contain adjusted contributions for each player.

# See also
- Uses    : [`Comms`](@ref), [`NLINEUP`](@ref)
- Used by : [`calc_contribs!`](@ref)
- Related : [`update_tactmult!`](@ref), [`update_bonus!`](@ref), [`update_sidefactor!`](@ref)
"""
function side_balance!(comm)
    upos = SVector{5, String15}("DF", "DM", "MF", "AM", "FW")
    side = SVector{NLINEUP, String15}(comm.Pos[i][3:3] for i in eachindex(comm.Pos))
    pos  = SVector{NLINEUP, String15}(comm.Pos[i][1:2] for i in eachindex(comm.Pos))

    for j in eachindex(upos)
        pos_flag = (pos .== upos[j]) .* comm.Act
        if sum(pos_flag) > 1
            nR = sum(pos_flag .* (side .== "R"))
            nL = sum(pos_flag .* (side .== "L"))
            nC = sum(pos_flag .* (side .== "C"))

            mult = 1f0
            if nR != nL
                mult = 1f0 - 0.25f0*abs(nR - nL)/(nR + nL)
            elseif nC > 3 && nR == 0 && nL == 0
                mult = 0.87f0
            end

            comm.Sh0 = @set $(comm.Sh0) .*= ifelse.(pos_flag, mult, 1f0)
            comm.Ps0 = @set $(comm.Ps0) .*= ifelse.(pos_flag, mult, 1f0)
            comm.Tk0 = @set $(comm.Tk0) .*= ifelse.(pos_flag, mult, 1f0)
        end
    end
end

"""
    update_sidefactor!(comm, idx)

Adjusts the contribution of the player using their preferred side. 

Eg, a player that prefers R will be penalized when playing on C or R sides.

# Arguments
- `comm :: Comms` : A mutable `Comms` struct
- `idx  :: Int`   : Index of the player in comm

# Returns
Nothing. Mutates a `Comms` struct to contain adjusted contributions for that player.

# See also
- Uses    : [`Comms`](@ref)
- Used by : [`calc_contribs!`](@ref), [`update_sub!`](@ref)
- Related : [`update_tactmult!`](@ref), [`update_bonus!`](@ref), [`side_balance!`](@ref)
"""
function update_sidefactor!(comm, idx)
    side     = comm.Pos[idx][3]
    likeside = comm.Prs[idx]

    # GK is always skipped due to the space (ie, "GK "[3] in " RLC")
    if !in(side, likeside)
        comm.Sh0 = @set $(comm.Sh0)[idx] *= 0.75f0
        comm.Ps0 = @set $(comm.Ps0)[idx] *= 0.75f0
        comm.Tk0 = @set $(comm.Tk0)[idx] *= 0.75f0
    end
    return nothing
end

"""
    write_comms(comms, path_xxxx, tnames)

Writes the game results (comms) to a file.

The file contains a minute-by-minute game log, a fixed-width table for each `Comms`, and is named `tname[1]_tname[2].txt`

# Arguments
- `comm   :: Comms`          : A mutable `Comms` struct
- `dir    :: String`         : Path to the directory where the file is saved
- `tnames :: Vector{String}` : A vector containing the names of the two teams

# Returns
Nothing.

# See also
- Uses    : [`Comms`](@ref)
- Used by : [`FUNC`](@ref)
- Related : [`write_roster`](@ref)
"""
function write_comms(comms, dir, tnames)
    commname = tnames[1]*"_"*tnames[2]*".txt"
    fname    = joinpath(dir, commname)
    sel      = SVector{20}(:St, :Tk, :Ps, :Sh, :Sm, 
                           :Min, :Sav, :Ktk, :Kps, :Ass, :Sht, :Gls, :Yel, :Red, :Inj,
                           :Kab, :Tab, :Pab, :Sab, :Fit)

    msgstr     = ["Game log goes here"]
    header_str = ["Name          \
                   Pos Prs St Tk Ps Sh Sm | \
                   Min Sav Ktk Kps Ass Sht Gls Yel Red Inj \
                   KAb TAb PAb SAb Fit",
                   "---------------------------------------------------\
                   -----------------------------------------------"]


    open(fname, "w") do file
        # Game Log placeholder
        println(file, msgstr)
        for _ in 1:10
            println.(file, "", header_str[1], "\n", header_str[2])
        end
        println(file, "\n\n")

        mat = @MMatrix fill(String15(""), length(comm.Name), 25)
        for i in 1:2
            comm = comms[i]
            # Second column is adding back padding for Name and Pos columns
            mat[:, 1]   = comm.Name
            mat[:, 2]   = ' '.^(14 .- length.(comm.Name))
            mat[:, 3]   = comm.Pos
            mat[:, 4]   = comm.Prs
            mat[:, 10] .= @SVector fill(" |", length(comm.Name))
            cnt = 1 
            for i in 5:9
                mat[:, i] = padint3.(getfield_unroll(comm, sel[cnt]))
                cnt += 1
            end
            for i in 11:24
                mat[:, i] = padint4.(getfield_unroll(comm, sel[cnt]))
                cnt += 1
            end
            mat[:, 25] = padint4.(convert.(Int16, floor.(100 .* comm.Fat)))


            statsums = SVector{9, Int16}(sum(getfield_unroll(comm, sel[i])) for i in 7:15)
            title_str  = "<<< Player statistics for: $(tnames[i]) >>>"*"\n"
            footer_str = "-- Total --                               "*
                         join(padint4.(statsums))*"\n"
    
    
            println(file, title_str, "\n", header_str[1], "\n", header_str[2])
            @views for j in 1:size(mat)[1]
                    println(file, join(mat[j, :]))
            end
            println(file, footer_str, "\n")

            if i == 2
                println(file, "\n")
            end
        end
    end
    return nothing
end
