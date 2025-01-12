using BenchmarkTools, InlineStrings
using SoccerManager

############################
### Set up paths/configs ###
############################

# Copy default roster/etc files from package into chosen data directory
# The directory will be created if it doesn't exist or can be overwritten by setting force = true
# WARNING: Overwriting the directory will delete all the contents
# A tuple of useful paths is also returned 
path_dest = "/home/user1/Documents/SoccerManager"
paths     = init_user_data_dir(path_dest, force = false);

# Init various config structs
const TSCONF[]      = TeamSheetConfig();
const UPDATECONF[]  = UpdateConfig();
const TACTICSCONF[] = parse_tactics(paths.tactics);

# Read in teamnames from league.dat file and construct a schedule
const TEAMNAMES = parse_league(paths.league, 20);
const SCHED     = makeschedule(length(TEAMNAMES));

# Set some additional paths here
rpaths  = joinpath.(paths.rosters,    TEAMNAMES.*String15(".txt"));
tspaths = joinpath.(paths.teamsheets, TEAMNAMES.*String15("sht.txt"));

# Replace roster/teamsheet files with the defaults
retrieve_rosters(paths,    TEAMNAMES; force = true)
retrieve_teamsheets(paths, TEAMNAMES; force = true)

# Initialize the league struct from file and constants
lg_data = init_league(rpaths, tspaths, TEAMNAMES, SCHED)

###########################
### Selected Benchmarks ###
###########################

@benchmark init_tv($rpaths, $tspaths)
@benchmark init_lgtble($TEAMNAMES)
@benchmark playgame!(x, $1, $11)    setup = (x = deepcopy($lg_data.tv)) evals = 1 seconds = 10
@benchmark playgames!(x, $SCHED[1]) setup = (x = deepcopy($lg_data))    evals = 1 seconds = 10
@benchmark playseason!(x)           setup = (x = deepcopy($lg_data))    evals = 1 seconds = 10
@benchmark reset_all!(x)            setup = (x = deepcopy($lg_data))    evals = 1
@benchmark save_rosters($rpaths, $lg_data.tv)
