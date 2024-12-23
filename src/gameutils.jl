"""
    sht_prob(comm, oppcomm)

Calculate probability of team taking a shot.

# Arguments
- `comm    :: Comms` : Current team's `Comms` struct
- `oppcomm :: Comms` : Opposing team's `Comms` struct

# Returns
A probability, `Float32` value between zero and one.

# See also 
- Used by : [`if_shot!`](@ref)
- Related : [`gl_prob`](@ref), [`tk_prob`](@ref)
"""
function sht_prob(comm, oppcomm)
    res = 1.8f0 * (sum(comm.Ag .* comm.Act)/50f4 + 0.08f0* 
                   (((sum(comm.Shm) + 2f0*sum(comm.Psm))/3f0) / 
                    (sum(oppcomm.Tkm) + 1f0))^2f0)

    return min(res, 1.0f0)
end


"""
    tk_prob(comm, oppcomm)

Calculate probability of potential shooter getting tackled.

# Arguments
- `comm    :: Comms` : Current team's `Comms` struct
- `oppcomm :: Comms` : Opposing team's `Comms` struct

# Returns
A probability, `Float32` value between zero and one.

# See also 
- Used by : [`if_shot!`](@ref)
- Related : [`gl_prob`](@ref), [`shot_prob`](@ref)
"""
function tk_prob(comm, oppcomm)
    res = 0.4f0*3f0*sum(oppcomm.Tkm)/(2f0*sum(comm.Psm) + sum(comm.Shm))

    return min(res, 1.0f0)
end


"""
    gl_prob(comm, oppcomm, idx_shooter)

Calculate probability the shooter scores a goal.

# Arguments
- `comm        :: Comms` : Current team's `Comms` struct
- `oppcomm     :: Comms` : Opposing team's `Comms` struct
- `idx_shooter :: Int`   : Index of shooter in the `Comms` struct

# Returns
A probability, `Float32` value between zero and one.

# See also 
- Used by : [`if_shot!`](@ref)
- Related : [`shot_prob`](@ref), [`tk_prob`](@ref)
"""
function gl_prob(comm, oppcomm, idx_shooter)
    idx_gk = oppcomm.Gk :: Int64
    res = 0.02f0 * comm.Sh[idx_shooter] * comm.Fat[idx_shooter] -
            0.02f0*oppcomm.St[idx_gk] + 0.35f0

    return min(max(res, 0.1f0), 0.9f0)
end


"""
    pick_player(x, wts)

Pick a player index using weighted sampling of x.

# Arguments
- `x   :: Vector{Int}` : Vector of contrib values to be used as weights
- `wts :: Weights`     : Reusable `Weights` for weighted sampling of players (who takes a shot, etc)

# Returns
An index, `Int` value between one and `MAXPLAYERS`.

# See also 
- Used by : [`if_shot!`](@ref)
- Related : [`pick_passer`](@ref)
"""
function pick_player(x, wts)
    wts.values = x 
    wts.sum    = sum(wts.values)

    return wsample(wts)
end


"""
    pick_passer(x, wts, idx_shooter)

Pick a player index using weighted sampling of x. 

Sets weight of the shooter to zero (passer cannot be the same player who takes a shot).

# Arguments
- `x           :: Vector{Int}` : Vector of contrib values to be used as weights
- `wts         :: Weights`     : Reusable `Weights` for weighted sampling of players (who takes a shot, etc).
- `idx_shooter :: Int`         : Index of shooter in the `Comms` struct

# Returns
An index, `Int` value between one and `MAXPLAYERS`.

# See also 
- Used by : [`if_shot!`](@ref)
- Related : [`pick_player`](@ref)
"""
function pick_passer(x, wts, idx_shooter)
    @reset x[idx_shooter] = 0.0f0
    wts.values = x  
    wts.sum    = sum(wts.values)

    return wsample(wts)
end


