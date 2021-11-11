#!/bin/bash
#SBATCH --time=1:00:00 --nodes=1 --ntasks=4 --mem=32G --account=varley-kp --partition=varley-shared-kp

ml R

Rscript combine.R

echo "Job Done"

