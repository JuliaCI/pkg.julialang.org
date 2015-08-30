#######################################################################
# packages.julialang.org
# build_html.jl
# Build the actual site by sticking together a header and footer
#######################################################################

using JSON
include("PackageFuncs.jl"); using PackageFuncs
using Humanize
#using Dates

# hist_to_html
# Take a matrix [dates pkgver status] and turns it into a simple
# multiline string that is used in the dropdown for each individual
# package
function hist_to_html(hist)
    output_strs = {}

    pos = size(hist,1)
    cur_start_date = date_nice(hist[pos,1])
    cur_end_date   = date_nice(hist[pos,1])
    cur_version    = hist[pos,2]
    cur_status     = HUMANSTATUS[hist[pos,3]]
    while true
        pos -= 1
        if pos == 0
            # End of history
            push!(output_strs, cur_start_date * " to " * cur_end_date *
                    ", v" * cur_version * ", " * cur_status * "\n")
            break
        end
        pos_date    = date_nice(hist[pos,1])
        pos_version = hist[pos,2]
        pos_status  = HUMANSTATUS[hist[pos,3]]
        if pos_version != cur_version || pos_status != cur_status
            # Change in state
            push!(output_strs, cur_start_date * " to " * cur_end_date *
                    ", v" * cur_version * ", " * cur_status * "\n")
            cur_start_date  = pos_date
            cur_end_date    = pos_date
            cur_version     = pos_version
            cur_status      = pos_status
        else
            # No changes to worry about it
            cur_end_date = pos_date
        end
    end

    return join(reverse(output_strs))
end

#######################################################################

# First get head and tail
index_head = readall("index.html.head")
index_head = replace(index_head, "!!LASTUPDATED!!", string(Dates.today()))
index_tail = readall("index.html.tail")
listing = String[]

# Load package listing
pkgs = JSON.parse(readall("all.json"))

# Load history
hist_db, pkg_set, date_set = create_hist_db()

for pkg in pkgs
    # Dump dictionary out into locals for easier interpolation
    P_OWNER = split(pkg["url"],"/")[end-1]
    P_NAME  = pkg["name"]
    P_URL   = pkg["url"]
    P_DESC  = pkg["githubdesc"] == "nothing" ? "" : pkg["githubdesc"]
    P_STAR  = pkg["githubstars"]
    P_SHA   = pkg["gitsha"]
    P_VER   = pkg["version"]
    P_DATE  = pkg["gitdate"]
    P_DTSTR = "unknown"
    #try
        P_DT    = Dates.now() - DateTime(P_DATE,"y-m-d H:M:S")
        P_DTSTR = timedelta(P_DT)
    #catch
    #    Base.warn("$(P_NAME) had an issue with its date string")
    #end
    P_LURL  = pkg["licfile"] != "" ? "$P_URL/blob/$P_SHA/$(pkg["licfile"])" : "$P_URL/tree/$P_SHA"
    P_LIC   = pkg["license"]
    P_STAT  = pkg["status"]
    P_HSTAT = HUMANSTATUS[pkg["status"]]
    P_JLVER = pkg["jlver"]
    P_MINOR = pkg["jlver"][end:end]
    P_NICEJLVER = pkg["jlver"] == STABLEVER ? "release" : "nightly"
    P_LINK  = "http://pkg.julialang.org/?pkg=$P_NAME&ver=$P_NICEJLVER"
    P_SVG   = "http://pkg.julialang.org/badges/$(P_NAME)_$(pkg["jlver"]).svg"
    P_SVG2  = "http://pkg.julialang.org/badgesrc/$(P_STAT)_$(pkg["jlver"]).svg"
    hist_data = hist_to_html(hist_db[pkg["jlver"]*pkg["name"]])
    
    cur_listing = """
<div class="container pkglisting" data-pkg="$(lowercase(P_NAME))"
 data-owner="$(lowercase(P_OWNER))" data-ver="$(pkg["jlver"])"
 data-status="$(pkg["status"])"   data-lic="$(pkg["license"])">
<hr>
<div class="row"><div class="col-xs-12">
<h2><a href="$P_URL">$P_NAME</a></h2>\n
<h4>$(P_DESC)</h4>
<p>Current version: <a href="$P_URL/tree/$P_SHA" title="$P_SHA">$P_VER</a>
($P_DTSTR ago) /
$(pkg["deprecated"] ? " <span class=\"using_fail\" title=\"Package is no longer supported and may not install on the next Julia release\">deprecated</span> / " : "")
<a href="$P_LURL">$P_LIC</a> license /
Owner: <a href="http://github.com/$P_OWNER">$P_OWNER</a> / 
<span title="GitHub stars">$(P_STAR) <i class="glyphicon glyphicon-star"></i></span></p>
<p>Test status: <i class="glyphicon glyphicon-stop $P_STAT"></i> $P_HSTAT
<small>
<a class="showbadge" data-pkg="$P_NAME" data-ver="$P_JLVER">
<span id="$(P_NAME)$(P_MINOR)_badgelink">Get permalink/badge</span></a> -
<a class="showhist" data-pkg="$P_NAME" data-ver="$P_JLVER">
<span id="$(P_NAME)$(P_MINOR)_histlink">Show version &amp; test history</span></a> -
<a class="showlog" data-pkg="$P_NAME" data-ver="$P_JLVER">
<span id="$(P_NAME)$(P_MINOR)_loglink">Show last test log</span></a>
<span style="display: none;" id="$(P_NAME)$(P_MINOR)_file"> -
<a href="https://github.com/IainNZ/PackageEvaluator.jl/issues">Report test result error</a>
</span>
</small></p>
<pre style="display: none;" class="badgelinks" id="$(P_NAME)$(P_MINOR)_badge">
BADGE:     <a href="$P_LINK"><img src="$P_SVG2"></a>
PERMALINK: $P_LINK
BADGE SVG: $P_SVG
MARKDOWN:  [![$P_NAME]($P_SVG)]($P_LINK)
</pre>
<pre style="display: none;" class="testlog" id="$(P_NAME)$(P_MINOR)_log"></pre>
<pre style="display: none;" class="testhist" id="$(P_NAME)$(P_MINOR)_hist">$hist_data</pre>
</div></div></div>"""  # /COL, /ROW, /CONTAINER

    push!(listing, cur_listing)
end

# Output
fp = open("../index.html","w")
print(fp, index_head * join(listing,"\n") * index_tail)
close(fp)