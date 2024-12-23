"""
    Tactics(TK, PS, SH)

Immutable struct containing the tactic skill multipliers.

# Fields
- `TK :: Float32` : Tackling multiplier
- `PS :: Float32` : Passing multiplier
- `SH :: Float32` : Shooting multiplier

# See also 
- Uses    : [`FUNC`](@ref)
- Used by : [`Position`](@ref)
- Related : [`TACTICSCONF`](@ref), [`Tactics`](@ref), [`Bonus`](@ref)
"""
@with_kw struct Skill
    TK :: Float32
    PS :: Float32
    SH :: Float32
end

"""
    Position(DF, DM, MF, AM, FW)

Immutable struct containing the tactic skill multipliers for each position.

Goalkeepers are not modified by any tactics.

Postion abbreviations:
- GK = Goalkeeper
- DF = Defender
- DM = Defensive Midfielder
- MF = Midfielder
- AM = Attacking Midfielder
- FW = Forward

# Fields
- `DF :: Skill` : Skill multipliers for players at the DF position
- `DM :: Skill` : Skill multipliers for players at the DM position
- `MF :: Skill` : Skill multipliers for players at the MF position
- `AM :: Skill` : Skill multipliers for players at the AM position
- `FW :: Skill` : Skill multipliers for players at the FW position

# See also 
- Uses    : [`Skill`](@ref)
- Used by : [`Tactics`](@ref)
- Related : [`TACTICSCONF`](@ref), [`Bonus`](@ref)
"""
@with_kw struct Position
    DF :: Skill
    DM :: Skill
    MF :: Skill
    AM :: Skill
    FW :: Skill
end

"""
    Position(DF, DM, MF, AM, FW)

Immutable struct containing the skill multipliers for each tactic.

Tactic abbreviations:
- N = Normal
- D = Defensive
- A = Attacking
- C = Counter-attack
- L = Long-ball
- P = Passing

# Fields
- `N :: Position` : Skill multipliers for the Normal tactic
- `D :: Position` : Skill multipliers for the Defensive tactic
- `A :: Position` : Skill multipliers for the Attacking tactic
- `C :: Position` : Skill multipliers for the Counter-attack tactic
- `L :: Position` : Skill multipliers for the Long-ball tactic
- `P :: Position` : Skill multipliers for the Passing tactic

# See also 
- Uses    : [`Position`](@ref)
- Used by : [`parse_tactics`](@ref), [`TacticsConfig`](@ref)
- Related : [`Bonus`](@ref), [`Skill`](@ref), [`TACTICSCONF`](@ref)
"""
@with_kw struct Tactics
    N :: Position 
    D :: Position
    A :: Position
    C :: Position
    L :: Position
    P :: Position
end

"""
    Bonus(owntact, opptact, pos, skill, mult)

Immutable struct containing the bonus skill multipliers.

The bonus determines how well a chosen tactic works against the opposing teams tactic.

# Fields
- `owntact :: SVector{12, SubString{String}}` : Current team's tactic
- `opptact :: SVector{12, SubString{String}}` : Opposing team's tactic
- `pos     :: SVector{12, SubString{String}}` : Position that the multiplier applies to
- `skill   :: SVector{12, SubString{String}}` : Skill that the multiplier applies to
- `mult    :: SVector{12, Float32}`           : Skill multiplier

# See also 
- Uses    : [`FUNC`](@ref)
- Used by : [`parse_tactics`](@ref), [`TacticsConfig`](@ref)
- Related : [`Tactics`](@ref), [`TACTICSCONF`](@ref)
"""
@with_kw struct Bonus
    owntact :: SVector{12, SubString{String}}
    opptact :: SVector{12, SubString{String}}
    pos     :: SVector{12, SubString{String}}
    skill   :: SVector{12, SubString{String}}
    mult    :: SVector{12, Float32}
end

