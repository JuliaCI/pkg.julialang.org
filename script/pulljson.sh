#!/bin/bash
#scp idunning@50.136.95.12:~/PackageEvaluator.jl/scripts/releaseAL.json releaseAL.json
#scp idunning@50.136.95.12:~/PackageEvaluator.jl/scripts/releaseMZ.json releaseMZ.json
#scp idunning@50.136.95.12:~/PackageEvaluator.jl/scripts/nightlyAL.json nightlyAL.json
#scp idunning@50.136.95.12:~/PackageEvaluator.jl/scripts/nightlyMZ.json nightlyMZ.json
#scp idunning@192.168.8.104:~/PackageEvaluator.jl/scripts/releaseAL.json releaseAL.json
#scp idunning@192.168.8.104:~/PackageEvaluator.jl/scripts/releaseMZ.json releaseMZ.json
#scp idunning@192.168.8.104:~/PackageEvaluator.jl/scripts/nightlyAL.json nightlyAL.json
#scp idunning@192.168.8.104:~/PackageEvaluator.jl/scripts/nightlyMZ.json nightlyMZ.json
cp /Users/idunning/.julia/v0.3/PackageEvaluator/scripts/releaseAL.json releaseAL.json
cp /Users/idunning/.julia/v0.3/PackageEvaluator/scripts/releaseMZ.json releaseMZ.json
cp /Users/idunning/.julia/v0.3/PackageEvaluator/scripts/nightlyAL.json nightlyAL.json
cp /Users/idunning/.julia/v0.3/PackageEvaluator/scripts/nightlyMZ.json nightlyMZ.json

julia enhance_json.jl $1
echo "BUILD HTML"
julia build_html.jl
echo "BUILD PLOT"
julia plot_pkg.jl
echo "BUILD PULSE"
julia build_pulse.jl