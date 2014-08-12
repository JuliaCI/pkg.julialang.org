#######################################################################
# packages.julialang.org
# enhance_json.jl
# Does the following
# - Take the stable and nightly results and concatenate them into one
#   list of JSON dicts
# - For every package, pull its description from Github and place it
#   in the JSON dict (use a cache to reduce repeated effort)
# - Produce .log and badge .svg files
# - Add the latest test results to history database
# - Write out the concatenated-description-enhanced JSON dicts out to
#   a file all.json
# Takes one command line argument - todays date, in the YYYYMMDD 
# format.
#######################################################################

import Requests
import JSON
import PackageEvaluator.MetaTools
using PackageFuncs

raw_json = readall("all.json")
clean_json = replace(raw_json, "\\e", "")
clean_json = replace(clean_json, "\\u", "\\\\u")
clean_json = replace(clean_json, "\\x", "escx")
clean_json = replace(clean_json, "\\e", "\\\\e")
clean_json = replace(clean_json, "\\0", "\\\\0")
clean_json = ascii(map(c->(c>=128 ? 'a' : c), bytestring(clean_json)))
all_pkgs = JSON.parse("["*clean_json*"]")

# Load GitHub auth token (NOT CHECKED IN!!)
const auth_token = readall("token")

# Load description/star cache
desc_cache = Dict()
star_cache = Dict()
cache_fp = open("../db/descriptions","r")
for line in readlines(cache_fp)
    spl = split(line,"#####")
    length(spl) < 3 && continue
    desc_cache[spl[1]] = chomp(spl[2])
    star_cache[spl[1]] = int(chomp(spl[3]))
end
close(cache_fp)

# Load METADATA into memory, get deprecations
metadata_pkgs = MetaTools.get_all_pkg(Pkg.dir("METADATA"))
deprecations = Dict()
for pkg_meta in metadata_pkgs
    ul = MetaTools.get_upper_limit(pkg_meta)
    deprecations[pkg_meta.name] = (ul != v"0.0.0")
end

# Open up history file
if length(ARGS) != 1
    error("Need to provide date! YYYYMMDD")
end
datestr = ARGS[1]
hist_fp = open("../db/hist_db.csv","a")  # APPEND

star_counts = {}

# Note: will repeat for the release and nightly entry
for pkg in all_pkgs
    
    if pkg["jlver"] == "0.4"
        # TEMP HACK
        pkg["jlver"] = "0.3"
    end

    # Add description from Github
    if !(pkg["name"] in keys(desc_cache))
        println("Pulling description for ", pkg["name"])
        url_split = split(pkg["url"], "/")
        # GET /repos/:owner/:repo/
        github_url = "https://api.github.com/repos/$(url_split[end-1])/$(url_split[end])?access_token=$(auth_token)"
        resp = JSON.parse(Requests.get(github_url).data)
        desc_cache[pkg["name"]] = get(resp, "description", "No description available.")
    end
    pkg["githubdesc"] = desc_cache[pkg["name"]]

    # Add starts from Github
    if !(pkg["name"] in keys(star_cache))
        println("Pulling stars for ", pkg["name"])
        # GET /repos/:owner/:repo/stargazers
        url_split = split(pkg["url"], "/")
        total_stars = 0
        for page in 1:10
            println("  Page $page")
            github_url = "https://api.github.com/repos/$(url_split[end-1])/$(url_split[end])/stargazers?page=$(page)&per_page=100&access_token=$(auth_token)"
            resp = Requests.get(github_url).data
            contains(resp,"Not Found") && break  # Probably a moved package
            star_count = length(JSON.parse(resp))
            star_count == 0 && break
            total_stars += star_count
        end
        star_cache[pkg["name"]] = total_stars
    end
    pkg["githubstars"] = star_cache[pkg["name"]]
    push!(star_counts, (pkg["githubstars"], pkg["name"]) )

    # Make badge
    source_file = joinpath("..", "badges", string(pkg["status"],".svg"))
    dest_file   = joinpath("..", "badges", string(pkg["name"],"_",pkg["jlver"],".svg"))
    run(`cp $source_file $dest_file`)

    # Make log file
    log_file = joinpath("..", "logs", string(pkg["name"],"_",pkg["jlver"],".log"))
    logfp = open(log_file,"w")
    println(logfp, unescape_string(pkg["log"]))
    close(logfp)

    # Add deprecation notice
    pkg["deprecated"] = deprecations[pkg["name"]]

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

# Update cache
cache_fp = open("../db/descriptions","w")
for pkg in keys(desc_cache)
    println(cache_fp, "$(pkg)#####$(desc_cache[pkg])#####$(star_cache[pkg])")
end
close(cache_fp)

# Update history file
close(hist_fp)