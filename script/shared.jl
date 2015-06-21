using Dates
using JSON

const ALLJSON_FILE = "/Users/idunning/Dropbox/Websites/packages.julialang.org/script/all.json"
const HIST_FILE    = "/Users/idunning/Dropbox/Websites/packages.julialang.org/db/hist_db.csv"
const STAR_FILE    = "/Users/idunning/Dropbox/Websites/packages.julialang.org/db/star_db.csv"

const HUMANSTATUS = [
        "tests_pass"    => "Tests pass.",
        "tests_fail"    => "Tests fail.",
        "no_tests"      => "No tests detected.",
        # OLD STATUS
        "full_pass"     => "Tests pass.",
        "full_fail"     => "Tests fail, but package loads.",
        "using_pass"    => "No tests, but package loads.",
        "using_fail"    => "Package doesn't load.",
        "not_possible"  => "Package was untestable.",
        "new_pkg"       => "N/A - new package."]
const DBSTATUSCODES = ["full_pass","full_fail","using_pass",
                        "using_fail","not_possible",
                        "tests_pass","tests_fail","no_tests",
                        "total"]

type PkgTestResult
    date
    pkgver
    status
end
Base.isless(a::PkgTestResult,b::PkgTestResult) = Base.isless(a.date,b.date)

# load_hist_db
# Given the package listing history database filename, 
# produces:
#  - an dictionary (key: Julia version) of dictionaries
#    (key: package name) of arrays of test results.
#  - an array of all packages seen in the file
#  - an array of all dates seen in the file.
function load_hist_db(hist_file)
    # Load CSV
    all_hist = readcsv(hist_file, String)
    # Remove all the whitespace
    map!(strip, all_hist)
    # Store results in a dictionary keyed on Julia version
    # Each Julia version has an dictionary keyed on package
    # names, with values being an array of PkgTestResult
    hist = ["0.2"=>Dict(),
            "0.3"=>Dict(),
            "0.4"=>Dict()]
    # Also track a set of all dates ever seen, and a set of
    # all package names seen
    pkgnames = Set()
    dates = Set()
    # Iterate through all rows of the history
    for row in 1:size(all_hist,1)
        date    = all_hist[row,1]  # Format: YYYYMMDD
        jlver   = all_hist[row,2]
        pkgname = all_hist[row,3]
        pkgver  = all_hist[row,4]
        status  = all_hist[row,5]
        # Create the result
        result  = PkgTestResult(date,pkgver,status)
        # Check if a dictionary has an entry for this
        # package yet
        if pkgname in keys(hist[jlver])
            push!(hist[jlver][pkgname], result)
        else
            hist[jlver][pkgname] = [result]
        end
        # Update the sets
        push!(pkgnames, pkgname)
        push!(dates, date)
    end
    # For convenience, we sort entries for every package
    # in descending order of dates
    for ver in keys(hist)
        for pkgname in keys(hist[ver])
            sort!(hist[ver][pkgname], rev=true)
        end
    end
    # Return arrays instead of sets
    return hist,
            sort(collect(pkgnames)),  # alphabetical
            sort(collect(dates),rev=true)  # from present to past
end


# load_star_db
# Given the package listing star database filename, 
# produces:
#  - an dictionary (key: package name) of arrays 
#    of stars by date.
#  - an array of all dates seen in the file.
function load_star_db(hist_file)
    # Load CSV
    all_hist = readcsv(hist_file, String)
    # Remove all the whitespace
    map!(strip, all_hist)
    # Store results in a dictionary keyed on on package
    # names, with values being an array of (date,stars)
    hist = Dict()
    # Also track a set of all dates ever seen
    dates = Set()
    # Iterate through all rows of the history
    for row in 1:size(all_hist,1)
        date    = all_hist[row,1]  # Format: YYYYMMDD
        pkgname = all_hist[row,2]
        stars   = int(all_hist[row,3])
        # Create the result
        result  = (date,stars)
        # Check if a dictionary has an entry for this
        # package yet
        if pkgname in keys(hist)
            push!(hist[pkgname], result)
        else
            hist[pkgname] = [result]
        end
        # Update the sets
        push!(dates, date)
    end
    # For convenience, we sort entries for every package
    # in descending order of dates
    for pkgname in keys(hist)
        sort!(hist[pkgname], rev=true)
    end
    # Return arrays instead of sets
    return hist, sort(collect(dates),rev=true)  # from present to past
end


# total_pkgs_by_date
# Given the output of load_hist_db, produces a dictionary
# of totals of package count for each Julia version by
# date and package testing status (as well as a total).
function total_pkgs_by_date(hist, pkgnames, dates)
    totals = Dict()
    for ver in keys(hist)
        totals[ver] = [date => ["full_pass"     => 0,
                                "full_fail"     => 0,
                                "using_pass"    => 0,
                                "using_fail"    => 0,
                                "not_possible"  => 0,
                                "tests_pass"    => 0,
                                "tests_fail"    => 0,
                                "no_tests"      => 0,
                                "total"         => 0] for date in dates]
        for pkg in pkgnames
            !(pkg in keys(hist[ver])) && continue
            results = hist[ver][pkg]
            for r in results
                totals[ver][r.date][r.status] += 1
                totals[ver][r.date]["total"]  += 1
            end
        end
    end
    return totals
end


# total_stars_by_date
# Given the output of load_star_db, produces a dictionary
# of totals of stars by date.
function total_stars_by_date(hist, dates)
    totals = [d => 0 for d in dates]
    for pkg in keys(hist)
        for (date,stars) in hist[pkg]
            totals[date] += stars
        end
    end
    return totals
end


# dbdate_to_date
# Takes a database YYYYMMDD date and turns it into
# a Date instance
dbdate_to_date(dbdate) =
    Date(int(dbdate[1:4]),int(dbdate[5:6]),int(dbdate[7:8]))