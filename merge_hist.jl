using JSON
all_pkgs = JSON.parse(readall("all.json"))
all_hist = JSON.parse(readall("hist.json"))
for pkg in all_pkgs
    pkg["hist"] = ""
end

function humanStatus(status)
    if status == "full_pass"
        return "Tests pass."
    elseif status == "full_fail"
        return "Tests fail, but package loads."
    elseif status == "using_pass"
        return "No tests, but package loads."
    elseif status == "using_fail"
        return "Package doesn't load."
    else
        return "Package was untestable."
    end
end

for day_ind in length(all_hist):-1:1
    cur_day = collect(keys(all_hist[day_ind]))[1]
    nice_day = cur_day[1:4] * "-" * cur_day[5:6] * "-" * cur_day[7:8]
    println(cur_day, " ", nice_day)
    for pkg in all_pkgs
        !(pkg["name"] in keys(all_hist[day_ind][cur_day])) && continue
        hist_for_pkg = all_hist[day_ind][cur_day][pkg["name"]]
        if !(pkg["jlver"] in keys(hist_for_pkg))
            println("Something wrong with ", pkg["name"], " ", pkg["jlver"])
            continue
        end
        pkg["hist"] *= nice_day * ", v" * hist_for_pkg[pkg["jlver"]][1] *
                                  ", " * humanStatus(hist_for_pkg[pkg["jlver"]][2]) * "\n"
    end
end
fp = open("all.json","w")
print(fp, JSON.json(all_pkgs))