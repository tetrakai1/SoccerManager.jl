"""
    playseason!(lg_data)

Play a season of games and store the results in `lg_data`. 

Automated `TeamSheet` selection is done after each game.

# Arguments
- `lg_data :: LeagueData` : Contains all the player and team-level info for the league

# Returns
Nothing. Mutates the `TeamVec` and `LgTable` vectors in `lg_data` after each game.

# See also 
- Uses    : [`LeagueData`](@ref), [`playgames!`](@ref), [`lgrank!`](@ref)
- Used by : [`FUNC`](@ref)
- Related : [`playgame!`](@ref)

"""
function playseason!(lg_data)
    @unpack_LeagueData lg_data
    for wk in eachindex(schedule)
        playgames!(lg_data, schedule[wk])
    end
    lgrank!(lg_table, Val(length(lg_table)))

    return nothing
end


"""
    playgames!(lg_data, wk_sched)

Play a week of games and store the results in `lg_data`. 

Performs automated `TeamSheet` selection after each game.

# Arguments
- `lg_data  :: LeagueData`    : Contains all the player and team-level info for the league
- `wk_sched :: Matrix{Int16}` : The schedule of matches for this week

# Returns
Nothing. Mutates the `TeamVec` and `LgTable` vectors in `lg_data` after each game.

# See also 
- Uses    : [`LeagueData`](@ref), [`playgame!`](@ref), [update_lgtble!](@ref), [`update_roster`](@ref), [`update_teamsheet`](@ref)
- Used by : [`playseason!`](@ref)
- Related : [`FUNC`](@ref)
"""
function playgames!(lg_data, wk_sched)
    @unpack_LeagueData lg_data
    @multi for idx in eachrow(wk_sched)
        idx1 = idx[1]
        idx2 = idx[2]

        playgame!(tv, idx1, idx2)
        comms = (tv[idx1].comm, tv[idx2].comm)

        update_lgtble!(lg_table, comms, idx1, idx2)
        for j in 1:2
            tv[idx[j]].roster  = update_roster(tv[idx[j]].roster, comms[j])
            tv[idx[j]].teamsht = update_teamsheet(tv[idx[j]].roster; tactic = "N")
        end
    end
    return nothing
end


"""
    playgame!(tv, idx1, idx2)

Play a single game between two teams. 

Stores the results in the corresponding `Comms` of `tv`.

# Arguments
- `tv   :: TeamVec` : Contains `Roster`, `TeamSheet`, and `Comms` structs for each team
- `idx1 :: Int`     : The index of the home team in tv
- `idx2 :: Int`     : The index of the away team in tv

# Returns
Nothing. Mutates the `TeamVec` vector.

# See also 
- Uses    : [`makecomm!`](@ref), [`calc_contribs!`](@ref), [`mainloop!`](@ref)
- Used by : [`playgames!`](@ref)
- Related : [`playseason!`](@ref)
"""
function playgame!(tv, idx1, idx2)
    makecomm!(tv[idx1].comm, tv[idx1].roster, tv[idx1].teamsht)
    makecomm!(tv[idx2].comm, tv[idx2].roster, tv[idx2].teamsht)

    comm1 = tv[idx1].comm
    comm2 = tv[idx2].comm

    calc_contribs!(comm1, comm2)
    calc_contribs!(comm2, comm1)

    # Same weights vector can be used for both teams
    mainloop!(comm1, comm2, comm1.Wts)

    return nothing
end


"""
    mainloop!(comm1, comm2, wts)

Main game loop. 

Plays a match one minute at a time and updates values in the `Comms` structs.

# Arguments
- `comm1 :: Comms`   : Home team's `Comms` struct
- `comm2 :: Comms`   : Away team's `Comms` struct
- `wts   :: Weights` : Reusable `Weights` for weighted sampling of players (who takes a shot, etc)

# Returns
Nothing. Mutates `Comms` elements of the `TeamVec` vector.

# See also 
- Uses    : [`Comms`](@ref), [`recalc_data!`](@ref), [`if_shot!`](@ref), [`if_foul!`](@ref), [`rand_injury!`](@ref)
- Used by : [`playgame!`](@ref)
- Related : [`FUNC`](@ref)
"""
function mainloop!(comm1, comm2, wts)
    for t in 1:90
        # Recalculate contributions based on current fatigue/activity
        recalc_data!(comm1);
        recalc_data!(comm2);

        # Home Team
        if_shot!(comm1, comm2, true, wts)
        if_foul!(comm1, comm2, wts)
        rand_injury!(comm1, comm2, wts)

        # Away Team
        if_shot!(comm2, comm1, false, wts)
        if_foul!(comm2, comm1, wts)
        rand_injury!(comm2, comm1, wts)

        # End game early if less than 7 active players
        if(sum(comm1.Act) < 7 || sum(comm2.Act) < 7)
            break
        end
    end
    return nothing
end



"""
    rand_fat32(N)

Generates a vector of random values for fatigue adjustment.

# Arguments
- `N::Int` : Length of the vector

# Returns
A vector of negatively biased random `Float32` values.

# See also 
- Uses    : [`FUNC`](@ref)
- Used by : [`recalc_data!`](@ref)
- Related : [`FUNC`](@ref)
"""
@inline function rand_fat32(N)
    vec = @SVector rand(Float32, N)

    return vec .* 0.006f0 .- 0.003f0
end


"""
    recalc_data!(comm)

Updates time played and fatigue level for each player after each minute of the game. 

This is used to adjust contributions to the team's shot, passing, and tackle skill.

# Arguments
- `comm :: Comms` : The `Comms` struct of the team to be updated

# Returns
Nothing. Mutates `Comms` elements of the `TeamVec` vector.

# See also 
- Uses    : [`Comms`](@ref), [`rand_fat32`](@ref), [`NLINEUP`](@ref) 
- Used by : [`mainloop!`](@ref)
- Related : [`FUNC`](@ref)
"""
function recalc_data!(comm)
    # Minutes played
    comm.Min += comm.Act

    # Fatigue level - deduction/Min +/- rand
    r1 = rand_fat32(NLINEUP)
    comm.Fat -= comm.Act .* (comm.Ded .- r1)

    # Min Fatigue is 0.1
    comm.Fat = max.(comm.Fat, 0.1f0)

    # Contrib columns: Tk, Ps, Sh
    comm.Shm = comm.Sh0 .* comm.Fat .* comm.Act
    comm.Psm = comm.Ps0 .* comm.Fat .* comm.Act
    comm.Tkm = comm.Tk0 .* comm.Fat .* comm.Act

    return nothing
end

