using Gadfly

include("shared.jl")

# plot_total_allvers
# Plot (with Gadfly) the total number of packages over
# all time and Julia versions.
function plot_total_allvers(totals, dates, outfile="")
    # Build an x-axis and y-axis for each version
    x_dates  = [ver=>Date[] for ver in keys(totals)]
    y_totals = [ver=>Int[]  for ver in keys(totals)]
    for ver in keys(totals)
        for i = 1:length(dates)
            y = totals[ver][dates[i]]["total"]
            if y > 0
                push!(x_dates[ver], dbdate_to_date(dates[i]))
                push!(y_totals[ver], y)
            end
        end
    end
    # Julia releases
    jl_date_vers = [Date(2014,08,20)  "v0.3.0"  250;
                    Date(2014,09,21)  "v0.3.1"  250;
                    Date(2014,10,21)  "v0.3.2"  250;
                    Date(2014,11,23)  "v0.3.3"  250;
                    Date(2014,12,26)  ""        250;
                    Date(2015,01,08)  "v0.3.5"  250;
                    Date(2015,02,17)  "v0.3.6"  250;
                    Date(2015,03,23)  "v0.3.7"  250;
                    Date(2015,04,30)  "v0.3.8"  250;
                    Date(2015,05,30)  "v0.3.9"  250;]
    p = plot(
        layer(x=x_dates["0.2"],y=y_totals["0.2"],color=fill("0.2",length(x_dates["0.2"])),Geom.line),
        layer(x=x_dates["0.3"],y=y_totals["0.3"],color=fill("0.3",length(x_dates["0.3"])),Geom.line),
        layer(x=x_dates["0.4"],y=y_totals["0.4"],color=fill("0.4",length(x_dates["0.4"])),Geom.line),
        layer(xintercept=jl_date_vers[:,1],Geom.vline(color="gray20",size=1px)),
        layer(x=jl_date_vers[:,1],y=jl_date_vers[:,3],label=jl_date_vers[:,2],Geom.label),
        Scale.y_continuous(minvalue=250,maxvalue=650),
        Guide.ylabel("Number of Tagged Packages"),
        Guide.xlabel("Date"),
        Guide.colorkey("Julia ver."),
        Theme(line_width=3px,label_placement_iterations=0))
    if outfile == ""
        draw(SVG(8inch, 3inch), p)
    else
        draw(SVG(outfile, 8inch, 3inch), p)
    end
end


# plot_total_allvers
# Plot (with Gadfly) the total number of packages over
# all time and Julia versions.
function plot_status_ver(totals, dates, ver, outfile=""; aspercent=false)
    # Build one x-axis, and y-axis for each status
    # Because we changed over to a new system 6/20/2015, we actually
    # need to collect two different histories otherwise we'll get
    # unsightly 0 totals for the old status forever.
    x_dates_old = Date[]
    x_dates = Date[]
    y_totals_old = [key=>Any[] for key in DBSTATUSCODES[1:5]]
    y_totals = [key=>Any[] for key in DBSTATUSCODES[5:8]]
    for i = 1:length(dates)
        v = totals[ver][dates[i]]
        d = dbdate_to_date(dates[i])
        if d <= Date(2015,6,18)
            # Old statuses
            if v["total"] > 0
                push!(x_dates_old, d)
                for key in DBSTATUSCODES[1:5]
                    push!(y_totals_old[key], 
                        aspercent ? v[key] / v["total"] * 100 :
                                    v[key])
                end
            end
        else
            # New statuses
            if v["total"] > 0
                push!(x_dates, d)
                for key in DBSTATUSCODES[5:8]
                    push!(y_totals[key],
                        aspercent ? v[key] / v["total"] * 100 :
                                    v[key])
                end
            end
        end
    end
    p = plot(
        [layer(x=x_dates_old,y=y_totals_old[key],color=fill("old"*key,length(x_dates_old)),Geom.line) 
            for key in DBSTATUSCODES[1:5]]...,
        [layer(x=x_dates,y=y_totals[key],color=fill("new"*key,length(x_dates)),Geom.line) 
            for key in DBSTATUSCODES[5:8]]...,
        Scale.y_continuous(minvalue=0,maxvalue=aspercent?100:350),
        Guide.ylabel((aspercent?"Percentage":"Number")*" of Packages",orientation=:vertical),
        Guide.xlabel("Date"),
        Guide.title("Julia $ver"),
        #Scale.x_continuous(labels=f->string(f)),
        Scale.color_discrete_manual("green","orange","blue","red","grey",
                                    "grey","green","red","blue"),
        Theme(#=line_width=3px,=#key_position=:none))
    if outfile == ""
        draw(SVG(4inch, 3inch), p)
    else
        draw(SVG(outfile, 4inch, 3inch), p)
    end
end


# plot_total_stars
# Plot (with Gadfly) the total number of stars over all time.
function plot_total_stars(totals, outfile="")
    # Build an x-axis and y-axis
    x_dates  = Date[]
    y_totals = Int[]
    for (date,total) in totals
        date == "20140925" && continue  # First entry, not accurate
        push!(x_dates, dbdate_to_date(date))
        push!(y_totals, total)
    end
    p = plot(
        layer(x=x_dates,y=y_totals,color=ones(length(y_totals)),Geom.line),
        #Scale.y_continuous(minvalue=250,maxvalue=450),
        Scale.color_discrete_manual("gold"),
        Guide.ylabel("Number of Stars"),
        Guide.xlabel("Date"),
        Theme(line_width=3px,key_position=:none))
    if outfile == ""
        draw(SVG(8inch, 3inch), p)
    else
        draw(SVG(outfile, 8inch, 3inch), p)
    end
end

hist, pkgnames, dates = load_hist_db(HIST_FILE)
totals = total_pkgs_by_date(hist, pkgnames, dates)
@show dates[1]
@show totals["0.3"][dates[1]]
@show dates[2]
@show totals["0.3"][dates[2]]
plot_total_allvers(totals, dates, "../allver.svg")
plot_status_ver(totals, dates, "0.2", "../test02.svg")
plot_status_ver(totals, dates, "0.3", "../test03.svg")
plot_status_ver(totals, dates, "0.4", "../test04.svg")
plot_status_ver(totals, dates, "0.2", "../test02per.svg",aspercent=true)
plot_status_ver(totals, dates, "0.3", "../test03per.svg",aspercent=true)
plot_status_ver(totals, dates, "0.4", "../test04per.svg",aspercent=true)

star_hist, star_dates = load_star_db(STAR_FILE)
star_totals = total_stars_by_date(star_hist, star_dates)
#plot_total_stars(star_totals, "../stars.svg")