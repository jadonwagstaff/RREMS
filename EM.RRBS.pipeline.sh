
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
    awk -f barcode.awk "$from/$sample"_*_R2_* "$from/$sample"_*_R1_* > "$to/$sample"_test.fastq &
    awk -f barcode.awk "$from/$sample"_*_R2_* "$from/$sample"_*_R3_* > "$to/$sample"_R3.fastq &
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
    bash countz.sh "$to"/CpG_OB_"$sample".txt "$to"/CpG_OT_"$sample".txt > "$to/$sample"_methylation.cov &
    wait
    
    rm "$to"/CHG_*_"$sample".txt &
    rm "$to"/CHH_*_"$sample".txt &
    rm "$to"/CpG_*_"$sample".txt &
    wait
    
    # Make color bed file
    awk -v name=$sample -f colorbed.awk "$to/$sample"_methylation.cov > "$to/$sample"_methylation.bed

done <<< "$samples"






