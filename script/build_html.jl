#######################################################################
# packages.julialang.org
# build_html.jl
# Build the actual site by sticking together a header and footer
#######################################################################

using JSON
#using PyPlot
using PackageFuncs

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


# generate_changelog
# Take the history database and generate an HTML list of the changes
function generate_changelog(hist_db, pkg_set, date_set)
    changes = [date=>{} for date in date_set]

    # Walk through every package and day
    for pkg in pkg_set
        key = NIGHTLYVER*pkg
        !(key in keys(hist_db)) && continue
        hist = hist_db[key]
        hist_size = size(hist,1)
        for i = 1:hist_size
            status  = hist[i,3]
            prev    = i < hist_size ? hist[i+1,3] : "new"
            status != prev && push!(changes[hist[i,1]], (pkg, prev, status))
        end
    end

    # Convert to HTML
    function day_to_list(date)
        length(changes[date]) == 0 && return "<h4>$date - no changes.</h4>\n"
        function pkg_to_item(pkg_change)
            pkg, prev, now = pkg_change
            "<li><b class=\"$now\">$pkg</b> " * (
                prev == "new" ?
                    "added to METADATA, status is '$(HUMANSTATUS[now])'" :
                    "changed to '$(HUMANSTATUS[now])' from '$(HUMANSTATUS[prev])'") *
            "</li>\n"
        end
        "<h4>$date</h4><ul>\n" * join(sort(map(pkg_to_item, changes[date]))) * "</ul>\n"
    end
    #return "<ul>\n" * join(map(day_to_list, date_set[1:5])) * "</ul>\n"
    return join(map(day_to_list, date_set[1:5]))
end


# generate_totals
# Take the history database and generate a dictionary of status counts
function generate_totals(hist_db, pkg_set, date_set)
    totals  = [date => ["full_pass" => 0,     "full_fail" => 0,
                        "using_pass" => 0,    "using_fail" => 0,
                        "not_possible" => 0,  "total" => 0]
                        for date in date_set]
    for pkg in pkg_set
        key = NIGHTLYVER*pkg
        !(key in keys(hist_db)) && continue
        hist = hist_db[key]
        for i = 1:size(hist,1)
            totals[hist[i,1]][hist[i,3]] += 1
            totals[hist[i,1]]["total"] += 1
        end
    end
    return totals
end

# generate_plot
# Take the history database and generate a plot of changes in package
# status counts over time
function generate_plot(hist_db, pkg_set, date_set)
    totals = generate_totals(hist_db, pkg_set, date_set)

    # Turn dictionary into a matrix, and do dates relative to the
    # current day (e.g. "days ago")
    data = zeros(length(date_set), 6)
    baseline_day = strptime("%Y%m%d", date_set[1]).yday
    for row in 1:length(date_set)
        data[row,1] = strptime("%Y%m%d", date_set[row]).yday - baseline_day
        data[row,2] = totals[date_set[row]]["full_pass"]
        data[row,3] = totals[date_set[row]]["full_fail"]
        data[row,4] = totals[date_set[row]]["using_pass"]
        data[row,5] = totals[date_set[row]]["using_fail"]
        data[row,6] = totals[date_set[row]]["not_possible"]
    end

    # Create plot with PyPlot
    plt.plot(data[:,1], data[:,2], color="green", label="Test Pass",  linewidth=2, marker="o")
    plt.plot(data[:,1], data[:,3], color="orange",label="Test Fail",  linewidth=2, marker="o")
    plt.plot(data[:,1], data[:,4], color="blue",  label="Using Pass", linewidth=2, marker="o")
    plt.plot(data[:,1], data[:,5], color="red",   label="Using Fail", linewidth=2, marker="o")
    plt.plot(data[:,1], data[:,6], color="grey",  label="Not Tested", linewidth=2, marker="o")
    plt.legend(loc=7)
    plt.xlabel("Days Ago")
    plt.ylabel("Number of Packages")
    plt.title("Package Test Status Counts for Julia $NIGHTLYVER")
    savefig("../pkghist.png")
end

# generate_table
# Take the history database and generate a table of changes in package
# status counts over time
function generate_table(hist_db, pkg_set, date_set)
    totals = generate_totals(hist_db, pkg_set, date_set)
    
    header= "<table class=\"table healthtable\"><tr>" * "<td>Date</td>" *
            "<td>Test Pass</td>" *      "<td>Test Fail</td>" *
            "<td>Using Pass</td>" *     "<td>Using Fail</td>" *
            "<td>Not Possible</td>" *   "<td>Total</td></tr>"
    function to_td(d,s)
        v = totals[d][s]
        t = totals[d]["total"]
        return string("<td>", v, " (", int(round(v/t*100,0)), "%)</td>")
    end
    rows = map( date ->("<tr><td>$date</td>" *
                        to_td(date,"full_pass") *   to_td(date,"full_fail") *
                        to_td(date,"using_pass") *  to_td(date,"using_fail") *
                        to_td(date,"not_possible")* to_td(date,"total") * "</tr>"),
                date_set)
    return header * join(rows[1:min(5,end)]) * "</table>"
end

#######################################################################

# First get head and tail
index_head = readall("index.html.head")
index_tail = readall("index.html.tail")
listing = String[]

# Load package listing
pkgs = JSON.parse(readall("all.json"))

# Load history
hist_db, pkg_set, date_set = create_hist_db()

