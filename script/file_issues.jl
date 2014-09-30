using Requests
using PackageFuncs
using JSON

const auth_token = readall("issuetoken")

###############################################################################
# change_file
# Files issues when package test status gets worse
function change_file(hist_db, pkg_set, date_set)
    # Walk through every package and day
    for JLVER = [STABLEVER, NIGHTLYVER]
    for pkg in pkg_set
        key = JLVER*pkg
        !(key in keys(hist_db)) && continue  # Guess it doesn't exist
        hist = hist_db[key]
        if size(hist,1) <= 1
            # New package
            status_now  = hist[1,3]
            status_prev = "new_pkg"
            hist = [hist[1,1] hist[1,2] hist[1,3];
                    hist[1,1] hist[1,2] hist[1,3]]
        else
            status_now  = hist[1,3]
            status_prev = hist[2,3]
        end
        status_now == "not_possible" && continue  # Stopped testing this
        STATUSNUM[status_now] >= STATUSNUM[status_prev] && continue  # Same or better
        # Ok, so we have a package that got worse
        nice_today = hist[1,1][1:4] * "-" * hist[1,1][5:6] * "-" * hist[1,1][7:8]
        nice_prev  = hist[2,1][1:4] * "-" * hist[2,1][5:6] * "-" * hist[2,1][7:8]
        issue_title = "[PkgEval] $pkg may have a testing issue on Julia $JLVER ($nice_today)"
        issue_body = """[PackageEvaluator.jl](https://github.com/IainNZ/PackageEvaluator.jl) is a script that runs nightly. It attempts to load all Julia packages and run their tests (if available) on both the stable version of Julia ($STABLEVER) and the nightly build of the unstable version ($NIGHTLYVER). The results of this script are used to generate a [package listing](http://pkg.julialang.org/) enhanced with testing results.

#### On Julia $JLVER
* On **$(nice_prev)** the testing status was `$(HUMANSTATUS[status_prev])`
* On **$(nice_today)** the testing status changed to `$(HUMANSTATUS[status_now])`

"""
        
        if status_prev == "full_pass" || status_now == "full_pass"
            issue_body *= "`$(HUMANSTATUS["full_pass"])` means that PackageEvaluator found the tests for your package, executed them, and they all passed.\n\n"""
        end
        if status_prev == "full_fail" || status_now == "full_fail"
            issue_body *= "`$(HUMANSTATUS["full_fail"])` means that PackageEvaluator found the tests for your package, executed them, and they didn't pass. However, trying to load your package with `using` worked.\n\n"""
        end
        if status_prev == "using_pass" || status_now == "using_pass"
            issue_body *= "`$(HUMANSTATUS["using_pass"])` means that PackageEvaluator did not find tests for your package. However, trying to load your package with `using` worked.\n\n"""
        end
        if status_prev == "using_fail" || status_now == "using_fail"
            issue_body *= "`$(HUMANSTATUS["using_fail"])` means that PackageEvaluator did not find tests for your package. Additionally, trying to load your package with `using` failed.\n\n"""
        end

        if JLVER == NIGHTLYVER
            issue_body *= """
\nThis error on Julia 0.4 is possibly due to recently merged pull request https://github.com/JuliaLang/julia/pull/8420.
"""
        end

        issue_body *= """
*This issue was filed because your testing status became worse. No additional issues will be filed if your package remains in this state, and no issue will be filed if it improves. If you'd like to opt-out of these status-change messages, reply to this message saying you'd like to and @IainNZ will add an exception. If you'd like to discuss [PackageEvaluator.jl](https://github.com/IainNZ/PackageEvaluator.jl) please file an issue at the repository. For example, your package may be untestable on the test machine due to a dependency - an exception can be added.*"""

        if JLVER == STABLEVER
            issue_body *= "\n\n*Test log*:\n```\n" * pkg_log_stable[pkg] * "\n```"
        else
            issue_body *= "\n\n*Test log*:\n```\n" * pkg_log_nightly[pkg] * "\n```"
        end

        #println(issue_title)
        #println(issue_body)
        println(string(JLVER, " ", pkg, " ", status_prev, " ", status_now))
        iain_input = readline()
        if iain_input == "y\n"
            # Approved
            try
                github_url = "https://api.github.com/repos/$(pkg_owners[pkg])/$(pkg).jl/issues?access_token=$(auth_token)"
                resp = post(github_url; json = {"title" => issue_title,
                                                "body"  => issue_body})
                println(pkg, "   ", pkg_owners[pkg], " posted!")
            catch
                println(pkg, "   ", pkg_owners[pkg], " failed to post issue")
            end
        else
            println("Skipped!")
        end
    end
    end
end

# Load package listing
pkg_owners = Dict()
pkg_log_stable = Dict()
pkg_log_nightly = Dict()
pkgs = JSON.parse(readall("all.json"))
for pkg_dict in pkgs
    owner = split(pkg_dict["url"],"/")[end-1]
    pkg_owners[pkg_dict["name"]] = owner
    if pkg_dict["jlver"] == STABLEVER 
        pkg_log_stable[pkg_dict["name"]] = pkg_dict["log"]
    elseif pkg_dict["jlver"] == NIGHTLYVER 
        pkg_log_nightly[pkg_dict["name"]] = pkg_dict["log"]
    else
        error("Unrecognized jlver $(pkg_dict["jlver"])")
    end
end

# Load history
hist_db, pkg_set, date_set = PackageFuncs.create_hist_db()

# Use with extreme care :D
change_file(hist_db, pkg_set, date_set)