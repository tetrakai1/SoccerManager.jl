julia> @benchmark init_league($rpaths, $tspaths, $TEAMNAMES, $SCHED; usefile = false)
BenchmarkTools.Trial: 7188 samples with 1 evaluation.
 Range (min … max):  326.198 μs … 98.536 ms  ┊ GC (min … max):  0.00% … 92.55%
 Time  (median):     455.972 μs              ┊ GC (median):     0.00%
 Time  (mean ± σ):   687.467 μs ±  3.297 ms  ┊ GC (mean ± σ):  30.74% ±  6.54%

                ▁▁▄▄▅▆█▇█▇▇▇▇▄▂▁                                
  ▂▁▂▂▃▃▄▄▅▅▆▅███████████████████▆▆▅▄▄▄▃▃▃▃▃▃▂▃▂▂▃▃▃▂▂▂▂▂▂▂▂▂▂ ▄
  326 μs          Histogram: frequency by time          671 μs <

 Memory estimate: 981.83 KiB, allocs estimate: 3647.


function doctemplate(f, args)
    x        = @code_typed f(args...)
    src      = x[1]
    sig      = split(string(src.parent.def), " @")[1]
    args     = string.(src.slotnames)[2:end]
    argtypes = string.(src.slottypes)[2:end]
    rettype  = string(x[2])

    argvec = args .* " :: " .* argtypes .* " : ARG_DESC"
    argstr = join(argvec, "\n")

    docstr = """
        $sig

    METHOD_DESC

    # Arguments
    $argstr

    # Returns
    $rettype
    """

    return docstr
end

function addnums(a, b::Int16)
    res = a + b
    return res
end

docstr = doctemplate(addnums, (10, Int16(3)));
print(docstr)





a = 10
b = Int16(1)

x = @code_typed addnums(a, b)

src      = x[1]
sig      = split(string(src.parent.def), " @")[1]
args     = string.(src.slotnames)[2:end]
argtypes = string.(src.slottypes)[2:end]
rettype  = string(x[2])

argvec = args .* " :: " .* argtypes .* " : ARG_DESC"
argstr = join(argvec, "\n")

docstr = """
    $sig

METHOD_DESC

# Arguments
$argstr

# Returns
$rettype
"""

print(docstr)

















# using AutomaticDocstrings
include(joinpath(pwd(), "scripts/autodoc.jl"))
using .AutomaticDocstrings

autodoc(joinpath(pwd(), "scripts/scratch.jl"))
include(joinpath(pwd(), "scripts/scratch.jl"))


using CSTParser, MacroTools
str = "function match_teamsht(roster, teamsht :: String; n = 10 :: Int, n2 = 29) end"
parsed = CSTParser.parse(str)
mp = Meta.parse(str,1)[1]
fundef = MacroTools.splitdef(mp)
MacroTools.splitarg(fundef[:args])

maxlength = maximum(length.(string.(fundef[:args])))

fundef[:args]
kwargnames = [MacroTools.splitarg(fundef[:kwargs][i])[1] for i in eachindex(fundef[:kwargs])]

maximum(length.(string.(kwargnames)))



str0 = readlines(joinpath(pwd(), "scripts/scratch.jl"))
idx1 = findfirst(startswith.(str0, "function "))
idx2 = findfirst(startswith.(str0, "end"))
str1  = str0[idx1:idx2]
str   = reduce(*, str1)
parsed = CSTParser.parse(str)

[parsed[i].head == :call for i in eachindex(parsed)]


using StaticArrays, Accessors

"""
    match_teamsht(roster, teamsht)

DOCSTRING

# Arguments
- `roster  :: TYPE` : DESCRIPTION
- `teamsht :: TYPE` : DESCRIPTION

# See also
- Uses    : [`FUNC`](@ref)
- Used by : [`FUNC`](@ref)
- Related : [`FUNC`](@ref)
"""
function match_teamsht(roster, teamsht)
    idx_in = @SVector fill(0, NLINEUP)
    tsvec  = SVector{NLINEUP, String15}([teamsht.StartName; teamsht.SubName])
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
    read_roster(fname)

Reads a fixed-width roster file into a vector of strings.

# Arguments
- `fname :: String` : Path to the roster file

See also [`parse_roster`](@ref).
"""
function read_roster(fname)
    io = open(fname, "r")
        seek(io, 206)
        x = read(io, String)
    close(io)

    return split(x[1:(end - 2)], "\n")
end




"""
    read_roster2(fname; n = 206, n2 = 10)

DOCSTRING

# Arguments
- `fname :: TYPE` : DESCRIPTION

# Kwargs
- `n  :: TYPE` : DESCRIPTION
- `n2 :: TYPE` : DESCRIPTION

