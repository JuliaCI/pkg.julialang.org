#!/bin/bash
scp idunning@che.mit.edu:~/PackageEvaluator.jl/extra/stable/concat.json stable.json
scp idunning@che.mit.edu:~/PackageEvaluator.jl/extra/nightly/concat.json nightly.json
julia enhance_json.jl $1
julia build_html.jl