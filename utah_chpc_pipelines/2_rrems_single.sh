#!/bin/bash
#SBATCH --time=120:00:00 --nodes=1 --account=varley-kp --partition=varley-kp

ml singularity

# Change this to the directory where your data is located
from="../Fastq"
# Change this to the directory where you want the alignments to be saved
to="../Aligned"
# Change this to the reference path
refpath="/uufs/chpc.utah.edu/common/home/varley-group3/FastqFiles/JadonWagstaff/ReferenceGenomes/hg19"
# Change this to the location of the singularity docker build
sb="/uufs/chpc.utah.edu/common/home/varley-group3/FastqFiles/JadonWagstaff/Pipelines"
# Change this for the appropriate number of parallel assemblies
p=12


# This will loop through all of the samples where each sample has a unique
# beginning before the "_" character. For example 13697X2_..._5.fastq.gz.
# If the naming convention does not follow this pattern then this loop will need
# to be rewritten.
samples=$(ls $from | awk -F_ '{print $1}' | uniq)

echo "Job Started"
date

while IFS= read -r sample
do
    echo "====================================================="
    echo "PROCESSING SAMPLE " $sample
    echo "====================================================="
    
    # Make a new directory
    mkdir "$to"
    
    # Unzip raw data
    gunzip -c "$from/$sample"_* > "$to/$sample".fastq
    wait
    
    # Align reads and get methylation
    singularity exec --no-home --cleanenv "$sb"/rrems-v0.1.2.sif rrems.sh \
        -c $p -n "$sample" -r "$refpath" "$to/$sample".fastq
    wait

done <<< "$samples"

echo ""
echo "Job Finished"
date



