#!/bin/bash
#SBATCH --time=1:00:00 --nodes=1 --ntasks=4 --mem=12G --account=varley-kp --partition=varley-shared-kp

echo "Data Transfer"

cd /uufs/chpc.utah.edu/common/home/varley-group3/FastqFiles/JadonWagstaff

java -jar /uufs/chpc.utah.edu/sys/pkg/fdt/0.9.20/fdt.jar \
    -noupdates -pull -r -c hci-bio-app.hci.utah.edu -d ./ \
    /scratch/fdtswap/fdt_sandbox_gnomex/f7e98056-46d9-4516-b89d-e37a637736a0/18708R

