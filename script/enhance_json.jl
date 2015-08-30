#######################################################################
# packages.julialang.org
# enhance_json.jl
# Does the following
# - For every package, pull its description and star count, attach
#   to each packages entry in the JSON
# - Record the star counts
# - Produce .log and badge .svg files
# - Add the latest test results to history database
# - Write out the concatenated-description-enhanced JSON dicts out to
#   a file all.json
# Takes one command line argument - todays date, in the YYYYMMDD 
# format.
#######################################################################

import Requests
import JSON
import MetadataTools
include("PackageFuncs.jl")
using PackageFuncs

if length(ARGS) != 1
    error("Need to provide date! YYYYMMDD")
end
datestr = ARGS[1]

# Load all the results
#=
println("Parsing RAL")
RAL = JSON.parsefile("releaseAL.json")
println("Parsing RMZ")
RMZ = JSON.parsefile("releaseMZ.json")
println("Parsing NAL")
NAL = JSON.parsefile("nightlyAL.json")
println("Parsing NMZ")
NMZ = JSON.parsefile("nightlyMZ.json")
all_pkgs = vcat(RAL,RMZ,NAL,NMZ)
=#
R = JSON.parsefile("release.json")
N = JSON.parsefile("nightly.json")
all_pkgs = vcat(R,N)
println("Done parsing")

# Load GitHub auth token (NOT CHECKED IN!!)
const auth_token = readall("token")

# Load METADATA into memory, get deprecations and GitHub data
metadata_pkgs = MetadataTools.get_all_pkg()
deprecations = Dict()
pkg_infos = Dict()
for pkg_meta in values(metadata_pkgs)
    ul = MetadataTools.get_upper_limit(pkg_meta)
    deprecations[pkg_meta.name] = (ul != v"0.0.0")
    pkg_infos[pkg_meta.name] = MetadataTools.get_pkg_info(pkg_meta,token=auth_token)
end

# Update star history
star_fp = open("../db/star_db.csv","a")  # APPEND
for pkg_meta in values(metadata_pkgs)
    println(star_fp, string(
                datestr, ", ", 
                lpad(pkg_meta.name,30," "), ",",
                lpad(string(pkg_infos[pkg_meta.name].stars),5," ") ))
end
close(star_fp)

# Open up test history file
hist_fp = open("../db/hist_db.csv","a")  # APPEND

# Note: will repeat for the release and nightly entry
for pkg in all_pkgs
    # Add description and stars to the JSON
    if pkg["name"] in keys(pkg_infos)
        pkg["githubdesc"]  = pkg_infos[pkg["name"]].description
        pkg["githubstars"] = pkg_infos[pkg["name"]].stars
    else
        pkg["githubdesc"]  = "No description available."
        pkg["githubstars"] = 0
    end

    # Get _stable or _nightly
    jlvertype = pkg["jlver"]
    jlvertype_old = (pkg["jlver"] == STABLEVER) ? "release" : "nightly"

    # Make badge
    source_file = joinpath("..", "badgesrc", string(pkg["status"],"_",jlvertype,".svg"))
    dest_file   = joinpath("..", "badges", string(pkg["name"],"_",jlvertype,".svg"))
    dest_file_old = joinpath("..", "badges", string(pkg["name"],"_",jlvertype_old,".svg"))
    run(`cp $(source_file) $(dest_file)`)
    run(`cp $(source_file) $(dest_file_old)`)

    # Make log file
    log_file = joinpath("..", "logs", string(pkg["name"],"_",jlvertype,".log"))
    logfp = open(log_file,"w")
    println(logfp, pkg["log"])
    close(logfp)

    # Add deprecation notice
    try
        pkg["deprecated"] = deprecations[pkg["name"]]
    catch
        println("Didn't figure out deprecation for $(pkg["name"])")
        pkg["deprecated"] = false
    end

    # Update history
    datestr == "nohist" && continue 
    println(hist_fp,datestr         * ", " * 
                    pkg["jlver"]    * ","  *
                    lpad(pkg["name"],   30," ") * ","  *
                    lpad(pkg["version"],10," ") * ", " *
                    pkg["status"])
end

# Output new combined JSON
fp = open("all.json","w")
print(fp, JSON.json(all_pkgs))
close(fp)

# Update history file
close(hist_fp)