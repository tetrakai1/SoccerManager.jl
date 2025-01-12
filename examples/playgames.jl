using InlineStrings
using SoccerManager
import SoccerManager: update_roster, lgrank!

############################
### Set up paths/configs ###
############################

# Copy default roster files from package into chosen data directory if it doesn't exist
# Also generates a tuple of paths to be used later
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

##########################
### Play a single game ###
##########################

# Play a game between teams 1 and 11
TEAMNAMES[[1; 11]]
playgame!(lg_data.tv, 1, 11)

# Inspect the communications struct (containing the player-level game results) for team 1
struct2df(lg_data.tv[1].comm, 1:29)

# Update the roster for team 1
lg_data.tv[1].roster = update_roster(lg_data.tv[1].roster, lg_data.tv[1].comm);

# Inspect the updated roster for team 1
rost2df(lg_data.tv[1].roster)

# Reset the league to default values (will clear the above results)
reset_all!(lg_data)

############################
### Play a week of games ###
############################

# Play the games scheduled for week one of SCHED
SCHED[1]
playgames!(lg_data, SCHED[1]) 

# Inspect the updated roster for team 1
rost2df(lg_data.tv[1].roster)

# Inspect the updated league table
lgrank!(lg_data.lg_table, Val(length(lg_data.lg_table)))
sort(lgtble2df(lg_data.lg_table), :Pl)

# Play the games scheduled for week two of SCHED
SCHED[2]
playgames!(lg_data, SCHED[2]) 

# Inspect the updated results
rost2df(lg_data.tv[1].roster)
lgrank!(lg_data.lg_table, Val(length(lg_data.lg_table)))
sort(lgtble2df(lg_data.lg_table), :Pl)

# Reset the league to default values (will clear the above results)
reset_all!(lg_data)

##############################
### Play a season of games ###
##############################

# Play the entire season (schedule is store in lg_data)
playseason!(lg_data);

# Inspect the updated results
sort(lgtble2df(lg_data.lg_table), :Pl)
rost2df(lg_data.tv[1].roster)

# Save the updated rosters to the data directory chosen above
# N.B. This should not be in the package directory
save_rosters(rpaths, lg_data.tv)

# Save the updated league table
write_lg_table(paths.table, lg_data.lg_table)

# Reset the league to default values (will clear the above results)
reset_all!(lg_data)



