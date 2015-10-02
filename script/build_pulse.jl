import Mustache

include("shared.jl")

# changes_this_week
# Build a list of changes this week:
# * new packages
# * version bumps
function changes_this_week(hist, pkgnames, dates, ver, today)
    changes = Any[]
    for pkgname in pkgnames
        !(pkgname in keys(hist[ver])) && continue
        # Get version now
        cur_ver = hist[ver][pkgname][1].pkgver
        cur_date = dbdate_to_date(hist[ver][pkgname][1].date)
        # Get rid of entries that possibly only briefly existed in METADATA
        abs(int(cur_date - dbdate_to_date(today))) >= 2 && continue
        # Try to get version a week ago
        pre_ver = cur_ver
        new_this_week = true
        for i = 2:length(hist[ver][pkgname])
            pre_date = dbdate_to_date(hist[ver][pkgname][i].date)
            if int(cur_date-pre_date) >= 14
                pre_ver = hist[ver][pkgname][i].pkgver
                new_this_week = false
                break
            end
        end
        # Is it new package?
        if new_this_week
            push!(changes, (:new, pkgname, cur_ver))
        else
            push!(changes, (:week, pkgname, pre_ver, cur_ver))
        end
    end
    sort!(changes)
    return changes
end


# star_changes
# Determine 14 day star change
function changes_this_week(star_hist)
    changes = Any[]
    for pkgname in keys(star_hist)
        # Get info now
        cur_date = dbdate_to_date(star_hist[pkgname][1][1])
        cur_star = star_hist[pkgname][1][2]
        # Try to get version a week ago (or best effort)
        pre_star = 0
        for i = 2:length(star_hist[pkgname])
            pre_date = dbdate_to_date(star_hist[pkgname][i][1])
            pre_star = star_hist[pkgname][i][2]
            int(cur_date-pre_date) >= 14 && break
        end
        push!(changes, (pkgname, cur_star, pre_star))
    end
    sort!(changes)
    return changes
end


# generate_changelog
# Take the history database and generate a list of the
# test changes
function test_changes(hist, pkgnames, dates, ver)
    changes = [date => Any[] for date in dates]

    # Walk through every package and day
    for pkg in pkgnames
        !(pkg in keys(hist[ver])) && continue
        h = hist[ver][pkg]
        h_size = length(h)
        for i = 1:h_size
            status  = h[i].status
            prev    = i < h_size ? h[i+1].status : "new"
            status != prev && push!(changes[h[i].date], (pkg, prev, status))
        end
    end

    return changes
end

#----------------------------------------------------------------------
# Load package listing, turn into a more useful dictionary
pkgs = JSON.parse(readall(ALLJSON_FILE))
pkgdict = ["0.3"=>Dict(), "0.4"=>Dict()]
for pkg in pkgs
    pkgdict[pkg["jlver"]][pkg["name"]] = pkg
end

RELEASE = "0.3"
NIGHTLY = "0.4"

# Build up last week changes
hist, pkgnames, dates = load_hist_db(HIST_FILE)
today = hist[RELEASE]["JuMP"][1].date
changes = changes_this_week(hist, pkgnames, dates, NIGHTLY, today)
disp_changes = Any[]
new_count = 0
up_count = 0
for c in changes
    @show c
    @show c[2] in keys(pkgdict[NIGHTLY])
    @show c[2] in keys(pkgdict[RELEASE])
    if c[2] in keys(pkgdict[NIGHTLY])
        pd = pkgdict[NIGHTLY][c[2]]
    else
        pd = pkgdict[RELEASE][c[2]]
    end
    if c[1] == :new
        push!(disp_changes,Dict("i"     =>  "star",
                                "nname" =>  "$(c[2])",
                                "npost" =>  "$(c[3])",
                                "url"   =>  pd["url"],
                                "sha"   =>  pd["gitsha"]))
        new_count += 1
    elseif c[1] == :week
        c[3] == c[4] && continue
        push!(disp_changes,Dict("i"     =>  "arrow-up",
                                "cname" =>  "$(c[2])",
                                "cpre"  =>  "$(c[3])",
                                "cpost" =>  "$(c[4])",
                                "url"   =>  pd["url"],
                                "sha"   =>  pd["gitsha"]))
        up_count += 1
    end
end

# Stars
star_hist, star_dates = load_star_db(STAR_FILE)
star_changes = changes_this_week(star_hist)
# Get top ten by count
star_top_alltime = sort(star_changes,by=f->f[2],rev=true)
top_star_data = Any[]
for i = 1:10
    name, cur, prev = star_top_alltime[i]
    push!(top_star_data, Dict(  "url" => pkgdict[NIGHTLY][name]["url"],
                                "name" => name,
                                "count" => cur,
                                "change" => cur-prev ))
