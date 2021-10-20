
ml fastqc
ml bismark
ml bowtie2
ml bowtie
ml cutadapt
ml trim_galore
ml samtools

from=$1
to=$2

samples=$(ls $from | awk -F_ '{print $1}' | uniq)
REFPATH="/uufs/chpc.utah.edu/common/home/varley-group2/ReferenceGenomes/RyanMiller/hg19"

while IFS= read -r sample
do
    # Uncompress raw data
    gunzip "$from/$sample"*.fastq.gz


    ###   Add Barcodes   ###
    echo "====================================================="
    echo "ADDING BARCODES FOR " $sample
    echo "====================================================="
    echo ""
    python addBarcodes_novaseq_variableSize.py -d "$from/$sample"_*_R1_* -b "$from/$sample"_*_R2_* -o "$to/$sample"_R1.fastq -s $sample -n 12 &
    python addBarcodes_novaseq_variableSize.py -d "$from/$sample"_*_R3_* -b "$from/$sample"_*_R2_* -o "$to/$sample"_R3.fastq -s $sample -n 12 &
    wait

    # Re-compress raw data
    gzip "$from/$sample"*.fastq

    # Make variables
    r1="$to/$sample"_R1
    r3="$to/$sample"_R3


    ###   Trim Adapters   ###
    echo "====================================================="
    echo "TRIMMING ADAPTERS FOR " $sample "\n\n\n"
    echo "====================================================="
    trim_galore --output_dir $to --rrbs --fastqc --paired "$r1".fastq "$r3".fastq

    # Clean up output
    mv "$r1"_val_1.fq "$r1".fastq &
    mv "$r3"_val_2.fq "$r3".fastq &
    mv "$r1"_val_1_fastqc.html "$r1".fastq_fastqc_report.html &
    mv "$r3"_val_2_fastqc.html "$r3".fastq_fastqc_report.html &
    rm "$r1"_val_1_fastqc.zip "$r3"_val_2_fastqc.zip &
    wait


    ###   Align Reads   ###
    echo "====================================================="
    echo "ALIGNING READS FOR " $sample
    echo "====================================================="
    echo ""
    bismark --quiet --output $to --multicore 6 --bowtie2 --un --ambiguous -N 1 --temp_dir TempDelme --non_bs_mm $REFPATH -1 "$r1".fastq -2 "$r3".fastq
    
    # Clean up output
    mv "$r1"_bismark_bt2_PE_report.txt "$to/$sample".bam_bismark_report.txt
    mv "$r1"_bismark_bt2_pe.bam "$to/$sample".bam

    # Compress clean data
    gzip "$to/$sample"*.fastq


    ###   Extract Methylation Data   ###
    echo "====================================================="
    echo "EXTRACTING MMETHYLATION DATA FOR " $sample
    echo "====================================================="
    echo ""
    bismark_methylation_extractor --output $to --multicore 6 --paired-end "$to/$sample".bam
    
    # Clean up output
    mv "$to/$sample"_splitting_report.txt "$to/$sample".bam_splitting_report.txt &
    mv "$to/$sample".M-bias.txt "$to/$sample".bam_M-bias.txt &
    awk '{if (NR > 1) {print $3, $4 - 1, $5}}' "$to"/CpG_OB_"$sample".txt > "$to/$sample"_OB.txt &
    awk '{if (NR > 1) {print $3, $4, $5}}' "$to"/CpG_OT_"$sample".txt > "$to/$sample"_OT.txt &
    wait
    
    rm "$to"/CHG_*_"$sample".txt &
    rm "$to"/CHH_*_"$sample".txt &
    rm "$to"/CpG_*_"$sample".txt &
    wait
    
    # Combine top and bottom strand then count number of methylated and unmethylated
    cat "$to/$sample"_OB.txt "$to/$sample"_OT.txt |
    awk '{if (NR != 1) a[$0]++ } END{for (x in a) print x, a[x]}' |
    awk '{if ($3 == "Z") print $1, $2, $4, 0; else print $1, $2, 0, $4}' |
    awk '{a[$1 " " $2] += $3; b[$1 " " $2] += $4} END{for (x in a) print x, a[x], b[x]}' |
    awk 'BEGIN{OFS = "\t"; print "Chromosome", "Location", "Methylated", "Unmethylated", "MethylP"} {$1 = $1; if ($3 + $4 >= 10) print $0, $3 / ($3 + $4)}' > "$to/$sample"_methylation.txt
    
    rm "$to/$sample"_OB.txt "$to/$sample"_OT.txt

done <<< "$samples"






