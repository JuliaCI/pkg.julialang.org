using Requests
using PackageFuncs
using JSON

const auth_token = readall("issuetoken")

pkgs = JSON.parse(readall("all.json"))
pkg_owners = Dict()
for pkg_dict in pkgs
    owner = split(pkg_dict["url"],"/")[end-1]
    pkg_owners[pkg_dict["name"]] = owner
end

for pkg in pkgs
    # Only look at 0.4
    if pkg["jlver"] != "0.4"
        continue
    end

    # Does this package have a test/runtests.jl?
    tf = split(pkg["testfile"],"/")
    if length(tf) == 1
        # Doesn't currently have a detected test file
        # Isn't going to get any worse, lets just ignore
        continue
    else
        if tf[end-1] == "test" && tf[end] == "runtests.jl"
            # A good one
            continue
        else
            # A bad one!
        end
    end
    

    issue_title = "[PkgEval] Your package doesn't have a test/runtests.jl file"
    issue_body = """
[PackageEvaluator.jl](https://github.com/IainNZ/PackageEvaluator.jl) is a script that runs nightly.
It attempts to load all Julia packages and run their tests (if available) on both the stable
version of Julia ($STABLEVER) and the nightly build of the unstable version ($NIGHTLYVER).
The results of this script are used to generate a [package listing](http://pkg.julialang.org/)
enhanced with testing results. This service also benefits package developers by notifying them if
their package breaks for some reason (caused by e.g. changes in Julia, changes in dependencies,
or broken binary dependencies.)

Currently PackageEvaluator attempts to find your test scripts using a heuristic, preferring the
standarized `test/runtests.jl` whenever present. Using `test/runtests.jl` allows people to test
your package using simply `Pkg.test("$(pkg["name"])")`, with any testing-only dependencies being
installed by looking at `test/REQUIRE`.

Your package doesn't appear to have a `test/runtests.jl` file. PackageEvaluator is going to move
away from auto-detecting tests and will instead only test packages with a `test/runtests.jl`
file. This change will take place in about a month.

*You can:*
- **Add the file and tag a new version**. You may in fact have already added this file but not
  tagged a new version. PackageEvaluator only tests your latest tagged verison, so you must tag
  for the file to be detected.
- **Chose to do nothing**. PackageEvaluator will stop attempting to test your package, and the testing
  status will be reported as "not possible".

If you'd like help or more information, please just reply to this issue.
"""
    
    println(pkg["name"], " ", pkg["testfile"])
    #println(issue_body)
    iain_input = readline()
    if iain_input == "y\n"
        # Approved
        try
            github_url = "https://api.github.com/repos/$(pkg_owners[pkg["name"]])/$(pkg["name"]).jl/issues?access_token=$(auth_token)"
            println(github_url)
            resp = post(github_url; json = {"title" => issue_title,
                                            "body"  => issue_body})
            println(pkg["name"], "   ", pkg_owners[pkg["name"]], " posted!")
        catch e
            println(e)
            println(pkg["name"], "   ", pkg_owners[pkg["name"]], " failed to post issue")
        end
    else
        println("Skipped!")
    end
end