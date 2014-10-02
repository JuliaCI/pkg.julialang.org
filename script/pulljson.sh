#!/bin/bash
scp idunning@che.mit.edu:~/PackageEvaluator.jl/extra/all.json all.json
julia enhance_json.jl $1
julia build_html.jl
cd ~/Desktop/PkgPulse
julia plot_pkg.jl
julia build_pulse.jl
cp pulse.html ~/Dropbox/Websites/packages.julialang.org/
cp *.svg ~/Dropbox/Websites/packages.julialang.org/
