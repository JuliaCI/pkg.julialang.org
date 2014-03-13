using JSON
auth_token = readall("token")
all_pkgs = JSON.parse(readall("all.json"))
for pkg in all_pkgs
    url_split = split(pkg["url"], "/")
    github_url = "https://api.github.com/repos/$(url_split[end-1])/$(url_split[end])?access_token=$(auth_token)"
    github_resp = JSON.parse(readall(download(github_url)))
    try
        pkg["githubdesc"] = github_resp["description"]
    catch
        pkg["githubdesc"] = "<i>No description available.</i>"
    end
end
fp = open("all.json","w")
print(fp, JSON.json(all_pkgs))