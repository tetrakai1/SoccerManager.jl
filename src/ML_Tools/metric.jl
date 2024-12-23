
"""
    calc_metric(baseline, sims)

Calculates the mean RMSE (root-mean-squared-error) per team. 

One or more simulated replicates are contained in `sims`, then all are compared to the same `baseline` season.

# Arguments
- `baseline :: LeagueData` : The baseline (ground truth) league
- `sims     :: Sims`       : One or more simulated leagues

# Returns
A `Float32` RMSE value.

# See also
- Uses    : [`LeagueData`](@ref), [`Sims`](@ref), [`getfield_unroll`](@ref) 
- Used by : [`FUNC`](@ref)
- Related : [`FUNC`](@ref)
"""
function calc_metric(baseline, sims)
    nteams    = length(baseline.tv)
    nreps     = length(sims)
    pl_fields = (:Gam, :Sav, :Ktk, :Kps, :Sht, :Gls, :Ass, :DP)
    tm_fields = (:Pl, :W, :D, :L, :GF, :GA, :GD, :Pts)

    sumSq = 0
    for sim in sims
        # Player Stats
        for i in eachindex(pl_fields)
            for j in eachindex(baseline.tv)
                x = getfield_unroll(baseline.tv[j].roster, pl_fields[i])
                y = getfield_unroll(sim.tv[j].roster,      pl_fields[i])
                sumSq += sum(abs2.(Int64.(x - y)))
            end
        end

        # Team Stats
        for i in eachindex(tm_fields)
            for j in eachindex(baseline.lg_table)
                x = getfield_unroll(baseline.lg_table[j], tm_fields[i])
                y = getfield_unroll(sim.lg_table[j],      tm_fields[i])
                sumSq += sum(abs2(Int64(x - y)))
            end
        end
    end

    # Refers to RMSE per team (not total number of variables)
    RMSE = sqrt(sumSq/(nteams*nreps))

    return Float32(RMSE)
end
