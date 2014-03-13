scp idunning@che.mit.edu:~/PackageEvaluator.jl/extra/stable/concat.json stable.json
scp idunning@che.mit.edu:~/PackageEvaluator.jl/extra/nightly/concat.json nightly.json
echo "[" > all.json
cat stable.json >> all.json
echo "," >> all.json
cat nightly.json >> all.json
echo "]" >> all.json
julia add_desc.jl