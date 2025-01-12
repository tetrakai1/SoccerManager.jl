# SoccerManager.jl
A performant soccer manager simulator written in julia. Ported from https://github.com/eliben/esms.

```
# Start julia REPL (this includes threads and optimization flags for example)
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


Next navigate to the examples/playgames.jl script, change path_dest to an appropriate location for the data directory, and paste the first few lines into the REPL. This will copy default roster/etc files into the chosen directory:
```
julia> using InlineStrings

julia> using SoccerManager

julia> import SoccerManager: update_roster, lgrank!

       ############################
       ### Set up paths/configs ###
       ############################

       # Copy default roster/etc files from package into chosen data directory
       # The directory will be created if it doesn't exist or can be overwritten by setting force = true
       # WARNING: Overwriting the directory will delete all the contents
       # A tuple of useful paths is also returned

julia> path_dest = "/home/user/Documents/SoccerManagerData"
"/home/user/Documents/SoccerManagerData"

julia> paths     = init_user_data_dir(path_dest, force = false);
New data directory created at: /home/user/Documents/SoccerManagerData/data
```

Now it should be set up to try the rest of the example scripts. First change the datadir path in those scripts to the same one used above. Eg:

```
path_dest = "/home/user/Documents/SoccerManagerData"
```

Next time julia is started use the project flag to automatically activate the environment:
```
user@pc:~/path/to/package$ julia --project=. --threads=2 -O3
```

TODO:
1) Add minute-by-minute game log
2) Halftime (added minutes)
3) Activate "abilities" (ratings update during the season due to in-game performance)
4) Get real-life data
5) Unit tests

