#!/bin/bash
#SBATCH --time=1:00:00 --nodes=1 --account=varley-kp --partition=varley-kp

ml singularity

# Change this to the repeat samples that you want to combine
declare -a files=(
    "first_path/first_file.bam"
    "second_path/second_file.bam"
)
# Change this to the location of the singularity docker build
sb="/uufs/chpc.utah.edu/common/home/varley-group3/FastqFiles/JadonWagstaff/Pipelines"
# Change this for the appropriate number of parallel assemblies
p=12

# Extract methylation data from bam files
# ------------------------------------------------------------------------------
delim=_
for i in ${!files[@]}; do
    singularity exec --no-home --cleanenv "$sb"/rrems-v0.1.1.sif \
    bismark_methylation_extractor --paired-end --multicore $p "${files[$i]}"
    
    name="$(basename ${files[$i]} .bam)"
    if [ $i == 0 ]; then
        mv CpG_OT_"$name".txt OT.txt
        mv CpG_OB_"$name".txt OB.txt
        
        # Establish output file name
        outfile="$name"
    else
        # Combine with first strand
        awk '{if (FNR != 1 || NR == 1 ) {print $0}}' OT.txt CpG_OT_"$name".txt \
            > OT_temp.txt
        awk '{if (FNR != 1 || NR == 1 ) {print $0}}' OB.txt CpG_OB_"$name".txt \
            > OB_temp.txt
        mv OT_temp.txt OT.txt
        mv OB_temp.txt OB.txt
        
        # Establish output file name
        outfile="$outfile$delim$name"
    fi
done

# Clean up output
rm *_splitting_report.txt  &
rm *.M-bias.txt &
rm CHG_*.txt &
rm CHH_*.txt &
rm CpG_*.txt &
wait

singularity exec --no-home --cleanenv "$sb"/rrems-v0.1.2.sif countz.sh \
    OT.txt OB.txt > "$outfile"_methylation.cov

rm OT.txt OB.txt





