# SoccerManager.jl
A performant soccer simulator for gaming and ML. Based on [ESMS](https://github.com/eliben/esms).

The game consists of (human or "AI") players submitting [teamsheets](data/teamsheets/apesht.txt) to select footballers from a [roster](data/rosters/ape.txt). The data for a pair of teams is then plugged into a game engine that pseudo-randomly chooses whether there was a shot, tackle, injury, etc each minute of the game. The results depend on the player ratings, but are also very sensitive to fatigue and the tactics (Attacking, Defensive, etc) used by each team.

Tuning the ratings of each player so the engine outputs realistic results is a non-trivial optmization problem. For a single league of 20 teams consisting of 30 players each, there are `20*30*6 = 3600` interdependent ratings to fit. The ratings are discrete values constrained between 1 and 99, which also poses a difficulty for many optimization algorithms.

Thus, the problem is high-dimensional, stochastic, discrete, and constrained. When simulating baseline data from the engine itself, the correct answer is also known. These are properties that could make it an interesting optimization/machine-learning benchmark.

The ultimate goal, however, is an open-source game that can realistically track the real-life performance of many leagues worth of players, over multiple seasons, according to a predetermined algorithm.

To that end, the original game was rewritten in Julia with a focus on performance (~1000x faster). Besides more efficiently tuning the ratings, this package could also serve as a base for developing a more realistic engine.

## Installation
#### Unregistered private repo
```bash
# After cloning/downloading repo
# Start Julia REPL (threads and optimization arguments are included as an example)
user@pc:~/path/to/package$ julia --threads=2 -O3

# Enter the package manager REPL using the closing square bracket
julia> ]

# Activate the SoccerManager package
(@v1.11) pkg> activate .
  Activating project at `~/path/to/package`

# Check package status. It should look like this (also note the new prompt):
(SoccerManager) pkg> status
Project SoccerManager v0.1.0
Status `~/path/to/package/Project.toml`
  [7d9f7c33] Accessors
  [a93c6f00] DataFrames
  [31c24e10] Distributions
  [1fa38f19] Format
  [842dd82b] InlineStrings
  [d96e819e] Parameters
  [f517fe37] Polyester
  [90137ffa] StaticArrays
  [2913bbd2] StatsBase
  [f3b207a7] StatsPlots
  [b8865327] UnicodePlots

# Instantiate the package (download the dependencies)
(SoccerManager) pkg> instantiate

# Return to the normal REPL with backspace
(SoccerManager) pkg> [backspace]
```

### Set up data directory
Next navigate to the [setup_datadir.jl](examples/setup_datadir.jl) script and open with a text editor, change `path_datadir` to an appropriate location for the data directory, and paste into the REPL. This will copy default roster/etc files into the chosen directory:
```julia
julia> using SoccerManager

       # Copy default roster/etc files from package into chosen data directory
       # The directory will be created if it doesn't exist or can be overwritten by setting force = true
       # WARNING: Overwriting the directory will delete all the contents

julia> path_datadir = "/home/user1/Documents/SoccerManager"
"/home/user1/Documents/SoccerManager"

julia> paths        = init_user_data_dir(path_datadir, force = false);
New data directory created at: /home/user1/Documents/SoccerManager/data

       # Save the path for use by the other example scripts
julia> write("examples/path_datadir.txt", path_datadir)
38

```

Exit the Julia REPL using `ctrl-d`.

Now the examples can be run. They are meant to be run interactively in the REPL, each in a fresh Julia session. NB: These scripts require that the data directory has been created and the path saved to `examples/path_datadir.txt`.

Next time Julia is started use the `--project=.` argument to automatically activate the environment:
```bash
user@pc:~/path/to/package$ julia --project=. --threads=2 -O3
```

The current environment can be double-checked using the package manager REPL prompt. It should be:
```bash
# Enter the package manager REPL using the closing square bracket
julia> ]
(SoccerManager) pkg> 
```

## Examples
### [setup_datadir.jl](examples/setup_datadir.jl)
- Short script for setting up the user data directory

### [benchmarks.jl](examples/benchmarks.jl)
- Benchmarks for the higher-level functions (eg, reading/writing league data from file or playing an entire season)
    - There will be a prompt to install `BenchmarkTools` if it is not already present

### [playgames.jl](examples/playgames.jl)
- Demonstrates how to play a single game, week of games, or an entire season at once
    - This script is meant to be run line-by-line

### [fitratings.jl](examples/fitratings.jl)
- Demonstrates a simple threshold acceptance algorithm for using season-end stats to optimize player ratings

## Tips
### Multi-threading
- The `@multi` macro defined in [SoccerManager.jl](src/SoccerManager.jl) can be used to switch between multi-threading libraries at compile time. Use `@batch` unless nesting multiple multi-threaded loops (then use `@threads`).
- Set the `--threads` command-line argument to the number of physical cores, not threads
- A league of 20 teams can play only 10 games in parallel, so unless nesting inside an outer loop `@batch` is best and only 10 threads are needed
- On the other hand, the algorithm in the [fitratings.jl](examples/fitratings.jl) script plays multiple replicates of the same season in parallel to average out the random variation. For this usecase `@threads` is best, and at least `nreps*nteams/2` threads is ideal. 
    - NB: Due to the composability of `@threads`, performance can still benefit from multi-threading even if oversubscribed.

## Performance Benchmarks
#### System Specs
```bash
Julia Version 1.11.2
Commit 5e9a32e7af2 (2024-12-01 20:02 UTC)
Build Info:
  Official https://julialang.org/ release
Platform Info:
  OS: Linux (x86_64-linux-gnu)
  CPU: 64 × AMD Ryzen Threadripper 2990WX 32-Core Processor
  WORD_SIZE: 64
  LLVM: libLLVM-16.0.6 (ORCJIT, znver1)
Threads: 32 default, 0 interactive, 16 GC (on 64 virtual cores)
```
#### Single game
`50.991 μs (0 allocations: 0 bytes)`
#### Season with 20 teams (38 games each)
- `@threads:` `13.545 ms (6231 allocations: 850.22 KiB)`
- `@batch  :` `5.211  ms (113  allocations: 29.06 KiB)`

## ML Benchmarks
The algorithm in [fitratings.jl](examples/fitratings.jl) was used to select player *skill ratings* according to how well the season-end stats fit those from a baseline/ground-truth season. 

The left plot shows the random variation when replaying a season using the same ratings. This corresponds to the best fit possible given the randomness in the game engine.

For the right plot, threshold-acceptance was used to choose ratings without knowledge of the true values (as would be the case when comparing to real-life data).

The bottom plot shows the algorithm tuning the ratings. The target corresponds to baseline variation.
<table>
  <tr>
    <td align="center">Baseline Variation</td>
    <td align="center">Example Fit</td>
  </tr>
  <tr>
    <td><img src="/docs/src/figures/Baseline.png" width="450" height="300"></td>
    <td><img src="/docs/src/figures/Fit.png"      width="450" height="300"></td>
  </tr>
    <tr>
      <td colspan="2" align="center"><img src="/docs/src/figures/Error.png" width="450" height="300"></td>
    </tr>
 </table>

## TODO
1. Minute-by-minute game log
2. Halftime (added minutes)
3. Activate "abilities" (ratings update during the season due to in-game performance)
4. Improve tactics/teamsheet AI
5. Add situations (planned/conditional subs and tactics)
6. Unit/integration/performance tests
7. Get real-life data
8. More ML algorithms
9. Run on GPU
10. Multiple leagues in parallel
11. Multiple seasons sequentially
12. Simulate transfer market activity