"""
    TacticsConfig(tactics, bonus)

Immutable struct containing the tactics and bonus skill multipliers.

# Fields
- `tactics :: Tactics` : Immutable `Tactics` struct
- `bonus   :: Bonus`   : Immutable `Bonus` struct

# See also 
- Uses    : [`Tactics`](@ref), [`Bonus`](@ref)
- Used by : [`TACTICSCONF`](@ref), [`parse_tactics`](@ref)
- Related : [`TeamSheetConfig`](@ref), [`UpdateConfig`](@ref), [`RosterInfo`](@ref)
"""
@with_kw struct TacticsConfig
    tactics :: Tactics
    bonus   :: Bonus
end

"""
    fillpos(mults, tacidx, posidx, id)

Fills in a position struct with the appropriate multipliers for that tactic and position.

Tactic Indices:
- 1 = N (Normal)
- 2 = D (Defensive)
- 3 = A (Attacking)
- 4 = C (Counter-attack)
- 5 = L (Long-ball)
- 6 = P (Passing)

Position Indices:
- 1 = DF (Defender)
- 2 = DM (Defensive Midfielder)
- 3 = MF (Midfielder)
- 4 = AM (Attacking Midfielder)
- 5 = FW (Forward)

# Arguments
- `mults  :: Vector{Float32}` : Vector of multipliers
- `tacidx :: Vector{Int}`     : Vector of tactics (labelled as Ints)
- `posidx :: Vector{Int}`     : Vector of positions (labelled as Ints)
- `id     :: Int`             : The tactic index to use as a subset

# Returns
An immutable `Position` struct populated with multipliers.

# See also
- Uses    : [`fillskill`](@ref)
- Used by : [`parse_tactics`](@ref)
- Related : [`FUNC`](@ref)
"""
function fillpos(mults, tacidx, posidx, id)
    selidx = tacidx .== id
    res = Position(DF = fillskill(mults[selidx .* posidx .== 1]),
                   DM = fillskill(mults[selidx .* posidx .== 2]),
                   MF = fillskill(mults[selidx .* posidx .== 3]),
                   AM = fillskill(mults[selidx .* posidx .== 4]),
                   FW = fillskill(mults[selidx .* posidx .== 5]))
    return res
end

"""
    fillskill(vec)

Fills in a `Skill` struct with TK, PS, and SH (tackling, passing, and shooting) mutlipliers.

# Arguments
- `vec :: Vector` : Vector of three multipliers

# Returns
An immutable `Skill` struct containing the values in vec.

# See also
- Uses    : [`FUNC`](@ref)
- Used by : [`fillpos`](@ref)
- Related : [`parse_tactics`](@ref)
"""
function fillskill(vec)
    res = Skill(TK = vec[1],
                PS = vec[2],
                SH = vec[3])
    return res
end

"""
    parse_tactics(path_tactics)

Reads the tactics.dat file and stores in a `TacticsConfig` struct.

# Arguments
- `path_tactics :: String` : Path to the tactics.dat file

# Returns
An immutable `TacticsConfig` struct containing the tactics multipliers.

# See also
- Uses    : [`Tactics`](@ref), [`Bonus`](@ref), [`TacticsConfig`](@ref), [`fillpos`](@ref)
- Used by : [`FUNC`](@ref)
- Related : [`parse_league`](@ref), [`parse_teamsheet`](@ref), [`parse_roster`](@ref)
"""
function parse_tactics(path_tactics)
    tactstr = readlines(path_tactics)
    idx_m = map(x -> (x == "" ? false : x[1] == 'M'), tactstr)
    idx_b = map(x -> (x == "" ? false : x[1] == 'B'), tactstr)

    matm  = stack(split.(tactstr[idx_m]), dims = 1)
    mults = parse.(Float32, matm[:, 5]);

    tacidx = indexin(matm[:, 2], unique(matm[:, 2]));
    posidx = indexin(matm[:, 3], unique(matm[:, 3]));

    # Tactics Struct
    tactics = Tactics(N = fillpos(mults, tacidx, posidx, 1), 
                      D = fillpos(mults, tacidx, posidx, 2),
                      A = fillpos(mults, tacidx, posidx, 3),
                      C = fillpos(mults, tacidx, posidx, 4),
                      L = fillpos(mults, tacidx, posidx, 5),
                      P = fillpos(mults, tacidx, posidx, 6))

    # Bonus Struct
    matb  = stack(split.(tactstr[idx_b]), dims = 1)
    bonus = Bonus(owntact = SVector{12, SubString{String}}(matb[:, 3]),
                  opptact = SVector{12, SubString{String}}(matb[:, 2]),
                  pos     = SVector{12, SubString{String}}(matb[:, 4]),
                  skill   = SVector{12, SubString{String}}(matb[:, 5]),
                  mult    = SVector{12, Float32}(parse.(Float32, matb[:, 6])))

    return TacticsConfig(tactics = tactics, bonus = bonus)
