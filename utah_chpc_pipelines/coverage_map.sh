#!/bin/bash
#SBATCH --time=1:00:00 --nodes=1 --ntasks=12 --mem=32G --account=varley-kp --partition=varley-shared-kp

ml singularity
ml R

# Change this to the directory where your data is located
from="../Aligned"
# Change this to the directory where you want the plots saved
to="../Plots"
# Change this to the location of the singularity docker build
sb="/uufs/chpc.utah.edu/common/home/varley-group3/FastqFiles/JadonWagstaff/Pipelines"
# Change this for the appropriate number of parallel assemblies
p=12

mkdir $to

# This will loop through all of the samples where each sample has a unique
# beginning before the "_" character. For example 13697X2_..._5.fastq.gz.
# If the naming convention does not follow this pattern then this loop will need
# to be rewritten.
bams=$(ls $from/*.bam)

while IFS= read -r bam
do
    singularity exec --no-home --cleanenv "$sb"/rrems-v0.1.2.sif \
    bismark_methylation_extractor --output "$to" --multicore $p "$bam"
    
    name="$(basename $bam .bam)"
    
    singularity exec --no-home --cleanenv "$sb"/rrems-v0.1.2.sif countz.sh \
    "$to"/CpG_OT_"$name".txt "$to"/CpG_OB_"$name".txt 1 > "$to/$name"_all.cov
    
    Rscript coverage_map.R "$to/$name"_all.cov "$to/$name"_coverage.png "$name"
    
done <<< "$bams"

# Clean up output
rm "$to"/*.cov
rm "$to"/*_splitting_report.txt  &
rm "$to"/*.M-bias.txt &
rm "$to"/CHG_*.txt &
rm "$to"/CHH_*.txt &
rm "$to"/CpG_*.txt &
wait





