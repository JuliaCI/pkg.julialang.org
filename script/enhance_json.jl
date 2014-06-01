#######################################################################
# packages.julialang.org
# enhance_json.jl
# Does the following
# - Take the stable and nightly results and concatenate them into one
#   list of JSON dicts
# - For every package, pull its description from Github and place it
#   in the JSON dict
# - Produce .log and badge .svg files
# - Add the latest test results to history database
# - Write out the concatenated-description-enhanced JSON dicts out to
#   a file all.json
# Takes one command line argument - todays date, in the YYYYMMDD 
# format.
#######################################################################

using JSON

# Produce concatenated file
stable   = readall("stable.json")
nightly  = readall("nightly.json")
combined = "[" * stable * "," * nightly * "]"
all_pkgs = JSON.parse(combined)

# Load GitHub auth token (NOT CHECKED IN!!)
auth_token = readall("token")

# Open up history file
if length(ARGS) != 1
    error("Need to provide date! YYYYMMDD")
end
datestr = ARGS[1]
hist_fp = open("../db/hist_db.csv","a")  # APPEND

for pkg in all_pkgs
    # Add description from Github
    if !("githubdesc" in keys(pkg))
        url_split = split(pkg["url"], "/")
        github_url = "https://api.github.com/repos/$(url_split[end-1])/$(url_split[end])?access_token=$(auth_token)"
        github_resp = JSON.parse(readall(download(github_url)))
        pkg["githubdesc"] = get(github_resp, "description", "No description available.")
    end

    # Make badge
    source_file = joinpath("..", "badges", string(pkg["status"],".svg"))
    dest_file   = joinpath("..", "badges", string(pkg["name"],"_",pkg["jlver"],".svg"))
    run(`cp $source_file $dest_file`)

    # Make log file
    log_file = joinpath("..", "logs", string(pkg["name"],"_",pkg["jlver"],".log"))
    logfp = open(log_file,"w")
    println(logfp, pkg["testlog"])
    close(logfp)

    # Update history
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