push!(LOAD_PATH,"../src/")

using Documenter, SoccerManager

makedocs(sitename  = "Soccer Manager",
         modules   = [SoccerManager],
         checkdocs = :all,
         format = Documenter.HTML(collapselevel    = 1,
                                  sidebar_sitename = false,
                                  size_threshold   = 300_000),
        pages = ["Home" => "index.md"])
