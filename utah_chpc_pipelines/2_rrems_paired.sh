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
# beginning before the "_" character. For example 19009X1_..._R1_001.fastq,
# 19009X1_..._R2_001.fastq, and 19009X1_..._R3_001.fastq are all sample 19009X1
# where R1 are the forward reads, R2 are the barcodes, and R3 are the reverse
# reads. If the naming convention does not follow this pattern then this loop
# will need to be rewritten.
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
    gunzip "$from/$sample"_*
    wait
    
    # Add barcodes
    singularity exec --no-home --cleanenv "$sb"/rrems-v0.1.1.sif \
        add_barcodes.py -n 12  -b "$from/$sample"_*_R2_* \
        -d "$from/$sample"_*_R1_* -o "$to/$sample"_R1.fastq &
    singularity exec --no-home --cleanenv "$sb"/rrems-v0.1.1.sif \
        add_barcodes.py -n 12  -b "$from/$sample"_*_R2_* \
        -d "$from/$sample"_*_R3_* -o "$to/$sample"_R3.fastq &
    wait
    
    # Zip raw data
    gzip "$from/$sample"_* &
    
    
    # Align reads and get methylation
    singularity exec --no-home --cleanenv "$sb"/rrems-v0.1.2.sif rrems.sh \
        -c $p -n "$sample" -r "$refpath" \
        "$to/$sample"_R1.fastq "$to/$sample"_R3.fastq
    wait

done <<< "$samples"

echo ""
echo "Job Finished"
date


