#!/bin/bash
scp idunning@che.mit.edu:~/PackageEvaluator.jl/extra/stable/concat.json stable.json
scp idunning@che.mit.edu:~/PackageEvaluator.jl/extra/nightly/concat.json nightly.json
julia concat.jl
julia add_desc.jl
julia add_hist.jl $1
julia merge_hist.jl