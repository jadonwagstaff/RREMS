
library(tidyverse)

samples <- list.files("../Fastq") %>% word(1, sep = "_") %>% unique()
samples <- samples[samples != "md5"]
sample_numbers <- as.numeric(word(samples, 2, sep = "X"))
samples <- samples[order(sample_numbers)]

methylp <- list()
reads <- list()
stat <- data.frame(percentAlignedReads = double(),
                   alignedReads = double(),
                   methCpG = double(),
                   methCHG = double(),
                   methCHH = double(),
                   methUnknownCNorCHN = double(),
                   CGsW10XCoverage = double())


# Read data
# ------------------------------------------------------------------------------
for (sample in samples) {
  
  # Reads and percent methylated
  input <- read_tsv(paste0("../Aligned/", sample, "_methylation.cov"),
                    col_names = c("CHROMOSOME", "START", "STOP", "METHYLP", 
                                  "METHYLATED", "UNMETHYLATED")) %>%
    mutate(LOCATION = paste0(CHROMOSOME, ":", START, "-", STOP))
  
  methylp[[sample]] <- input %>%
    select(LOCATION, METHYLP)
  names(methylp[[sample]])[2] <- sample
  
  reads[[sample]] <- input %>%
    mutate(READS = METHYLATED + UNMETHYLATED) %>%
    select(LOCATION, READS)
  names(reads[[sample]])[2] <- sample
  
  # Sample statistics
  statin <- read_delim(paste0("../Aligned/", sample, ".bam_bismark_report.txt"),
                     delim = ":\t+", col_names = FALSE) %>%
    mutate(X2 = parse_number(X2))
  
  stat[sample, "percentAlignedReads"] <- 
    statin$X2[statin$X1 == "Mapping efficiency"]
  stat[sample, "alignedReads"] <- 
    statin$X2[statin$X1 %in% c("Number of paired-end alignments with a unique best hit",
                               "Number of alignments with a unique best hit from the different alignments")]
  stat[sample, "methCpG"] <- 
    statin$X2[statin$X1 == "C methylated in CpG context"]
  stat[sample, "methCHG"] <- 
    statin$X2[statin$X1 == "C methylated in CHG context"]
  stat[sample, "methCHH"] <- 
    statin$X2[statin$X1 == "C methylated in CHH context"]
  stat[sample, "methUnknownCNorCHN"] <- 
    statin$X2[statin$X1 %in% c("C methylated in unknown context (CN or CHN)",
                               "C methylated in Unknown context (CN or CHN)")]
  stat[sample, "CGsW10XCoverage"] <- nrow(input)
}

# Combine data
methylp <- reduce(methylp, full_join, by = "LOCATION")
reads <- reduce(reads, full_join, by = "LOCATION")
stat <- stat %>%
  rownames_to_column("SampleID")

# Write Data
# ------------------------------------------------------------------------------
run <- paste0(word(samples[1], 1, sep = "X"), "R")
write_tsv(methylp, paste0("../", run, "_methylp.tsv"))
write_tsv(reads, paste0("../", run, "_reads.tsv"))
write_tsv(stat, paste0("../", run, "_statistics.tsv"))


