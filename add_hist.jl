using JSON

datestr = ARGS[1]
infp    = open("all.json","r")
todaystr= readall(infp)
close(infp)

outfp   = open("hist.json","r")
histstr = readall(outfp)
close(outfp)
outfp   = open("hist.json","w")

hist    = JSON.parse(histstr)

today   = JSON.parse(todaystr)
newday  = Dict()
for pkg in today
    if pkg["name"] in keys(newday)
        newday[pkg["name"]][pkg["jlver"]] = [pkg["version"], pkg["status"]]
    else
        newday[pkg["name"]] = [pkg["jlver"] => [pkg["version"], pkg["status"]]]
    end
end

push!(hist, [datestr => newday])
print(outfp, JSON.json(hist))
close(outfp)