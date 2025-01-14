"""
    printlog(i, rmselog, init_time, rmse_best, rmse_last, thresh)

Prints the current progress of the fitting algorithm.

# Arguments
- `i         :: Int`                   : Index of the last step
- `rmselog   :: Vector{Float32, Bool}` : RMSE and accept-flag for each step
- `init_time :: Float64`               : The system time at the start of the run (ie, using `time`)
- `rmse_best :: Tuple{Int, Float32}`   : Index and RMSE of the best so-far step
- `rmse_last :: Tuple{Int, Float32}`   : Index and RMSE of the last accepted step
- `thresh    :: Float`                 : The accept-threshold used for the last step

# Returns
Nothing. Prints line to REPL.

# See also
- Uses    : [`FUNC`](@ref)
- Used by : [`FUNC`](@ref)
- Related : [`FUNC`](@ref)
"""
function printlog(i, rmselog, init_time, rmse_best, rmse_last, thresh)
    secstep = (time() - init_time)/i
    accrate = mean(rmselog[j][2] for j in 1:i)
    toprint = (i, rmselog[i][1], secstep, rmse_best..., rmse_last..., thresh, accrate)

    pads = (ifelse(rmselog[i][1] >= 100, 12, 11) + ndigits(i), 
            ifelse(rmse_best[2]  >= 100, 11, 10) + ndigits(rmse_best[1]), 
            ifelse(rmse_last[2]  >= 100, 11, 10) + ndigits(rmse_last[1]))

    header = rpad(" Last-Step",  pads[1]) * "Time(s) " * 
             rpad("Best-Step",   pads[2]) * 
             rpad("Last-Accept", pads[3]) * "Thresh  AccRate"

    println(header)
    println(toprint)
end



"""
    plotlog(rmselog, target, idx; kwargs)

Plots the progress of the algorithm fitting.

Eg, RMSE vs step index.

# Arguments
- `rmselog :: Vector{Float32, Bool}` : RMSE and accept-flag for each step
- `target  :: Float`                 : A target RMSE value
- `idx     :: Int`                   : Index of the last completed step

# Kwargs
- `kwargs :: Tuple` : Kwargs to be passed to plotting functions

# Returns
Nothing. Plots (a unicode plot) to REPL.

# See also
- Uses    : [`FUNC`](@ref)
- Used by : [`FUNC`](@ref)
- Related : [`FUNC`](@ref)
"""
function plotlog(rmselog, target, idx; kwargs...)
    rmsevals  = [rmselog[j][1]        for j in idx]
    idx_flags = findall(rmselog[j][2] for j in idx)
    ylim      = extrema([target; rmsevals])
    xvals     = idx_flags .+ idx[1] .- 1
    yvals     = rmsevals[idx_flags]

    p1 = lineplot(idx, rmsevals;     color = :cyan, ylim = ylim, blend = false, kwargs...)
    p1 = lineplot!(p1, xvals, yvals; color = :red)
    p1 = hline!(p1, [target];        color = :green)
    display(p1)
end


