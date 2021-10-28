#! /usr/bin/awk -f

# Adds barcodes to reads by appending barcode sequence to name of read
# ==============================================================================
# Parameters:
#   barcode.fastq file first
#   read.fastq file second
# ==============================================================================
# Example:
#   awk -f barcode.awk mybarcodes.fastq myreads.fastq > myreadswbarcodes.fastq
# ==============================================================================

NR == FNR {
    if (FNR % 4 == 1) read=$1
    else if (FNR % 4 == 2) barcode[read]=$1
    next
} {
    if (FNR %4 == 1) print $1"-"$2"+"barcode[$1]
    else print $0
}

