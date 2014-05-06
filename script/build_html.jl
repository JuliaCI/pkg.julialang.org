#######################################################################
# packages.julialang.org
# build_html.jl
# Build the actual site by sticking together a header and footer
#######################################################################

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
    return hist_db, pkg_set, date_set
end

# hist_to_html
# Take a matrix [DATE PKGVER STATUS; ...] and turn it into something
# we can inject into the web page
function hist_to_html(hist)
    hist = sort(hist, 1, rev=true)
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

# build_stats
# Take the history database and extract summary statistics for it
function extract_stats(hist_db, pkg_set, date_set)
    # Want to count number of packages are in each category on 
    # each day
    totals_by_day = Dict()
    for date in date_set
        totals_by_day[date] = [ "full_pass" => 0,
                                "full_fail" => 0,
                                "using_pass" => 0,
                                "using_fail" => 0,
                                "not_possible" => 0,
                                "total" => 0]
    end

    for pkg in pkg_set
        key  = "0.3"*pkg
        !(key in keys(hist_db)) && continue
        hist = hist_db[key]
        for i = 1:size(hist,1)
            col_DATE    = hist[i,1]
            col_STATUS  = hist[i,3]
            totals_by_day[col_DATE][col_STATUS] += 1
            totals_by_day[col_DATE]["total"] += 1
        end
    end

    sorted_dates = sort(collect(date_set),rev=true)
    output_table = "<table class=\"table healthtable\"><tr>" * 
                                 "<td>Date</td>" *
                                 "<td>Full Pass</td>" *
                                 "<td>Full Fail</td>" *
                                 "<td>Using Pass</td>" *
                                 "<td>Using Fail</td>" *
                                 "<td>Not Possible</td>" *
                                 "<td>Total</td></tr>"
    data_matrix = zeros(length(sorted_dates), 7)
    function to_td(d,s,r,c)  # Has sideeffects on data_matrix!
        v = totals_by_day[d][s]
        t = totals_by_day[d]["total"]
        data_matrix[r,c] = v #/t*100
        return string("<td>", v, " (", int(round(v/t*100,0)), "%)</td>")
    end
    row = 0
    baseline_day = strptime("%Y%m%d", sorted_dates[1]).yday
    for date in sorted_dates
        row += 1
        output_table *= "<tr><td>$date</td>" *
                        to_td(date,"full_pass",row,2) *
                        to_td(date,"full_fail",row,3) *
                        to_td(date,"using_pass",row,4) *
                        to_td(date,"using_fail",row,5) *
                        to_td(date,"not_possible",row,6) *
                        to_td(date,"total",row,7) * "</tr>"
        data_matrix[row,1] = strptime("%Y%m%d", date).yday - baseline_day
    end
    output_table *= "</table>"

    # Turn data_matrix into a plot
    plt.plot(data_matrix[:,1], data_matrix[:,2], color="green", label="Full Pass", linewidth=2, marker="o")
    plt.plot(data_matrix[:,1], data_matrix[:,3], color="orange", label="Full Fail", linewidth=2, marker="o")
    plt.plot(data_matrix[:,1], data_matrix[:,4], color="blue", label="Using Pass", linewidth=2, marker="o")
    plt.plot(data_matrix[:,1], data_matrix[:,5], color="red", label="Using Fail", linewidth=2, marker="o")
    plt.plot(data_matrix[:,1], data_matrix[:,6], color="grey", label="Not Tested", linewidth=2, marker="o")
    plt.legend(loc=7)
    plt.xlabel("Days Ago")
    plt.ylabel("Number of Packages")
    plt.title("Package Test Status Counts for Julia 0.3")
    savefig("../pkghist.png")

    return output_table
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
        cur_listing *= "<i class=\"glyphicon glyphicon-link\"></i> <b>Permalink</b></a></p></div>"

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

# Build package ecoystem health indicator
output_table = extract_stats(hist_db, pkg_set, date_set)
health = "<div class=\"container\" id=\"pkgstats\"><div class=\"row\"><div class=\"col-md-6\">" *
         "<img src=\"pkghist.png\" alt=\"Package test history\" class=\"img-responsive\">" *
         "</div><div class=\"col-md-6\">" * 
         output_table *
         "</div></div></div>"

# Output
fp = open("../index.html","w")
print(fp, index_head * health * join(listing,"\n") * index_tail)
close(fp)