"""
    if_shot!(comm, oppcomm, ishome, wts)

Pseudo-randomly decide whether an attempted shot takes place and whether it was assisted by a passer. 

The shot may then be prevented by a tackle, off-target, score a goal, or be stopped by the GK. A bonus is added to the home team's probability of taking a shot.


# Arguments
- `comm    :: Comms`   : Current team's `Comms` struct
- `oppcomm :: Comms`   : Opposing team's `Comms` struct
- `ishome  :: Bool`    : Whether `Comms` is the home team
- `wts     :: Weights` : Reusable `Weights` for weighted sampling of players (who takes a shot, etc).

# Returns
Nothing. Mutates `Comms` elements of the `TeamVec` vector.

# See also 
- Uses    : [`sht_prob`](@ref), [`tk_prob`](@ref), [`gl_prob`](@ref), [`pick_player`](@ref), [`pick_passer`](@ref)
- Used by : [`mainloop!`](@ref)
- Related : [`rand_injury!`](@ref), [`if_foul!`](@ref)
"""
function if_shot!(comm, oppcomm, ishome, wts)
    # Attempt a shot
    # Home teams gets a bonus
    shot_prob = sht_prob(comm, oppcomm)
    shot_prob = ifelse(ishome, min(shot_prob + 0.02f0, 1), shot_prob)
    shot_flag = rand(Bernoulli(shot_prob))

    if shot_flag 
        idx_shooter = pick_player(comm.Shm, wts)

        # Who passed to shooter?
        # Try twice if shooter is on a different side
        make_pass = rand(Bernoulli(0.75))
        if make_pass
            idx_passer = pick_passer(comm.Psm, wts, idx_shooter)
            sideflag   = comm.Pos[idx_shooter][3] != comm.Pos[idx_passer][3]
            if !sideflag
                idx_passer = pick_passer(comm.Psm, wts, idx_shooter)
            end
            comm.Kps = @set $(comm.Kps)[idx_passer] += 1
        end

        # Is shooter tackled?
        chance_tackled = tk_prob(comm, oppcomm)
        if !rand(Bernoulli(chance_tackled))
            comm.Sht = @set $(comm.Sht)[idx_shooter] += 1

            # Is shot on-target?
            chance_ontarget = 0.58f0*comm.Fat[idx_shooter]
            if rand(Bernoulli(chance_ontarget))
                chance_goal = gl_prob(comm, oppcomm, idx_shooter)

                # Is it a goal?
                if rand(Bernoulli(chance_goal))

                    # Is the goal cancelled (due to offsides, etc)?
                    if(!rand(Bernoulli(0.05)))
                        comm.Gls = @set $(comm.Gls)[idx_shooter] += 1
                        if make_pass
                            comm.Ass = @set $(comm.Ass)[idx_passer] += 1
                        end
                    end

                else
                    oppcomm.Sav = @set $(oppcomm.Sav)[oppcomm.Gk] += 1
                end
            end 

        else
            idx_tackler = pick_player(oppcomm.Tkm, wts)
            oppcomm.Ktk = @set $(oppcomm.Ktk)[idx_tackler] += 1 
        end
    end
    return nothing
end



"""
    if_foul!(comm, oppcomm, wts)

Pseudo-randomly decide whether a foul is commited. 

This may result in  Yellow/Red cards and/or a penalty kick. The fouler is ejected from the game without replacement after accumulating two yellow cards or one red card.

# Arguments
- `comm    :: Comms`   : Current team's `Comms` struct
- `oppcomm :: Comms`   : Opposing team's `Comms` struct
- `wts     :: Weights` : Reusable `Weights` for weighted sampling of players (who takes a shot, etc)

# Returns
 Nothing. Mutates `Comms` elements of the `TeamVec` vector.

# See also 
- Uses    : [`Comms`](@ref), [`pick_player`](@ref)
- Used by : [`mainloop!`](@ref)
- Related : [`if_shot!`](@ref), [`rand_injury`](@ref)
"""
function if_foul!(comm, oppcomm, wts)
    chance_foul = (0.75f0 * sum(comm.Ag .* comm.Act))/10f3
    foul_flag   = rand(Bernoulli(chance_foul))
    if foul_flag
        idx_fouler = pick_player((comm.Ag .* comm.Act), wts)
        
        # Yellow Card
        if rand(Bernoulli(0.6))
            comm.Yel = @set $(comm.Yel)[idx_fouler] += 1
            if comm.Yel[idx_fouler] == 2
                comm.Act = @set $(comm.Act)[idx_fouler] = 0
            end

        # Red Card
        elseif rand(Bernoulli(0.04))
            comm.Red = @set $(comm.Red)[idx_fouler] = true
            comm.Act = @set $(comm.Act)[idx_fouler] = 0
        end

        # Penalty Kick
        if comm.Pos[idx_fouler] == "GK" || rand(Bernoulli(0.05))

            idx_pk = ifelse(oppcomm.Act[oppcomm.Pk], oppcomm.Pk, 
                            findmax(oppcomm.Sh .* oppcomm.Act .* oppcomm.Fat)[2])
            chance_pk = 0.8f0 + 0.01f0*(oppcomm.Sh[idx_pk] - comm.St[comm.Gk])
            chance_pk = max(min(chance_pk, 1), 0)
            if rand(Bernoulli(chance_pk))
                oppcomm.Gls = @set $(oppcomm.Gls)[idx_pk] += 1
            elseif rand(Bernoulli(0.75))
                # Saved
                # add logging
            else
                # Off-target
                # add logging
            end
        end
    end
    return nothing
end


