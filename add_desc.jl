using JSON
auth_token = readall("token")
all_pkgs = JSON.parse(readall("all.json"))
for pkg in all_pkgs
    # Add description from Github if not there already
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
end
fp = open("all.json","w")
print(fp, JSON.json(all_pkgs))