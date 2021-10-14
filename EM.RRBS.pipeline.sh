
ml fastqc
ml bismark
ml bowtie2
ml bowtie
ml cutadapt
ml trim_galore
ml samtools



r1=$1
r2=$2
r3=$3

r1Base=`basename $r1`
r2Base=`basename $r2`
r3Base=`basename $r3`

directory=`dirname $r1`
cd $directory

gunzip *.fastq.gz &
wait

r1UMI="${r1Base%.fastq.gz}.UMIAdded.fastq"
r3UMI="${r3Base%.fastq.gz}.UMIAdded.fastq"

sample=`basename $directory`

echo "Adding Barcodes to Read Files"
# This is a script Ryan wrote and Mark modified to add the barcode (R2) to the header of the FastQ read files (R1 & R3)
python /uufs/chpc.utah.edu/common/home/varley-group2/FastqFiles/MarkWadsworth/scripts/addBarcodes_novaseq_variableSize.py -d ${r1Base%.gz} -b ${r2Base%.gz} -o $r1UMI -s $sample -n 12 &
python /uufs/chpc.utah.edu/common/home/varley-group2/FastqFiles/MarkWadsworth/scripts/addBarcodes_novaseq_variableSize.py -d ${r3Base%.gz} -b ${r2Base%.gz} -o $r3UMI -s $sample -n 12 &

wait

gzip *.fastq

r1UMI=`ls *R1*.UMIAdded.fastq.gz`
r3UMI=`ls *R3*.UMIAdded.fastq.gz`


echo $r1UMI
echo $r3UMI

echo "Run FastQC and Trim Reads"
## Runs FastQC on the original files
fastqc $r1UMI &
fastqc $r2Base &
fastqc $r3UMI &

## Trims the adapters off the reads. --rrbs is used here because we use the MspI cutsites and it controls for that.
trim_galore --rrbs --fastqc --paired $r1UMI $r3UMI &

wait

r1="${r1UMI%.fastq.gz}_val_1.fq.gz"
r3="${r3UMI%.fastq.gz}_val_2.fq.gz"

echo $r1
echo $r3

REFPATH="/uufs/chpc.utah.edu/common/home/varley-group2/ReferenceGenomes/RyanMiller/hg19"

echo "Bismark Alignment Started"
## Bismark alignment using Bowtie2
bismark --multicore 6 --bowtie2 --un --ambiguous -N 1 --temp_dir TempDelme --non_bs_mm $REFPATH -1 $r1 -2 $r3 --quiet -o ./bowtie2.trimmed/
echo "Bismark Alignment Finished"


cd bowtie2.trimmed/

bowtie2Bam=`ls *bismark_bt2_pe.bam`
## Extracts the CpG sites with their coverage
echo "Bismark Methylation extractor and report started"
bismark_methylation_extractor --bedgraph --zero_based -p $bowtie2Bam > $bowtie2Bam".methylationExtractor"
## Outputs a nice HTML report of the run
bismark2report

#gunzip *.cov.gz

#zeroCovFile=`ls *zero.cov`
#
#echo "Creating BigBed"
### This is a wrapper script Mark Wadsworth wrote that calls another script he wrote that turns the coverage file to a color coded  bigbed file for the UCSC Genome Browser track.
#bash /uufs/chpc.utah.edu/common/home/varley-group2/FastqFiles/MarkWadsworth/scripts/runBismarkColorBed.sh -f $zeroCovFile -d 10
#
#echo "Creating 10x coverage file"
### Creates a file of thee CpG to the percent methylation. This file will be merged with the other samples from the run.
#awk -F"\t" '{if($5+$6 >= 10) print $1" "$2"\t"$4}' $zeroCovFile > "${zeroCovFile}.cpgs.moreThan10XCov.txt"

cd ../