"""
    plot_player_panels(flatbase, flatsim; title = )

Creates scatter plots of the player stats in the baseline vs "simulated" (with fit ratings) leagues.

Stats plotted:
- Gam : Games 
- Sav : Saves 
- Ktk : Tackles 
- Kps : Passes 
- Sht : Shots 
- Gls : Goals 
- Ass : Assists 
- DP  : Disciplinary Points


# Arguments
- `flatbase :: DataFrame` : Flattened (one player from the league in each row) baseline league
- `flatsim  :: DataFrame` : Flattened (one player from the league in each row) comparison league

# Kwargs
- `title :: String : Overall title of the panel plot

# Returns
An array of scatterplots.

# See also
- Uses    : [`FUNC`](@ref)
- Used by : [`stat_scatter`](@ref)
- Related : [`FUNC`](@ref)
"""
function plot_player_panels(flatbase, flatsim; title = "")
    fields    = (:Gam, :Sav, :Ktk, :Kps, :Sht, :Gls, :Ass, :DP)
    statnames = ("Games", "Saves", "Tackles", "Passes", "Shots", "Goals", "Assists", "DPs")
    namedict  = Dict(fields .=> statnames)

  plot_array = []
  for i in fields
    xylim    = MVector(extrema([flatbase[:, i]; flatsim[:, i]]))
    xylim[2] = ceil(1.05*xylim[2])
    xylim[1] = floor(xylim[1] - 0.05*xylim[2])

    push!(plot_array,
          scatter(flatbase[:, i], flatsim[:, i], 
                  xlim          = xylim,
                  ylim          = xylim,
                  group         = flatbase.Team,
                  markersize    = 2,
                  legend        = false,
                  title         = namedict[i],
                  titlefontsize = 7))
    plot!(x -> x, ls = :dash, color = :gray)
  end

  p = plot(plot_array..., plot_title = title, plot_titlefontsize = 8, dpi = 300)

  return p
end

"""
    stat_scatter(lg_data1, lg_data2)

Plots player stats in `lg_data1` vs `lg_data2`.

The selected stats are described in `plot_player_panels`.

# Arguments
- `lg_data1 :: LeagueData` : The baseline (ground truth) league
- `lg_data2 :: LeagueData` : The simulated (comparison) league

# Returns
A panel of scatterplots.

# See also
- Uses    : [`LeagueData`](@ref), [`flatten_rosters`](@ref), [`plot_player_panels`](@ref)
- Used by : [`FUNC`](@ref)
- Related : [`FUNC`](@ref)
"""
function stat_scatter(lg_data1, lg_data2)
    nteams   = length(lg_data1.teamnames)
    flatbase = flatten_rosters(lg_data1, Val(nteams))
    flatsim  = flatten_rosters(lg_data2, Val(nteams))
    pl       = plot_player_panels(flatbase, flatsim; title = "")
    display(plot(pl))

    return pl
end


"""
    plot_error(rmselog, target, idx, nreps, elapsed)

Plots the error curve of a fit.

# Arguments
- `rmselog :: Vector{Float32, Bool}` : RMSE and accept-flag for each step
- `target  :: Float`                 : A target RMSE value
- `idx     :: Int`                   : Index of the last completed step
- `nreps   :: Int`                   : Number of repetitions used
- `elapsed :: Float64`               : Minutes elapsed

# Returns
A plot of the error vs step.

# See also
- Uses    : [`FUNC`](@ref)
- Used by : [`FUNC`](@ref)
- Related : [`FUNC`](@ref)
"""
function plot_error(rmselog, target, idx, nreps, elapsed)
    nsteps    = length(idx)
    idx_flags = findall(rmselog[j][2] for j in idx)
    rmsevals  = [rmselog[j][1] for j in idx]

    ylim  = extrema([.95*target; rmsevals])
    xvals = idx_flags .+ idx[1] .- 1
    yvals = rmsevals[idx_flags]

    subtitle = "(nsteps = " * cfmt("%\'d", nsteps) * 
               ", nreps = " * string(nreps) * 
               ", elapsed = " * string(round(elapsed, digits = 1)) *" min)"
    p1 = plot(idx, rmsevals; 
              color         = :cyan, 
              ylim          = ylim, 
              legend        = false, 
              gridalpha     = 0.5,
              xscale        = :log10,
              xticks        = 10 .^ collect(0:ceil(log10(nsteps))),
              ylab          = "RMSE (per team)", 
              title         = "Error Curve\n"*subtitle,
              titlefontsize = 10)
    p1 = plot!(p1, xvals, yvals; color = :red)
    p1 = sp_hline!(p1, [target]; color = :green)
    annotate!(2, target, text("Target", :green, :bottom, 12))

    display(plot(p1))

    return p1
end
