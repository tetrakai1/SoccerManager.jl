"""
    Padding functions

- `padstrm21 :: {Format.FmtSpec{Format.FmtStr}}` : Right-pad `String` to 21 chars
- `padstr4   :: {Format.FmtSpec{Format.FmtStr}}` : Left-pad `String` to 4 chars
- `padintm5  :: {Format.FmtSpec{Format.FmtDec}}` : Right-pad `Int` to 5 chars
- `padint3   :: {Format.FmtSpec{Format.FmtDec}}` : Left-pad `Int` to 3 chars
- `padint4   :: {Format.FmtSpec{Format.FmtDec}}` : Left-pad `Int` to 4 chars
- `padint5   :: {Format.FmtSpec{Format.FmtDec}}` : Left-pad `Int` to 5 chars
- `padint6   :: {Format.FmtSpec{Format.FmtDec}}` : Left-pad `Int` to 6 chars
"""
padintm5, padstrm21, padstr4, padint3, padint4, padint5, padint6

padstrm21 = generate_formatter("%-21s")
padstr4   = generate_formatter("%4s")
padintm5  = generate_formatter("%-5i")
padint3   = generate_formatter("%3i")
padint4   = generate_formatter("%4i")
padint5   = generate_formatter("%5i")
padint6   = generate_formatter("%6i")


"""
    Sched(v)

Immutable `FieldVector` containing the schedule for the league. 

Each element of the vector is a matrix containing the weekly schedule. For performance, the schedule consists of `Int16` values that index each team rather than strings.

# Fields
- `v :: SVector{N, Matrix{Int16}}` : `SVector` of matrices that contain the schedule for each week

# See also 
- Uses    : [`FUNC`](@ref)
- Used by : [`makeschedule`](@ref), [`playseason!`](@ref)
- Related : [`TeamNames`](@ref)
"""
struct Sched{N, T <: Matrix{Int16}} <: FieldVector{N, Matrix{Int16}}
    v::SVector{N, T}
end
Base.getindex(v::Sched, i::Int)                    = getindex(v.v, i)
Base.setindex!(v::Sched, X::Matrix{Int16}, i::Int) = setindex!(v.v, X, i)


"""
    makeschedule(nteams)

Creates a league schedule.

Each element of the vector is a matrix containing the weekly schedule. For performance, the schedule consists of `Int16` values that index each team rather than strings.

# Arguments
- `nteams :: Int` : Number of teams in the league

# Returns
A `Sched` vector where each element is a matrix of the matches for each week.

# See also
- Uses    : [`Sched`](@ref)
- Used by : [`FUNC`](@ref)
- Related : [`playseason!`](@ref)
"""
function makeschedule(nteams)
    flag = false
    if isodd(nteams)
        flag   = true
        nteams = nteams + 1
    end

    nr  = Int(nteams/2)
    nw  = nteams - 1
    res = [zeros(Int16, nr, 2) for _ in 1:nw]

    res[1][1:end] = ifelse(flag, Int16(0):Int16(nteams - 1), Int16(1):Int16(nteams))
    for w in 2:nw
        base = res[w - 1]
        tmp  = res[w]

        tmp[1, 1]  = base[1, 1]
        tmp[1, 2]  = base[2, 1]
        tmp[nr, 1] = base[nr, 2]

        if nr > 2
            for i in reverse(3:nr)
                tmp[i - 1, 1] = base[i, 1]
            end
        end

        for i in 2:nr
            tmp[i, 2] = base[i - 1, 2]
        end
    end

    if flag
        res = [res[i][1:end .!= findfirst(res[i] .== Int16(0))[1], :] for i in eachindex(res)]
    end

    # Repeat the above schedule with home/away teams reversed
    res = SVector{2*nw, Matrix{Int16}}(vcat(res, reverse.(res)))

    return Sched(res)
end


"""
    struct2df(s, idx)

Convert a `Struct` to a `DataFrame`.

# Arguments
- `s   :: Struct`      : The struct to be converted
- `idx :: Vector{Int]` : Selected indices of `s`

# Returns
A `DataFrame` verion of the input struct.

# See also
- Uses    : [`FUNC`](@ref)
- Used by : [`FUNC`](@ref)
- Related : [`rost2df`](@ref), [`lgtble2df`](@ref)
"""
function struct2df(s, idx)
    fields = fieldnames(typeof(s))[idx]
    vector = [getfield(s, field) for field in fields]

    return DataFrame(hcat(vector...), collect(fields))
end

"""
    getfield_unroll(t, f)

Extracts a struct field without any heap allocations.

Used instead of `Base.getfield` for performance.

# Arguments
- `t :: T     ` : The struct/type that contains the field
- `f :: Symbol` : The field to extract

# Returns
Field `f` of struct `t`.

# See also
- Uses    : [`FUNC`](@ref)
- Used by : [`write_comms`](@ref), [`write_roster`](@ref), [`rost2df`](@ref), [`flatten_rosters`](@ref)
- Related : [`FUNC`](@ref)
"""
@generated function getfield_unroll(t::T, f::Symbol) where {T}
    names = fieldnames(T)
    exprs = [:($(QuoteNode(name)) == f && return getfield(t, $(QuoteNode(name)))) for (c, name) in enumerate(names)]

    return quote
        $(exprs...)
    end
end
