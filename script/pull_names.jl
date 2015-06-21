import JSON
using PackageFuncs

# Load all the results
all_pkgs = vcat(JSON.parsefile("releaseAL.json"),
                JSON.parsefile("releaseMZ.json"),
                JSON.parsefile("nightlyAL.json"),
                JSON.parsefile("nightlyMZ.json"))

releasefp = open("releasenames.txt","w")
nightlyfp = open("nightlynames.txt","w")
for pkg in all_pkgs
    fp = (pkg["jlver"] == STABLEVER) ? releasefp : nightlyfp
    for name in pkg["expnames"]
        # Remove some bad lines
        if contains(name, " ") ||
            (length(name) >= 1 && name[1] == " ")
            continue
        end

        println(fp, name)
    end
end
close(releasefp)
close(nightlyfp)