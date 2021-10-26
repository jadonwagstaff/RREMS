# Combine top and bottom strand then count number of methylated and unmethylated
# ==============================================================================
# Parameters:
#   top strand extracted methylation calls
#   bottom strand extracted methylation calls
# ==============================================================================
# Example:
#   bash countz.sh top_strand.txt bottom_strand.sh
# ==============================================================================

top=$1
bottom=$2

awk '{if (NR > 1) {print $3, $4, $5}}' "$top" > "$top"_temp.txt &
awk '{if (NR > 1) {print $3, $4 - 1, $5}}' "$bottom" > "$bottom"_temp.txt &
wait


cat "$top"_temp.txt "$bottom"_temp.txt |
awk '{a[$0]++ } END{for (x in a) print x, a[x]}' |
awk '{if ($3 == "Z") print $1, $2, $4, 0; else print $1, $2, 0, $4}' |
awk '{a[$1 " " $2] += $3; b[$1 " " $2] += $4} END{for (x in a) print x, a[x], b[x]}' |
awk 'BEGIN{OFS = "\t"} {$1 = $1; if ($3 + $4 >= 10) print $1, $2 - 1, $2 + 1, $3 / ($3 + $4), $3, $4}'

rm "$top"_temp.txt "$bottom"_temp.txt
