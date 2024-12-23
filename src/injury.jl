"""
    update_sub!(comm, oppcomm, inj_pos, idx)

Performs a substitution after injury. 

The sub is set to active, and their contributions are updated given the current tactics.

# Arguments
- `comm    :: Comms`  : Current team's 'Comms' struct
- `oppcomm :: Comms`  : Opposing team's 'Comms' struct
- `inj_pos :: String` : Position being subbed (FWC, MFR, etc)
- `idx     :: Int`    : 'Comms' index of the sub (new player)

# Returns
Nothing. Mutates a `Comms` struct.

# See also
- Uses    : [`update_sidefactor!`](@ref), [`update_tactmult!`](@ref), [`update_bonus!`](@ref)
- Used by : [`rand_injury!`](@ref)
- Related : [`update_sub_gk!`](@ref), [`set2inj!`](@ref) 
"""
@inline function update_sub!(comm, oppcomm, inj_pos, idx)
    comm.Act = @set $(comm.Act)[idx] = 1
    comm.Pos = @set $(comm.Pos)[idx] = inj_pos
    update_sidefactor!(comm, idx)
    update_tactmult!(comm, idx, comm.Tactic)
    update_bonus!(comm, comm.Tactic, oppcomm.Tactic, idx)

    return nothing
end

"""
    update_sub_gk!(comm, idx)

Performs a substitution after injury to the goalkeeper. 

The sub is set to active, and their contributions are set to zero (besides shot-stopping).


# Arguments
- `comm :: Comms` : Current team's `Comms` struct
- `idx  :: Int`   : `Comms` index of the sub (new player)

# Returns
Nothing. Mutates a `Comms` struct.

# See also
- Uses    : [`FUNC`](@ref)
- Used by : [`rand_injury!`](@ref)
- Related : [`update_sub!`](@ref), [`set2inj!`](@ref) 
"""
@inline function update_sub_gk!(comm, idx)
    comm.Pos = @set $(comm.Pos)[idx] = String15("GK")
    comm.Sh0 = @set $(comm.Sh0)[idx] = 0.0f0
    comm.Ps0 = @set $(comm.Ps0)[idx] = 0.0f0
    comm.Tk0 = @set $(comm.Tk0)[idx] = 0.0f0
    comm.Ded = @set $(comm.Ded)[idx] = 0.0f0
    comm.Gk  = idx

    return nothing
end

"""
    set2inj!(comm, idx_inj)

Flags player as injured and deactivates.

# Arguments
- `comm    :: Comms` : Current team's `Comms` struct
- `idx_inj :: Int`   : `Comms` index of the injured player

# Returns
Nothing. Mutates a `Comms` struct.

# See also
- Uses    : [`FUNC`](@ref)
- Used by : [`rand_injury!`](@ref)
- Related : [`update_sub!`](@ref), [`update_sub_gk!`](@ref)
"""
@inline function set2inj!(comm, idx_inj)
    comm.Act = @set $(comm.Act)[idx_inj] = 0
    comm.Inj = @set $(comm.Inj)[idx_inj] = 1

    return nothing
end

"""
    rand_injury!(comm, oppcomm, wts)

Pseudo-randomly decide whether an injury occurs based on opposing teamm's aggression. 

If so, pick a random player (no relation to stamina, etc) and set to injured. If the team has subs remaining, choose the best player as the sub (according to position, preferred side, and skill).


# Arguments
- `comm    :: Comms`   : Current team's `Comms` struct
- `oppcomm :: Comms`   : Opposing team's `Comms` struct
- `wts     :: Weights` : Reusable `Weights` for weighted sampling of players (who takes a shot, etc).

# Returns
Nothing. Mutates a `Comms` struct.

# See also
- Uses    : [`UpdateConfig`](@ref), [`pick_player`](@ref), [`update_sub!`](@ref), 
            [`update_sub_gk!`](@ref), [`set2inj!`](@ref) 
- Used by : [`mainloop!`](@ref)
- Related : [`if_shot!`](@ref), [`if_foul!`](@ref)
"""
function rand_injury!(comm, oppcomm, wts)
    @unpack_UpdateConfig UPDATECONF[]

    chance_injury = 0.15f0 * sum(oppcomm.Ag .* oppcomm.Act)/50f3
    if rand(Bernoulli(chance_injury))
        idx_inj = pick_player(comm.Act, wts)
        inj_pos = comm.Pos[idx_inj]
        avail   = .!comm.Act .* .!comm.Inj .* .!comm.Red .* (comm.Yel .!= 2)
        if sum(avail) > 0 && comm.SubCnt < max_subs
            same_pos_side = comm.Pos .== inj_pos
            flags         = same_pos_side .* avail
            if sum(flags) > 0
                # Sub with same position and side
                # Type annotation here gets rid of 3 allocations...
                idx      = findfirst(flags) :: Int64
                comm.Act = @set $(comm.Act)[idx] = 1

                if inj_pos == "GK"
                    comm.Gk = idx
                end
            else

                if inj_pos == "GK"
                    # If no GK found, sub using highest ST rating
                    idx = findmax(comm.St .* avail)[2]
                    comm.Act = @set $(comm.Act)[idx] = 1
                    update_sub_gk!(comm, idx)
                else
                    pos = map(x -> SubString(x, 1:2), comm.Pos)
                    same_pos = (pos.== comm.Pos[idx_inj][1:2])
                    flags = same_pos .* avail

                    if sum(flags) > 0
                        # Sub with same position
                        idx = findfirst(flags)
                        update_sub!(comm, oppcomm, inj_pos, idx)
                    else
                        # Sub with first available player you see
                        flags = ifelse(sum(avail) > 1, (pos .!= "GK") .* avail, avail)
                        idx   = findfirst(flags)
                        update_sub!(comm, oppcomm, inj_pos, idx)
                    end

                end

            end
            comm.SubCnt += 1
            set2inj!(comm, idx_inj)
        else
            if inj_pos == "GK"
                # Reassign best ST rating on field to GK
                set2inj!(comm, idx_inj)

                idx = findmax(comm.St .* comm.act)[2]
                update_sub_gk!(comm, idx)
            else
                # Keep playing with one less player
                set2inj!(comm, idx_inj)
            end
        end
    end
end


