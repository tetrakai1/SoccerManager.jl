
"""
    maxmin(vec; minval = Int16(1), maxval = Int16(99))

Truncates values of a vector to be between `minval` and `maxval`.

# Arguments
- `vec :: Vector` : A vector of values to be truncated

# Kwargs
- `minval :: Int` : The lowest allowed value
- `maxval :: Int` : The highest allowed value

# Returns
A vector of values bewteen `minval` and `maxval`.

# See also
- Uses    : [`FUNC`](@ref)
- Used by : [`stats2rating`](@ref), [`step_ratings`](@ref)
- Related : [`FUNC`](@ref)
"""
function maxmin(vec; minval = Int16(1), maxval = Int16(99))
    return max.(min.(vec, maxval), minval)
end

"""
    randstep(stepsize)

Generates an `SVector` of random values between -stepsize to + stepsize.

# Arguments
- `stepsize :: Int` : Absolute value of the largest allowed step size

# Returns
An `SVector` of `Ints`.

# See also
- Uses    : [`MAXPLAYERS`](@ref)
- Used by : [`step_ratings`](@ref)
- Related : [`FUNC`](@ref)
"""
function randstep(stepsize)
    return @SVector rand(-stepsize:stepsize, MAXPLAYERS)
end

"""
    step_ratings(roster, stepsize)

Samples new skill ratings from currrent +/- `stepsize`.

# Arguments
- `roster   :: Roster` : An immutable `Roster` struct
- `stepsize :: Int`    : Absolute value of the largest allowed step size

# Returns
The `roster` with new ratings.

# See also
- Uses    : [`Roster`](@ref), [`maxmin`](@ref), [`randstep`](@ref)
- Used by : [`update_ratings!`](@ref)
- Related : [`FUNC`](@ref)
"""
function step_ratings(roster, stepsize)
    flag = roster.Name .!= "PLACEHOLDER"

    @reset roster.St = maxmin(roster.St + randstep(stepsize)) .* flag
    @reset roster.Tk = maxmin(roster.Tk + randstep(stepsize)) .* flag
    @reset roster.Ps = maxmin(roster.Ps + randstep(stepsize)) .* flag
    @reset roster.Sh = maxmin(roster.Sh + randstep(stepsize)) .* flag
    @reset roster.Sm = maxmin(roster.Sm + randstep(stepsize)) .* flag
    @reset roster.Ag = maxmin(roster.Ag + randstep(stepsize)) .* flag

    return roster
end

"""
    step_ratings(roster1, roster2, stepsize)

Samples new skill ratings from `roster2` +/- `stepsize`, then binds them to the corresponding elements of `roster1`.

# Arguments
- `roster1  :: Roster` : The destination immutable `Roster` struct
- `roster2  :: Roster` : The source immutable `Roster` struct
- `stepsize :: Int`    : Absolute value of the largest allowed step size

# Returns
The `roster1` struct with new ratings.

# See also
- Uses    : [`Roster`](@ref), [`maxmin`](@ref), [`randstep`](@ref)
- Used by : [`update_ratings!`](@ref)
- Related : [`FUNC`](@ref)
"""
function step_ratings(roster1, roster2, stepsize)
    flag = roster1.Name .!= "PLACEHOLDER"

    @reset roster1.St = maxmin(roster2.St + randstep(stepsize)) .* flag
    @reset roster1.Tk = maxmin(roster2.Tk + randstep(stepsize)) .* flag
    @reset roster1.Ps = maxmin(roster2.Ps + randstep(stepsize)) .* flag
    @reset roster1.Sh = maxmin(roster2.Sh + randstep(stepsize)) .* flag
    @reset roster1.Sm = maxmin(roster2.Sm + randstep(stepsize)) .* flag
    @reset roster1.Ag = maxmin(roster2.Ag + randstep(stepsize)) .* flag

    return roster1
end

"""
    update_ratings!(sims, stepsize)

Updates skill ratings from each roster +/- `stepsize`.

Eg, used when an MCMC step is *accepted*. All replicates in `sims` have identical new ratings.

# Arguments
- `sims     :: Sims` : Mutable `FieldVector` containing multiple copies of the same `LeagueData` struct
- `stepsize :: Int`  : Absolute value of the largest allowed step size

# Returns
Nothing. Mutates the `Roster` elements of the `Sims` struct.

# See also
- Uses    : [`Sims`](@ref), [`step_ratings`](@ref)
- Used by : [`FUNC`](@ref)
- Related : [`FUNC`](@ref)
"""
function update_ratings!(sims, stepsize)
    for i in eachindex(sims[1].tv)
        sims[1].tv[i].roster = step_ratings(sims[1].tv[i].roster, stepsize)
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
    update_ratings!(sims, sims_last, stepsize)

Updates skill ratings from each roster in `sims_last` +/- `stepsize`, then binds them to the corresponding elements of `sims`.

Eg, used when an MCMC step is *rejected*. All replicates in `sims` have identical new ratings.

# Arguments
- `sims      :: TYPE` : The destination `Sims` struct
- `sims_last :: TYPE` : The source `Sims` struct
- `stepsize  :: Int`  : Absolute value of the largest allowed step size

# Returns
Nothing. Mutates the `Roster` elements of the `Sims` struct.

# See also
- Uses    : [`Sims`](@ref), [`step_ratings`](@ref)
- Used by : [`FUNC`](@ref)
- Related : [`FUNC`](@ref)
"""
function update_ratings!(sims, sims_last, stepsize)
    for i in eachindex(sims[1].tv)
        sims[1].tv[i].roster = step_ratings(sims[1].tv[i].roster, sims_last[1].tv[i].roster, stepsize)
    end

    # All reps should start the same (doesn't matter that its a copy)
    for i in 2:length(sims)
        for j in eachindex(sims[1].tv)
            sims[i].tv[j].roster = sims[1].tv[j].roster
        end
    end
    return nothing
end


