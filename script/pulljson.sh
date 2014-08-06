#!/bin/bash
scp idunning@che.mit.edu:~/PackageEvaluator.jl/extra/all.json all.json
julia enhance_json.jl $1
julia build_html.jl
