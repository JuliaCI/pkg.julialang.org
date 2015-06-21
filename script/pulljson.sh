#!/bin/bash
scp idunning@che.mit.edu:~/PackageEvaluator.jl/scripts/releaseAL.json releaseAL.json
scp idunning@che.mit.edu:~/PackageEvaluator.jl/scripts/releaseMZ.json releaseMZ.json
scp idunning@che.mit.edu:~/PackageEvaluator.jl/scripts/nightlyAL.json nightlyAL.json
scp idunning@che.mit.edu:~/PackageEvaluator.jl/scripts/nightlyMZ.json nightlyMZ.json
julia enhance_json.jl $1
echo "BUILD HTML"
julia build_html.jl
echo "BUILD PLOT"
julia plot_pkg.jl
echo "BUILD PULSE"
julia build_pulse.jl