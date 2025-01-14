using Accessors, Format, InlineStrings, Printf, StaticArrays, StatsPlots
using SoccerManager
theme(:solarized)

############################
### Set up paths/configs ###
############################

# Paths used to access the data directory structure
path_datadir = read("examples/path_datadir.txt", String)
paths        = get_data_paths(path_datadir);

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

#############################
### Threshold Acceptance  ###
#############################

# Hyperparameters
nreps    = 64
nsteps   = 100_000
thresh   = thresh0 = 0.1
threshd  = 0.01
stepsize = stepsize0 = Int16(1)

# Generate Baseline Stats
nteams   = length(rpaths)
baseline = init_league(rpaths, tspaths, TEAMNAMES, SCHED);
playseason!(baseline);

# Get baseline rmse (using the same skill ratings)
sims = init_sims(rpaths, tspaths, TEAMNAMES, SCHED, nreps);
playreps!(sims);
rmse_base = calc_metric(baseline, sims)
stat_scatter(baseline, sims[1])

# Initialization
# init_rand_ratings!(sims);
init_percent_ratings!(sims, baseline, Val(length(baseline.tv)));

rmse_best = (1, Inf);
rmse_last = (1, Inf);
sims_last = deepcopy(sims);
sims_best = deepcopy(sims);
rmselog   = [(Float32(0), false) for _ in 1:nsteps];
init_time = time();
Base.show(io::IO, f::Float64) = @printf(io, "%.4f", f)
Base.show(io::IO, f::Float32) = @printf(io, "%.3f", f)
for i in 1:nsteps

    # Play the games
    reset_sims!(sims)
    playreps!(sims)

    # Calculate RMSE and compare to threshold
    rmse = calc_metric(baseline, sims)
    flag = rmse < rmse_last[2] + thresh
    if flag
        # Store rosters if its the best step so far
        if rmse < rmse_best[2] && i > 1
            rmse_best = (i, rmse)
            sims_best = deepcopy(sims)
            stat_scatter(baseline, sims_best[1])
        end
        # Update rosters from this step (new ratings are sampled from uniform +/-1)
        # Only decrement threshold when a better fit was found
        rmse_last = (i, rmse)
        thresh    = max(thresh - threshd, 0.001)
        sims_last = deepcopy(sims)
        update_ratings!(sims, stepsize)
    else
        # Update rosters from previous accepted step (new ratings are sampled from uniform +/1)
        # Restart from best result if too many steps elapsed without progress
        if i - rmse_last[1] <= 100
            update_ratings!(sims, sims_last, stepsize)
            stepsize  = max(stepsize - Int16(1), Int16(1))
        else
            thresh    = thresh0
            stepsize  = stepsize0
            rmse_last = (1, Inf)
            sims      = deepcopy(sims_best)
        end
    end

    # Save results
    rmselog[i] = (rmse, flag)

    # Print results to terminal
    if i % 100 == 0
        printlog(i, rmselog, init_time, rmse_best, rmse_last, thresh)

        idx1 = 1:i; idx2 = max(1, i - 1000):i
        plotlog(rmselog, rmse_base,    idx1; height = 8,  width = 20, yscale = :log10)
        plotlog(rmselog, rmse_best[2], idx2; height = 15, width = 40)

        # Use Linux "watch" in a terminal to spot/sanity-check rosters
        save_rosters(rpaths, sims[1].tv)
    end
end
elapsed = (time() - init_time)/60

# Plot error curve
# plot_error(rmselog, rmse_base, 1:nsteps, nreps, elapsed)