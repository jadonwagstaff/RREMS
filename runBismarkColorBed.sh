source /uufs/chpc.utah.edu/common/home/u1071805/scripts/arg_parser.sh

usage () {
cat << help_message
	bash runBismarkColorBed.sh
		-f bismark coverage bed file as input
		-d coverage depth cutoff 
help_message
}

get_flags file=-f depth=-d

pwd > /dev/stderr
realpath . > /dev/stderr
realpath $file > /dev/stderr


if [[ $file =~ .gz ]]
then
	gunzip $file
fi

file=${file%.gz}

output=${file}"_ColorBed.bed"
outBed=${file}"_FilteredPercentMethylated.bed"

echo $file
echo $output
echo $outBed

bash /uufs/chpc.utah.edu/common/home/u1071805/scripts/Bismark.Cov.2.Color.Bed.collapseDinucleotides.sh $file $depth $outBed $output

sorted=${file}"_ColorBed.sorted.bed"

sort -k1,1 -k2,2n $output > $sorted

bigBed=${file}"_ColorBed.bb"
 
/uufs/chpc.utah.edu/common/home/u1071805/scripts/bedToBigBed $sorted /uufs/chpc.utah.edu/common/home/varley-group2/ReferenceGenomes/MarkWadsworth/hg19/hg19.chrom.sizes $bigBed


echo "Done"
