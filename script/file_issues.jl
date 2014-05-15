using Requests
using PackageFuncs
using JSON

const auth_token = readall("issuetoken")

# Load package listing
pkg_owners = Dict()
pkgs = JSON.parse(readall("all.json"))
for pkg_dict in pkgs
    owner = split(pkg_dict["url"],"/")[end-1]
    pkg_owners[pkg_dict["name"]] = owner
end

# onetime_file
# For mass one-off postings to every package that isn't green or grey
function initial_file(hist_db, pkg_set)
    # Walk through every package for this julia version
    count = 0
    for pkg in pkg_set
        stable_key      = STABLEVER*pkg
        stable_status   = (stable_key  in keys(hist_db)) ? hist_db[stable_key][1,3] : "not_possible"
        nightly_key     = NIGHTLYVER*pkg
        nightly_status  = (nightly_key in keys(hist_db)) ? hist_db[nightly_key][1,3] : "not_possible"

        if (stable_status == "full_pass" || stable_status == "not_possible") &&
           (nightly_status == "full_pass" || nightly_status == "not_possible")
           continue
        end

        count += 1

        issue_title = "[PackageEvaluator.jl] Your package $pkg may have a testing issue."

        issue_body  = """
*This issue is being filed by a script, but if you reply, I will see it.*

[PackageEvaluator.jl](https://github.com/IainNZ/PackageEvaluator.jl) is a script that runs nightly. It attempts to load all Julia packages and run their test (if available) on both the stable version of Julia ($STABLEVER) and the nightly build of the unstable version ($NIGHTLYVER).

The results of this script are used to generate a [package listing](http://iainnz.github.io/packages.julialang.org/) enhanced with testing results.

The status of this package, $pkg, on...

* Julia $STABLEVER is **'$(HUMANSTATUS[stable_status])'** [![PackageEvaluator.jl](http://iainnz.github.io/packages.julialang.org/badges/$stable_status.svg)](http://iainnz.github.io/packages.julialang.org/?pkg=$pkg&ver=$STABLEVER)
* Julia $NIGHTLYVER is **'$(HUMANSTATUS[nightly_status])'** [![PackageEvaluator.jl](http://iainnz.github.io/packages.julialang.org/badges/$nightly_status.svg)](http://iainnz.github.io/packages.julialang.org/?pkg=$pkg&ver=$NIGHTLYVER)

*'$(HUMANSTATUS["using_pass"])'* can be due to their being no tests (you should write some if you can!) but can also be due to PackageEvaluator not being able to find your tests. Consider adding a [`test/runtests.jl`](https://github.com/JuliaLang/julia/pull/6191) file.

*'$(HUMANSTATUS["using_fail"])'* is the worst-case scenario. Sometimes this arises because your package doesn't have BinDeps support, or needs something that can't be installed with BinDeps. If this is the case for your package, please [file an issue](https://github.com/IainNZ/PackageEvaluator.jl) and an exception can be made so your package will not be tested.

**This automatically filed issue is a one-off message. Starting soon, issues will only be filed when the testing status of your package changes in a negative direction (gets worse). If you'd like to opt-out of these status-change messages, reply to this message saying you'd like to and @IainNZ will add an exception.**
"""
        try
            github_url = "https://api.github.com/repos/$(pkg_owners[pkg])/$(pkg).jl/issues?access_token=$(auth_token)"
            resp = post(github_url; json = {"title" => issue_title,
                                            "body"  => issue_body})
            println(pkg, "   ", pkg_owners[pkg], " posted! $count")
        catch
            println(pkg, "   ", pkg_owners[pkg], " failed to post issue $count")
        end
    end
end

# Load history
hist_db, pkg_set, date_set = PackageFuncs.create_hist_db()

# Use with extreme care :D
#initial_file(hist_db, pkg_set)