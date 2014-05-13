#######################################################################
# packages.julialang.org
# build_html.jl
# Build the actual site by sticking together a header and footer
#######################################################################

const STABLEVER = "0.2"
const NIGHTLYVER = "0.3"

using JSON
using PyPlot

# HUMANSTATUS
# Human-readable versions of the test codes
const HUMANSTATUS = [
    "full_pass" => "Tests pass.",
    "full_fail" => "Tests fail, but package loads.",
    "using_pass" => "No tests, but package loads.",
    "using_fail" => "Package doesn't load.",
    "not_possible" => "Package was untestable."]


# create_hist_db
# Load the history database CSV, turn it into a dictionary keyed on
# the package name and the Julia version
# Returns 
#  - Dictionary keyed on a string "$jlver$pkgname" with value being
#    a matrix [dates pkgver status] sorted so most recent is at top
#  - a set of all package names seen
#  - a set of all dates seen
function create_hist_db()
    all_hist = readcsv("../db/hist_db.csv", String)
    # Remove all the whitespace
    map!(strip, all_hist)
    # Form the dictionaries
    hist_db  = Dict()
    pkg_set  = Set()
    date_set = Set()
    for row in 1:size(all_hist,1)
        col_DATE    = all_hist[row,1]
        col_JLVER   = all_hist[row,2]
        col_NAME    = all_hist[row,3]
        col_PKGVER  = all_hist[row,4]
        col_STATUS  = all_hist[row,5]
        key         = col_JLVER * col_NAME
        value       = [col_DATE col_PKGVER col_STATUS]

        hist_db[key] = key in keys(hist_db) ? 
                        vcat(hist_db[key], value) :
                        value
        push!(pkg_set,  col_NAME)
        push!(date_set, col_DATE)
    end
    # Sort by descending dates
    for key in keys(hist_db)
        val = hist_db[key]
        hist_db[key] = val[sortperm(val[:,1], rev=true),:]
    end
    return hist_db, pkg_set, sort(collect(date_set),rev=true)
end


# hist_to_html
# Take a matrix [dates pkgver status] and turns it into a simple
# multiline string that is used in the dropdown for each individual
# package
function hist_to_html(hist)
    output_str = ""
    for i = 1:size(hist,1)
        col_DATE    = hist[i,1]
        col_PKGVER  = hist[i,2]
        col_STATUS  = HUMANSTATUS[hist[i,3]]
        nice_day    = col_DATE[1:4]*"-"*col_DATE[5:6]*"-"*col_DATE[7:8]
        output_str *= nice_day * ", v" * col_PKGVER * ", " * col_STATUS * "\n"         
    end
    return output_str
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
        "<h4>$date</h4><ul>\n" * join(map(pkg_to_item, changes[date])) * "</ul>\n"
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
    return header * join(rows) * "</table>"
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
    cur_listing *= ">\n"

    # First line - Name
    cur_listing *= "<div class=\"row\">\n"
        cur_listing *= "<div class=\"col-xs-12\"><h2><a href=\"" * pkg["url"] * "\">" * pkg["name"] * "</a></h2></div>\n"
    cur_listing *= "</div>\n"

    # Second line - Description
    cur_listing *= "<div class=\"row\">\n"
        cur_listing *= "<div class=\"col-xs-12\"><h4>" * (pkg["githubdesc"] == nothing ? "" : pkg["githubdesc"]) * "</h4>"
        cur_listing *= "</div>\n"
    cur_listing *= "</div>\n"

    # Third line - Info
    cur_listing *= "<div class=\"row\">\n"
        # Version
        cur_listing *= "<div class=\"col-sm-4\"><p><b>Version: <a href=\"" * 
                        pkg["url"] * "/tree/" * pkg["gitsha"] * "\">" * pkg["version"] * " (" *
                        pkg["gitsha"][1:8] * ")</a></b></p></div>\n"

        # License
        licurl = ""
        if pkg["licfile"] != ""
            licurl = pkg["url"] * "/blob/" * pkg["gitsha"] * "/" * pkg["licfile"]
        else
            licurl = pkg["url"] * "/tree/" * pkg["gitsha"]
        end
        cur_listing *= "<div class=\"col-sm-3\"><p><b>License: <a href=\"" *
                        licurl * "\">" * pkg["license"] * "</a></b></p></div>\n"

        # Owner
        cur_listing *= "<div class=\"col-sm-3\"><p><b>Author: <a href=\"http://github.com/" *
                        owner * "\">" * owner * "</a></b></p></div>\n"

        # Permalink
        cur_listing *= "<div class=\"col-sm-2\">"
        cur_listing *= "<p><a href=\"" * "http://iainnz.github.io/packages.julialang.org/?pkg=" * pkg["name"] * "&ver=" * pkg["jlver"] * "\">" 
        cur_listing *= "<i class=\"glyphicon glyphicon-link\"></i>&nbsp;<b>Permalink</b></a></p></div>"

    cur_listing *= "</div>\n"

    # Fourth line - testing info
    cur_listing *= "<div class=\"row\">\n<div class=\"col-md-12\"><p>\n<b>Test status</b>: "
    cur_listing *= "<a href=\"badges/" * pkg["name"] * "_" * pkg["jlver"] * ".svg" * "\">" *
                   "<img src=\"badges/" * pkg["status"] * ".svg" * "\" alt=\"" * HUMANSTATUS[pkg["status"]] * "\"></a> "
    cur_listing *= HUMANSTATUS[pkg["status"]] * " "
    
    cur_listing *= "<a class=\"showlog\" data-pkg=\"" * pkg["name"] * "\" data-ver=\"" * pkg["jlver"] * "\">"
    cur_listing *= "<span id=\"" * pkg["name"] * pkg["jlver"][end:end] * "_loglink\">Show log</span></a> - "
    
    cur_listing *= "<a class=\"showhist\" data-pkg=\"" * pkg["name"] * "\" data-ver=\"" * pkg["jlver"] * "\">"
    cur_listing *= "<span id=\"" * pkg["name"] * pkg["jlver"][end:end] * "_histlink\">Show history</span></a></p>"

    cur_listing *= "<pre style=\"display: none;\" class=\"testlog\" id=\"" * pkg["name"] * pkg["jlver"][end:end] * "_log\"></pre>"
    hist_data = hist_to_html(hist_db[pkg["jlver"]*pkg["name"]])
    cur_listing *= "<pre style=\"display: none;\" class=\"testhist\" id=\"" * pkg["name"] * pkg["jlver"][end:end] * "_hist\">" * hist_data * "</pre>"
    cur_listing *= "</div></div>"


    push!(listing, cur_listing * "<hr></div>")
    #break
end

# Build package ecoystem health indicators
generate_plot(hist_db, pkg_set, date_set)
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