
"""
    retrieve_rosters(paths, teamnames; force = false)

Copies the default roster files from the `/Roster0` directory to its parent `/roster` directory.

# Arguments
- `paths     :: NamedTuple{String}` : The various paths to rosters, teamsheets, etc
- `teamnames :: TeamNames`          : Vector of team names

# Kwargs
- `force :: Bool` : Whether to force overwriting existing files with the same names

# Returns
Nothing.

# See also
- Uses    : [`TeamNames`](@ref)
- Used by : [`FUNC`](@ref)
- Related : [`retrieve_teamsheets`](@ref), [`init_user_data_dir`](@ref)
"""
function retrieve_rosters(paths, teamnames; force = false)
        fnames = teamnames.*String15(".txt")
        for i in eachindex(fnames)
            src  = joinpath(paths.rosters0, fnames[i])
            dest = joinpath(paths.rosters,  fnames[i])
            cp(src, dest, force = force)
        end
        return nothing
end


"""
    retrieve_teamsheets(paths, teamnames; force = false)

Copies the default teamsheet files from the `/Teamsheet0` directory to its parent `/teamsheet` directory.

# Arguments
- `paths     :: NamedTuple{String}` : The various paths to rosters, teamsheets, etc
- `teamnames :: TeamNames`          : Vector of team names

# Kwargs
- `force :: Bool` : Whether to force overwriting existing files with the same names

# Returns
Nothing.

# See also
- Uses    : [`TeamNames`](@ref)
- Used by : [`FUNC`](@ref)
- Related : [`retrieve_rosters`](@ref), [`init_user_data_dir`](@ref)
"""
function retrieve_teamsheets(paths, teamnames; force = false)
        fnames = teamnames.*String15("sht.txt")
        for i in eachindex(fnames)
            src  = joinpath(paths.teamsheets0, fnames[i])
            dest = joinpath(paths.teamsheets,  fnames[i])
            cp(src, dest, force = force)
        end
        return nothing
end


"""
    init_user_data_dir(path_dest; force = false)

Copies the default data directory *from the package source directory* to one chosen by the user.

WARNING: If force == true, this deletes any existing files in the directory. If the directory already exists, an interactive prompt asks to confirm before doing so.

If the directory exists and force == false, then it only returns a set of paths.

# Arguments
- `path_dest :: String` : The destination data directory

# Kwargs
- `force :: Bool` : Whether to force overwriting existing files with the same names

# Returns
A `NamedTuple` of paths to the various data.

# See also
- Uses    : [`DATADIR0`](@ref)
- Used by : [`FUNC`](@ref)
- Related : [`retrieve_rosters`](@ref), [`retrieve_teamsheets`](@ref)
"""
function init_user_data_dir(path_dest; force = false)
    paths     = nothing
    path_data = joinpath(path_dest, "data")
    response  = "yes"

    # If directory exists and force = true then prompt before overwriting
    if isdir(path_data) && force
        println("--WARNING-- Existing contents of the following directory will be deleted: $path_data")
        println("Type yes to continue:")
        response = readline()
        if response == "yes"
            Base.Filesystem.cptree(DATADIR0, path_data; force = force)
        else
            println("Data directory not created")
        end

    # Create directory if it does not exist
    elseif !isdir(path_data)
        mkpath(path_dest)
        Base.Filesystem.cptree(DATADIR0, path_data; force = force)
        println("New data directory created at: $path_data")

    # Else data directory is unchanged
    elseif isdir(path_data) && !force
        println("Data directory unchanged at: $path_data")
        println("Set the kwarg force = true to overwrite")
    end

    if response == "yes"
        paths = (proj                   = path_dest,)
        paths = (paths ..., data        = path_data)
        paths = (paths ..., rosters     = joinpath(paths.data,       "rosters"))
        paths = (paths ..., teamsheets  = joinpath(paths.data,       "teamsheets"))
        paths = (paths ..., rosters0    = joinpath(paths.rosters,    "Rosters0"))
        paths = (paths ..., teamsheets0 = joinpath(paths.teamsheets, "Teamsheets0"))
        paths = (paths ..., tactics     = joinpath(paths.data,       "tactics.dat"))
        paths = (paths ..., league      = joinpath(paths.data,       "league.dat"))
    end

    return paths
end


