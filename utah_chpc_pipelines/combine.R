
library(tidyverse)

samples <- list.files("../Fastq") %>% word(1, sep = "_") %>% unique()
samples <- samples[samples != "md5"]
sample_numbers <- as.numeric(word(samples, 2, sep = "X"))
samples <- samples[order(sample_numbers)]

methylp <- list()
reads <- list()
stat <- data.frame(SEQUENCE_PAIRS = double(),
                   EFFICIENCY = double(),
                   METHYLATED_CPG = double(),
                   METHYLATED_CHG = double(),
                   METHYLATED_CHH = double(),
                   METHYLATED_UNKNOWN = double())


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
  
  stat[sample, "SEQUENCE_PAIRS"] <- 
    statin$X2[statin$X1 == "Sequence pairs analysed in total"]
  stat[sample, "EFFICIENCY"] <- 
    statin$X2[statin$X1 == "Mapping efficiency"]
  stat[sample, "METHYLATED_CPG"] <- 
    statin$X2[statin$X1 == "C methylated in CpG context"]
  stat[sample, "METHYLATED_CHG"] <- 
    statin$X2[statin$X1 == "C methylated in CHG context"]
  stat[sample, "METHYLATED_CHH"] <- 
    statin$X2[statin$X1 == "C methylated in CHH context"]
  stat[sample, "METHYLATED_UNKNOWN"] <- 
    statin$X2[statin$X1 == "C methylated in unknown context (CN or CHN)"]
}

# Combine data
methylp <- reduce(methylp, full_join, by = "LOCATION")
reads <- reduce(reads, full_join, by = "LOCATION")

# Write Data
# ------------------------------------------------------------------------------
run <- paste0(word(samples[1], 1, sep = "X"), "R")
write_tsv(methylp, paste0("../", run, "_methylp.tsv"))
write_tsv(reads, paste0("../", run, "_reads.tsv"))
write_tsv(stat, paste0("../", run, "_statistics.tsv"))


