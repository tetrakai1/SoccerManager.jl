
"""
    rand_ratings(roster)

Generates random skill ratings between 1 and 99.

A roster with less than `MAXPLAYERS` is padded with entries having the player name set to `PLACEHOLDER`. These will have ratings set to the placeholder value of zero.

# Arguments
- `roster :: Roster` : An immutable `Roster` struct

# Returns
The `roster` with new random ratings.

# See also
- Uses    : [`Roster`](@ref), [`MAXPLAYERS`](@ref)
- Used by : [`init_rand_ratings!`](@ref)
- Related : [`RosterInfo`](@ref)
"""
function rand_ratings(roster)
    flag = roster.Name .!= "PLACEHOLDER"

    @reset roster.St = SVector{MAXPLAYERS, Int16}(rand(Int16(1):Int16(99), MAXPLAYERS) .* flag)
    @reset roster.Tk = SVector{MAXPLAYERS, Int16}(rand(Int16(1):Int16(99), MAXPLAYERS) .* flag)
    @reset roster.Ps = SVector{MAXPLAYERS, Int16}(rand(Int16(1):Int16(99), MAXPLAYERS) .* flag)
    @reset roster.Sh = SVector{MAXPLAYERS, Int16}(rand(Int16(1):Int16(99), MAXPLAYERS) .* flag)
    @reset roster.Sm = SVector{MAXPLAYERS, Int16}(rand(Int16(1):Int16(99), MAXPLAYERS) .* flag)
    @reset roster.Ag = SVector{MAXPLAYERS, Int16}(rand(Int16(1):Int16(99), MAXPLAYERS) .* flag)

    return roster
end




"""
    init_rand_ratings!(sims)

Sets all the rosters in `sims` to random values between 1 and 99.

# Arguments
- `sims  :: Sims` : Mutable `FieldVector` containing multiple copies of the same `LeagueData` struct

# Returns
Nothing. Mutates the `Sims` struct.

# See also
- Uses    : [`FUNC`](@ref)
- Used by : [`FUNC`](@ref)
- Related : [`FUNC`](@ref)
"""
function init_rand_ratings!(sims)
    
    for i in eachindex(sims[1].tv)
        sims[1].tv[i].roster = rand_ratings(sims[1].tv[i].roster)
    end

    # All reps should start the same (doesn't matter that its a copy)
    for i in 2:length(sims)
        for j in eachindex(sims[1].tv)
            sims[i].tv[j].roster = sims[1].tv[j].roster
        end
    end
    return nothing
end


"""
    stats2rating(stats, dt)

Transforms a vector of `stats` using the function `dt`, then truncate to valid ratings values (between 1 and 99).

Eg, as used by `init_percent_ratings!` a vector of already ECDF-transformed stats are normalized to `Int16` values between 1 and 99.

# Arguments
- `stats :: Vector`                : A vector of stats (eg, Saves, Goals, etc)
- `dt    :: AbstractDataTransform` : The transform to be used on stats

# Returns
DESCRIPTION

# See also
- Uses    : [`maxmin`](@ref)
- Used by : [`init_percent_ratings!`](@ref)
- Related : [`FUNC`](@ref)
"""
function stats2rating(stats, dt)
    res = SVector{length(stats), Float16}(StatsBase.transform(dt, stats))
    return maxmin(Int16.(round.(res * Float16(100))))
end

"""
    init_percent_ratings!(sims, baseline, ::Val{N})

Initialize player skill ratings in `sims` to percentiles of relevant stats in the `baseline` `LeagueData`.

```  
  Skill Rating         Statistic
- St (Shot-Stopping) : Sav (Saves)
- Tk (Tackling)      : Ktk (Key Tackles)
- Ps (Passing)       : Kps (Key Passes)
- Sh (Shooting)      : Sht (Shots)
- Ag (Aggression)    : All equal to 50
- Sm (Stamina)       : All equal to 30
```


# Arguments
- `baseline :: LeagueData` : The baseline (ground truth) league
- `sims     :: Sims`       : One or more simulated leagues
- `N        :: Val{N}`     : The number of teams

# Returns
Nothing. Mutates `sims` to have the new percentile-derived skill ratings.

# See also
- Uses    : [`Sims`](@ref), [`LeagueData`](@ref), [`MAXPLAYERS`](@ref), [`stats2rating`](@ref)
- Used by : [`FUNC`](@ref)
- Related : [`FUNC`](@ref)
"""
function init_percent_ratings!(sims, baseline, ::Val{N}) where {N}

    btv  = baseline.tv
    stv  = sims[1].tv
    ntot = MAXPLAYERS*N

    idx0  = SVector{N, Int64}(1:MAXPLAYERS:ntot)
    idxF  = idx0 .+ (MAXPLAYERS -1)

    T = SVector{N, SVector{MAXPLAYERS, Int16}}
    flatratings = (reduce(vcat, T(btv[i].roster.Sav for i in 1:N)),
                   reduce(vcat, T(btv[i].roster.Ktk for i in 1:N)),
                   reduce(vcat, T(btv[i].roster.Kps for i in 1:N)),
                   reduce(vcat, T(btv[i].roster.Sht for i in 1:N)))

    # dt         = @SVector [fit(UnitRangeTransform, flatratings[i]) for i in 1:4] # 35 allocs
    # newratings = @SVector [stats2rating(flatratings[i], dt[i])     for i in 1:4] # 15 allocs

    # TODO: Fix type-instability from ecdf
    ecdfs        = @SVector [ecdf(flatratings[i])                    for i in 1:4]
    ecdfratings  = @SVector [ecdfs[i](flatratings[i])                for i in 1:4]
    dt           = @SVector [fit(UnitRangeTransform, ecdfratings[i]) for i in 1:4]
    newratings   = @SVector [stats2rating(ecdfratings[i], dt[i])     for i in 1:4]


    for i in eachindex(btv)
        flag = stv[i].roster.Name .!= "PLACEHOLDER"
        idx  = SVector{MAXPLAYERS, Int64}(idx0[i]:idxF[i])
        Sm   = @SVector fill(Int16(50), MAXPLAYERS)
        Ag   = @SVector fill(Int16(30), MAXPLAYERS)     
        stv[i].roster = @set $(stv[i].roster).St = newratings[1][idx] .* flag
        stv[i].roster = @set $(stv[i].roster).Tk = newratings[2][idx] .* flag
        stv[i].roster = @set $(stv[i].roster).Ps = newratings[3][idx] .* flag
        stv[i].roster = @set $(stv[i].roster).Sh = newratings[4][idx] .* flag
        stv[i].roster = @set $(stv[i].roster).Ag = Ag .* flag 
        stv[i].roster = @set $(stv[i].roster).Sm = Sm .* flag
    end

    # All reps should start the same (doesn't matter that its a copy)
    for i in 2:length(sims)
        for j in eachindex(stv)
            sims[i].tv[j].roster = sims[1].tv[j].roster
        end
    end

    return sims
end