end

"""
    getTactMult(tact, pos, skill)

Extracts the multiplier for a given tactic, position, and skill.

# Arguments
- `tact  :: String` : One character abberivation of the tactic name
- `pos   :: String` : Position name
- `skill :: String` : Skill name

# Returns
A `Float32` multiplier value.

# See also
- Uses    : [`TacticsConfig`](@ref), [`TACTICSCONF`](@ref)
- Used by : [`update_tactmult!`](@ref)
- Related : [`FUNC`](@ref)
"""
function getTactMult(tact, pos, skill)
    @unpack_TacticsConfig TACTICSCONF[]

    tact  = Symbol(tact)
    pos   = Symbol(pos)
    skill = Symbol(skill)
    res = getfield(getfield(getfield(tactics, tact), pos), skill)

    return res
end

"""
    update_tactmult!(comm, idx, tact)

Updates the (shooting, passing, and tackling) contributions for a single player based on the team tactic and their position.

# Arguments
- `comm :: Comms`  : A mutable `Comms` struct
- `idx  :: Int`    : The player index in comm
- `tact :: String` : The team tactic

# Returns
Nothing. Mutates a `Comms` struct with the updated player contributions.

# See also
- Uses    : [`Comms`](@ref), [`getTactMult`](@ref)
- Used by : [`calc_contribs!`](@ref), [`update_sub!`](@ref)
- Related : [`update_bonus!`](@ref)
"""
function update_tactmult!(comm, idx, tact)
    pos = comm.Pos[idx][1:2]
    if pos != "GK"
        comm.Sh0 = @set $(comm.Sh0)[idx] *= getTactMult(tact, pos, "SH")
        comm.Ps0 = @set $(comm.Ps0)[idx] *= getTactMult(tact, pos, "PS")
        comm.Tk0 = @set $(comm.Tk0)[idx] *= getTactMult(tact, pos, "TK")
    end
    return nothing
end

"""
    update_bonus!(comm, owntact, opptact, idx)

Updates the (shooting, passing, and tackling) contributions for a single player based on their position, their team tactic, and the opponent's team tactic.

# Arguments
- `comm    :: Comms`  : A mutable `Comms` struct
- `owntact :: String` : The team tactic
- `opptact :: String` : The opposing team tactic
- `idx     :: Int`    : The player index in comm

# Returns
Nothing. Mutates a `Comms` struct with the updated player contributions.

# See also
- Uses    : [`Comms`](@ref), [`TacticsConfig`](@ref), [`TACTICSCONF`](@ref)
- Used by : [`calc_contribs!`](@ref), [`update_sub!`](@ref)
- Related : [`update_tactmult!`](@ref)
"""
function update_bonus!(comm, owntact, opptact, idx)
    @unpack_TacticsConfig TACTICSCONF[]

    pos   = comm.Pos[idx][1:2]
    flag1 = bonus.owntact .== owntact
    flag2 = bonus.opptact .== opptact
    flag3 = bonus.pos     .== pos

    flag = flag1 .* flag2 .* flag3
    if sum(flag) > 0
        sk = bonus.skill
        mu = bonus.mult
        for i in eachindex(sk)
            if sk[i] == "SH"
                comm.Sh0 = @set $(comm.Sh0)[idx] *= ifelse(flag[i], mu[i], 1f0)

            elseif sk[i] == "PS"
                comm.Ps0 = @set $(comm.Ps0)[idx] *= ifelse(flag[i], mu[i], 1f0)

            else # Must be TK
                comm.Tk0 = @set $(comm.Tk0)[idx] *= ifelse(flag[i], mu[i], 1f0)
            end
        end
    end
    return nothing
end