# See also
- Uses    : [`FUNC`](@ref)
- Used by : [`FUNC`](@ref)
- Related : [`FUNC`](@ref)
"""
function read_roster2(fname; n = 206, n2 = 10)
    io = open(fname, "r")
        seek(io, n)
        x = read(io, String)
    close(io)

    return split(x[1:(end - 2)], "\n")
end

using InlineStrings, Parameters

# @autodoc
@with_kw struct RosterInfo
    nchar      :: SVector{25, Int64}    = SVector{25, Int64}([13; 3; repeat([4], 2); repeat([3], 6); repeat([4], 15)])
    col_end    :: SVector{25, Int64}    = cumsum(nchar)
    col_start  :: SVector{25, Int64}    = col_end - nchar .+ 1
    pl_fill    :: SubString{String}     = SubString{String}("PLACEHOLDER   00 xxx   C  \
                                                            0  0  0  0  0  0 300 300 300 300   \
                                                            0   0   0   0   0   0   0   0   0   0 100")
    header_str :: SVector{2, String127} = SVector{2, String127}(["Name         \
                                                                Age Nat Prs St Tk Ps Sh Sm Ag KAb TAb PAb SAb \
                                                                Gam Sav Ktk Kps Sht Gls Ass  DP Inj Sus Fit",
                                                                "---------------------------------------------------\
                                                                ---------------------------------------------------"])
end




# @with_kw mutable struct League2
#     rosters  :: MVector{NTEAMS, Roster{SVector{30, String15}, SVector{30, Int16}}}   
#     teamshts :: MVector{NTEAMS, TeamSheet{SVector{11, String15}, SVector{5, String15}}}
#     comms    :: MVector{NTEAMS, Comms{SVector{16, String15}, SVector{16, Int16}, SVector{16, Float32}, SVector{16, Bool}}}    
#     wts      :: MVector{NTEAMS, Weights{Float32, Float32, SVector{16, Float32}}}  
# end

# function init_lg2(rpaths, tspaths)
#     League2(rosters  = MVector{NTEAMS}(parse_roster(rpaths[i])     for i in eachindex(rpaths)),
#             teamshts = MVector{NTEAMS}(parse_teamsheet(tspaths[i]) for i in eachindex(rpaths)),
#             comms    = MVector{NTEAMS}(Comms()                    for i in eachindex(rpaths)),
#             wts      = MVector{NTEAMS}(Weights(@SVector fill(0.0f0, NLINEUP)) for i in eachindex(rpaths)))
# end


# lg2 = init_lg2(rpaths, tspaths)

# @benchmark init_lg2($rpaths, $tspaths)


# function playgames2!(lg2, wk)
#     mat      = sched[wk]
#     rosters  = lg2.rosters
#     teamshts = lg2.teamshts
#     comms    = lg2.comms
#     wts      = lg2.wts
#     # Threads.@threads for tnames in eachrow(mat)
#     @batch for tnames in eachrow(mat)
#     # for tnames in eachrow(mat)
#         idx1 = teamdict[tnames[1]] :: Int64
#         idx2 = teamdict[tnames[2]] :: Int64
#         idx  = SVector{2, Int64}(idx1, idx2)

#         playgame2!(rosters, teamshts, comms, wts, idx1, idx2)
#         # comms = (comms[idx1], comms[idx2])

#         # update_lgTble!(lg_table, comms, idx1, idx2)
#         for j in 1:2
#             rosters[idx[j]]  = update_roster(rosters[idx[j]], comms[idx[j]])
#             teamshts[idx[j]] = update_teamsheet(rosters[idx[j]]; tactic = "N")
#         end
#     end
# end


# function playgame2!(rosters, teamshts, comms, wts, idx1, idx2)
#     makecomm!(comms[idx1], rosters[idx1], teamshts[idx1]);
#     makecomm!(comms[idx2], rosters[idx2], teamshts[idx2]);

#     comm1 = comms[idx1]
#     comm2 = comms[idx2]

#     calc_contribs!(comm1, comm2);
#     calc_contribs!(comm2, comm1);

#     # Same weights vector can be used for both teams
#     mainloop!(comm1, comm2, wts[idx1])
# end

# @benchmark playgames2!(x, 1) setup = (x = deepcopy($lg2)) evals = 1 seconds = 10


# @benchmark playgame2!(x.rosters, x.teamshts, x.comms, x.wts, $1, $11) setup = (x = deepcopy($lg2)) evals = 1 seconds = 10

# playgames2!(lg2, 1)
# rost2df(lg2.rosters[1])

# @benchmark makecomm!($lg2.comms[1], $lg2.rosters[1], $lg2.teamshts[1])


# lg2.comms[1].Name



# @with_kw mutable struct GameLogTeam
#     sav :: SVector{90, Int16} = @SVector fill(Int16(0), 90)
#     ktk :: SVector{90, Int16} = @SVector fill(Int16(0), 90)
#     sht :: SVector{90, Int16} = @SVector fill(Int16(0), 90)
#     kps :: SVector{90, Int16} = @SVector fill(Int16(0), 90)
#     gls :: SVector{90, Int16} = @SVector fill(Int16(0), 90)
#     yel :: SVector{90, Int16} = @SVector fill(Int16(0), 90)
#     red :: SVector{90, Int16} = @SVector fill(Int16(0), 90)
#     inj :: SVector{90, Int16} = @SVector fill(Int16(0), 90)
# end

# @with_kw  mutable struct GameLog
#     home :: GameLogTeam = GameLogTeam()
#     away :: GameLogTeam = GameLogTeam()
# end


# const gamelog = GameLog()


# function upgl(gamelog)
# gamelog.home.sht = @set $(gamelog.home.sht)[1] = 11
# end

# upgl(gamelog)

# @btime @reset $gamelog.home.sht[1] = 11
