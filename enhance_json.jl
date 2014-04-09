using JSON

# Produce concatenated file
stable   = readall("stable.json")
nightly  = readall("nightly.json")
combined = "[" * stable * "," * nightly * "]"
all_pkgs = JSON.parse(combined)

# Load GitHub auth token (NOT CHECKED IN!!)
auth_token = readall("token")

# Open up history file
hist   = JSON.parse(readall("hist.json"))
newday = Dict()

for pkg in all_pkgs
    # Add description from Github
    if !("githubdesc" in keys(pkg))
        url_split = split(pkg["url"], "/")
        github_url = "https://api.github.com/repos/$(url_split[end-1])/$(url_split[end])?access_token=$(auth_token)"
        github_resp = JSON.parse(readall(download(github_url)))
        pkg["githubdesc"] = get(github_resp, "description", "No description available.")
    end

    # Make badge
    source_file = joinpath("badges", string(pkg["status"],".svg"))
    dest_file   = joinpath("badges", string(pkg["name"],"_",pkg["jlver"],".svg"))
    run(`cp $source_file $dest_file`)

    # Make log file
    log_file = joinpath("logs", string(pkg["name"],"_",pkg["jlver"],".log"))
    logfp = open(log_file,"w")
    println(logfp, pkg["details"]*"\n"*pkg["testlog"])
    close(logfp)

    # Update history
    if pkg["name"] in keys(newday)
        newday[pkg["name"]][pkg["jlver"]] = [pkg["version"], pkg["status"]]
    else
        newday[pkg["name"]] = [pkg["jlver"] => [pkg["version"], pkg["status"]]]
    end
end

# Output new combined JSON
fp = open("all.json","w")
print(fp, JSON.json(all_pkgs))
close(fp)

# Update history file
datestr = ARGS[1]
push!(hist, [datestr => newday])
hist_fp = open("hist.json","w")
print(hist_fp, JSON.json(hist))
close(hist_fp)