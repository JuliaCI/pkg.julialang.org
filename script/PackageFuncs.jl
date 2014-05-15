module PackageFuncs

    export STABLEVER, NIGHTLYVER
    const STABLEVER  = "0.2"
    const NIGHTLYVER = "0.3"

    # HUMANSTATUS
    # Human-readable versions of the test codes
    export HUMANSTATUS
    const HUMANSTATUS = [
        "full_pass" => "Tests pass.",
        "full_fail" => "Tests fail, but package loads.",
        "using_pass" => "No tests, but package loads.",
        "using_fail" => "Package doesn't load.",
        "not_possible" => "Package was untestable."]

    # create_hist_db
    # Load the history database CSV, turn it into a dictionary keyed on
    # the package name and the Julia version
    # Returns 
    #  - Dictionary keyed on a string "$jlver$pkgname" with value being
    #    a matrix [dates pkgver status] sorted so most recent is at top
    #  - a set of all package names seen
    #  - a set of all dates seen
    export create_hist_db
    function create_hist_db()
        all_hist = readcsv("../db/hist_db.csv", String)
        # Remove all the whitespace
        map!(strip, all_hist)
        # Form the dictionaries
        hist_db  = Dict()
        pkg_set  = Set()
        date_set = Set()
        for row in 1:size(all_hist,1)
            col_DATE    = all_hist[row,1]
            col_JLVER   = all_hist[row,2]
            col_NAME    = all_hist[row,3]
            col_PKGVER  = all_hist[row,4]
            col_STATUS  = all_hist[row,5]
            key         = col_JLVER * col_NAME
            value       = [col_DATE col_PKGVER col_STATUS]

            hist_db[key] = key in keys(hist_db) ? 
                            vcat(hist_db[key], value) :
                            value
            push!(pkg_set,  col_NAME)
            push!(date_set, col_DATE)
        end
        # Sort by descending dates
        for key in keys(hist_db)
            val = hist_db[key]
            hist_db[key] = val[sortperm(val[:,1], rev=true),:]
        end
        return hist_db, pkg_set, sort(collect(date_set),rev=true)
    end

end