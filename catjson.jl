using JSON
outfp = open("all.json","w")
println(outfp, "[")
first = true
for file in readdir("json")
    if !first
        println(outfp, ",")
    end
    first = false

    data = readall(joinpath("json",file))
    js   = JSON.parse(data)
    pkg  = js["name"]
    #println(outfp, "\"$pkg\":")
    println(outfp, data)
    
end
println(outfp, "]")