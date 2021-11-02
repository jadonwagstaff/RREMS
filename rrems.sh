#!/bin/bash

# Process Input
# ==============================================================================

# Help function
show_help() {
   echo "Runs rrems pipeline with the following options:"
   echo "trim-galore --rrbs --fastqc --paired"
   echo "bismark --quiet --bowtie2 --un --ambiguous"
   echo "bismark_methylation_extractor --paired-end"
   echo
   echo "Uses CpG context output from bismark_methylation_extractor"
   echo "to get percent methylation for each CpG (combined top and"
   echo "bottom strands)."
   echo
   echo "Requires a forward read file and a reverse read file."
   echo
   echo "Outputs a .cov file and a .bed file."
   echo
   echo "Required:"
   echo "-n    Sample name."
   echo "-r    Reference directory."
   echo "-b    Barcode file."
   echo "Optional"
   echo "-o    Output directory (default current directory)."
   echo "-c    Number of cores (default 6)"
   echo "-h    Print this help."
   echo
}

# Set variables
r2=
name=
ref=
to="."
cores=6

# Process options
OPTIND=1
while getopts "hn:o:r:b:c:" option; do
    case $option in
        h) # display Help
            show_help
            exit;;
        n) # Name of sample
            name=$OPTARG;;
        r) # reference directory
            ref=$OPTARG;;
        b) # Barcodes
            r2=$OPTARG;;
        o) # output directory
            to=$OPTARG;;
        c) # cores
            cores=$OPTARG;;
        \?) # Invalid option
            echo "Error: Invalid option"
            exit 1;;
   esac
done
shift $(( OPTIND-1 ))

# main input
r1=$1
r3=$2

# Check input
if [[ -z $r1 ]]; then
    echo "Error: parameter 1 is missing, need forward reads"
    exit 1
fi
if [[ -z $r3 ]]; then
    echo "Error: parameter 2 is missing, need reverse reads"
    exit 1
fi
if [[ -z $r2 ]]; then
    echo "Error: barcode file is missing, need -b value"
    exit 1
fi
if [[ -z $name ]]; then
    echo "Error: name is missing, need -n value"
    exit 1
fi
if [[ -z $ref ]]; then
    echo "Error: reference directory is missing, need -r value"
    exit 1
fi




# Pipeline
# ==============================================================================

# Uncompress raw data
gunzip "$r1" "$r2" "$r3"
r1="${r1%.gz}"
r2="${r2%.gz}"
r3="${r3%.gz}"


###   Add Barcodes   ###
echo "====================================================="
echo "ADDING BARCODES FOR " $name
echo "====================================================="
echo ""
barcode.awk "$r2" "$r1" > "$to/$name"_R1.fastq &
barcode.awk "$r2" "$r3" > "$to/$name"_R3.fastq &
wait

# Re-compress raw data
gzip "$r1" "$r2" "$r3"

# Make variables (clean reads)
c1="$to/$name"_R1
c3="$to/$name"_R3


###   Trim Adapters   ###
echo "====================================================="
echo "TRIMMING ADAPTERS FOR " $name
echo "====================================================="
trim_galore --output_dir $to --rrbs --fastqc --paired "$c1".fastq "$c3".fastq

# Clean up output
mv "$c1"_val_1.fq "$c1".fastq &
mv "$c3"_val_2.fq "$c3".fastq &
mv "$c1"_val_1_fastqc.html "$c1".fastq_fastqc_report.html &
mv "$c3"_val_2_fastqc.html "$c3".fastq_fastqc_report.html &
rm "$c1"_val_1_fastqc.zip "$c3"_val_2_fastqc.zip &
wait


###   Align Reads   ###
echo "====================================================="
echo "ALIGNING READS FOR " $name
echo "====================================================="
echo ""
bismark --quiet --output $to --parallel $cores --bowtie2 --un --ambiguous \
    -N 1 --non_bs_mm --genome_folder "$ref" -1 "$c1".fastq -2 "$c3".fastq

# Clean up output
mv "$c1"_bismark_bt2_PE_report.txt "$to/$name".bam_bismark_report.txt
mv "$c1"_bismark_bt2_pe.bam "$to/$name".bam

# Compress clean data
gzip "$to/$name"*.fastq


###   Extract Methylation Data   ###
echo "====================================================="
echo "EXTRACTING MMETHYLATION DATA FOR " $name
echo "====================================================="
echo ""
bismark_methylation_extractor --output $to --multicore $cores --paired-end "$to/$name".bam

# Clean up output
mv "$to/$name"_splitting_report.txt "$to/$name".bam_splitting_report.txt &
mv "$to/$name".M-bias.txt "$to/$name".bam_M-bias.txt &
countz.sh "$to"/CpG_OT_"$name".txt "$to"/CpG_OB_"$name".txt > "$to/$name"_methylation.cov &
wait

rm "$to"/CHG_*_"$name".txt &
rm "$to"/CHH_*_"$name".txt &
rm "$to"/CpG_*_"$name".txt &
wait

# Make color bed file
colorbed.awk -v name=$name "$to/$name"_methylation.cov > "$to/$name"_methylation.bed
