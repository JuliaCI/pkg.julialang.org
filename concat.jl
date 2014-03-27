stable = readall("stable.json")
nightly = readall("nightly.json")
output = open("all.json","w")
println(output, "[")
println(stable[end])
#if stable[end]==","
    println(output, stable)
#else
#    println(output, stable, ",")
#end
#if nightly[end]==","
    println(output, nightly[1:end-1])
#else
#    println(output, nightly)
#end
println(output, "]")
close(output)