for pkg in pkgs
    owner = split(pkg["url"],"/")[end-1]

    cur_listing  = "<div class=\"container pkglisting\" "
    cur_listing *= "data-pkg=\"" * lowercase(pkg["name"])  * "\" "
    cur_listing *= "data-owner=\"" * lowercase(owner) * "\" "
    cur_listing *= "data-ver=\"" * pkg["jlver"] * "\" "
    cur_listing *= "data-status=\"" * pkg["status"] * "\" "
    cur_listing *= "data-lic=\"" * pkg["license"] * "\" "
    cur_listing *= ">\n<hr>\n"

    # First line - Name
    cur_listing *= "<div class=\"row\">\n"
        cur_listing *= "<div class=\"col-xs-12\"><h2><a href=\"" * pkg["url"] * "\">" * pkg["name"] * "</a></h2></div>\n"
    cur_listing *= "</div>\n"

    # Second line - Description
    cur_listing *= "<div class=\"row\">\n"
        cur_listing *= "<div class=\"col-sm-12\"><h4>" * (pkg["githubdesc"] == nothing ? "" : pkg["githubdesc"]) * "</h4>"
        cur_listing *= "</div>\n"
    cur_listing *= "</div>\n"

    # Third line - Info
    cur_listing *= "<div class=\"row\">\n<div class=\"col-sm-12\"><p>"
        # Version
        cur_listing *= "Current version: <a href=\"" * 
                        pkg["url"] * "/tree/" * pkg["gitsha"] * "\">" * pkg["version"] * " (" *
                        pkg["gitsha"][1:8] * ")</a> / "

        # License
        licurl = ""
        if pkg["licfile"] != ""
            licurl = pkg["url"] * "/blob/" * pkg["gitsha"] * "/" * pkg["licfile"]
        else
            licurl = pkg["url"] * "/tree/" * pkg["gitsha"]
        end
        cur_listing *= "<a href=\"" *
                        licurl * "\">" * pkg["license"] * "</a> license / "

        # Owner
        cur_listing *= "Owner: <a href=\"http://github.com/" *
                        owner * "\">" * owner * "</a>\n"

    cur_listing *= "</p></div></div>\n"

    # Fourth line - testing info
    cur_listing *= "<div class=\"row\">\n<div class=\"col-md-12\"><p>\nTest status: "
    cur_listing *= "<i class=\"glyphicon glyphicon-stop $(pkg["status"])\"></i> "
    cur_listing *= HUMANSTATUS[pkg["status"]] * " "
    
    cur_listing *= "<small>"
    cur_listing *= "<a class=\"showbadge\" data-pkg=\"" * pkg["name"] * "\" data-ver=\"" * pkg["jlver"] * "\">"
    cur_listing *= "<span id=\"" * pkg["name"] * pkg["jlver"][end:end] * "_badgelink\">Get permalink/badge</span></a> - "

    cur_listing *= "<a class=\"showhist\" data-pkg=\"" * pkg["name"] * "\" data-ver=\"" * pkg["jlver"] * "\">"
    cur_listing *= "<span id=\"" * pkg["name"] * pkg["jlver"][end:end] * "_histlink\">Show version and test history</span></a> - "

    cur_listing *= "<a class=\"showlog\" data-pkg=\"" * pkg["name"] * "\" data-ver=\"" * pkg["jlver"] * "\">"
    cur_listing *= "<span id=\"" * pkg["name"] * pkg["jlver"][end:end] * "_loglink\">Show last test log</span></a>"
    cur_listing *= "</small></p>"

    # BADGE PRE  
    cur_listing *= "<pre style=\"display: none;\" class=\"badgelinks\" id=\"" * pkg["name"] * pkg["jlver"][end:end] * "_badge\">"
    cur_listing *= "BADGE:     <a href=\"http://pkg.julialang.org/?pkg=$(pkg["name"])&ver=$(pkg["jlver"])\">" *
                   "<img src=\"http://pkg.julialang.org/badges/$(pkg["name"])_$(pkg["jlver"]).svg\"></a> \n"
    cur_listing *= "PERMALINK: http://pkg.julialang.org/?pkg=$(pkg["name"])&ver=$(pkg["jlver"]) \n"
    cur_listing *= "BADGE SVG: http://pkg.julialang.org/badges/$(pkg["name"])_$(pkg["jlver"]).svg \n"
    cur_listing *= "MARKDOWN:  [![$(pkg["name"])](http://pkg.julialang.org/badges/$(pkg["name"])_$(pkg["jlver"]).svg)]"
    cur_listing *= "(http://pkg.julialang.org/?pkg=$(pkg["name"])&ver=$(pkg["jlver"]))"
    
    cur_listing *= "</pre>"

    # LOG PRE
    cur_listing *= "<pre style=\"display: none;\" class=\"testlog\" id=\"" * pkg["name"] * pkg["jlver"][end:end] * "_log\"></pre>"
    # HIST PRE
    hist_data = hist_to_html(hist_db[pkg["jlver"]*pkg["name"]])
    cur_listing *= "<pre style=\"display: none;\" class=\"testhist\" id=\"" * pkg["name"] * pkg["jlver"][end:end] * "_hist\">" * hist_data * "</pre>"
    cur_listing *= "</div></div>"



    push!(listing, cur_listing * "</div>")
    #break
end

# Build package ecoystem health indicators
#generate_plot(hist_db, pkg_set, date_set)
output_table = generate_table(hist_db, pkg_set, date_set)
change_list  = generate_changelog(hist_db, pkg_set, date_set)
health = "<div class=\"container\" id=\"pkgstats\"><div class=\"row\"><div class=\"col-md-6\">" *
         "<img src=\"pkghist.png\" alt=\"Package test history\" class=\"img-responsive\">" *
         output_table *
         "</div><div class=\"col-md-6\">" * 
         change_list * 
         "</div></div></div>"

# Output
fp = open("../index.html","w")
print(fp, index_head * health * join(listing,"\n") * index_tail)
close(fp)