end
# Get top ten by change
star_top_change = sort(star_changes,by=f->(f[2]-f[3]),rev=true)
top_star_change_data = Any[]
#for i = 1:10
done = 0
i = 1
while done < 10
    name, cur, prev = star_top_change[i]
    try  # Caused by untagged package
        push!(top_star_change_data, Dict(
                                "url" => pkgdict[NIGHTLY][name]["url"],
                                "name" => name,
                                "count" => cur,
                                "change" => cur-prev ))
        done += 1
    catch
        @show name * " had a problem"
    end
    i += 1
end


# Build up totals for testing chart
totals = total_pkgs_by_date(hist, pkgnames, dates)

# Testing changes
changes = test_changes(hist, pkgnames, dates, RELEASE)
rel_test_changes = Any[]
for i in 1:5
    push!(rel_test_changes, Any[])
    for change in changes[dates[i]]
        push!(rel_test_changes[i], Dict(
                                    "name"  =>  change[1],
                                    "prev"  =>  change[2],
                                    "cur"   =>  change[3],
                                    "url"   =>  ((change[1] in keys(pkgdict[RELEASE])) ?
                                                    pkgdict[RELEASE][change[1]]["url"] :
                                                    pkgdict[NIGHTLY][change[1]]["url"]),
                                    "purl"  =>  "../logs/$(change[1])_$RELEASE.log"
                                    ))
    end
    sort!(rel_test_changes[i],by=f->f["name"])
end
changes = test_changes(hist, pkgnames, dates, NIGHTLY)
nig_test_changes = Any[]
for i in 1:5
    push!(nig_test_changes, Any[])
    for change in changes[dates[i]]
        push!(nig_test_changes[i], Dict(
                                    "name"  =>  change[1],
                                    "prev"  =>  change[2],
                                    "cur"   =>  change[3],
                                    "url"   =>  pkgdict[NIGHTLY][change[1]]["url"],
                                    "purl"  =>  "../logs/$(change[1])_$NIGHTLY.log"
                                    ))
    end
    sort!(nig_test_changes[i],by=f->f["name"])
end


#----------------------------------------------------------------------
# Use all the above to build the HTML
template = readall("pulse_temp.html")
rel_num_per(s) = @sprintf("%d (%.0f%%)", totals[RELEASE][today][s],
                    totals[RELEASE][today][s]/totals[RELEASE][today]["total"]*100)
nig_num_per(s) = @sprintf("%d (%.0f%%)", totals[NIGHTLY][today][s],
                    totals[NIGHTLY][today][s]/totals[NIGHTLY][today]["total"]*100)
rendered = Mustache.render(template, 
    Dict(
    "updatedate"    => dbdate_to_date(today),

    "num-new-pkg"   => new_count,
    "num-up-pkg"    => up_count,
    "changes1"      => disp_changes[1:div(length(disp_changes),2)+1],
    "changes2"      => disp_changes[div(length(disp_changes),2)+2:end],

    "topstaralltime"=> top_star_data,
    "topstarchange" => top_star_change_data,

    #="rel-pass"      => rel_num_per("full_pass"),
    "rel-fail"      => rel_num_per("full_fail"),
    "rel-using"     => rel_num_per("using_pass"),
    "rel-noload"    => rel_num_per("using_fail"),
    "rel-untest"    => rel_num_per("not_possible"),=#
    "rel-pass"      => rel_num_per("tests_pass"),
    "rel-fail"      => rel_num_per("tests_fail"),
    "rel-no"        => rel_num_per("no_tests"),
    "rel-untest"    => rel_num_per("not_possible"),
    "rel-total"     => totals[RELEASE][today]["total"],
    #="nig-pass"      => nig_num_per("full_pass"),
    "nig-fail"      => nig_num_per("full_fail"),
    "nig-using"     => nig_num_per("using_pass"),
    "nig-noload"    => nig_num_per("using_fail"),
    "nig-untest"    => nig_num_per("not_possible"),=#
    "nig-pass"      => nig_num_per("tests_pass"),
    "nig-fail"      => nig_num_per("tests_fail"),
    "nig-no"        => nig_num_per("no_tests"),
    "nig-untest"    => nig_num_per("not_possible"),
    "nig-total"     => totals[NIGHTLY][today]["total"],
    "testdate1"     => dbdate_to_date(dates[1]),
    "testdate2"     => dbdate_to_date(dates[2]),
    "testdate3"     => dbdate_to_date(dates[3]),
    "testdate4"     => dbdate_to_date(dates[4]),
    "testdate5"     => dbdate_to_date(dates[5]),
    "reltest1"      => rel_test_changes[1],
    "reltest2"      => rel_test_changes[2],
    "reltest3"      => rel_test_changes[3],
    "reltest4"      => rel_test_changes[4],
    "reltest5"      => rel_test_changes[5],
    "nigtest1"      => nig_test_changes[1],
    "nigtest2"      => nig_test_changes[2],
    "nigtest3"      => nig_test_changes[3],
    "nigtest4"      => nig_test_changes[4],
    "nigtest5"      => nig_test_changes[5]
    ))
fp = open("../pulse.html","w")
print(fp, rendered)
close(fp)