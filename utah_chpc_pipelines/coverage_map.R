library(tidyverse)

hg19_lengths <- c(
  chr1 = 249250621,
  chr2 = 243199373,
  chr3 = 198022430,
  chr4 = 191154276,
  chr5 = 180915260,
  chr6 = 171115067,
  chr7 = 159138663,
  chr8 = 146364022,
  chr9 = 141213431,
  chr10 = 135534747,
  chr11 = 135006516,
  chr12 = 133851895,
  chr13 = 115169878,
  chr14 = 107349540,
  chr15 = 102531392,
  chr16 = 90354753,
  chr17 = 81195210,
  chr18 = 78077248,
  chr19 = 59128983,
  chr20 = 63025520,
  chr21 = 48129895,
  chr22 = 51304566,
  chrX = 155270560,
  chrY = 59373566
)

hg19_centromeres<- c(
  chr1 = 121535434,
  chr2 = 92326171,
  chr3 = 90504854,
  chr4 = 49660117,
  chr5 = 46405641,
  chr6 = 58830166,
  chr7 = 58054331,
  chr8 = 43838887,	
  chr9 = 47367679,
  chr10 = 39254935,	
  chr11 = 51644205,
  chr12 = 34856694,
  chr13 = 16000000,
  chr14 = 16000000,
  chr15 = 17000000,
  chr16 = 35335801,
  chr17 = 22263006,
  chr18 = 15460898,
  chr19 = 24681782,
  chr20 = 26369569,
  chr21 = 11288129,
  chr22 = 13000000,
  chrX = 58632012,
  chrY = 10104553
)

chr_data <- data.frame(CHR = factor(names(hg19_lengths), 
                                    levels = names(hg19_lengths)), 
                       LENGTH = hg19_lengths, 
                       CENT = hg19_centromeres)

args <- commandArgs(TRUE)

cgs <- read_tsv(args[1], col_names = FALSE) %>%
  mutate(COUNT = X5 + X6) %>%
  select(CHR = X1, START = X2, COUNT) %>%
  filter(CHR %in% names(hg19_lengths)) %>%
  mutate(START = floor(START / 1000000),
         START = START * 1000000) %>%
  group_by(CHR, START) %>%
  summarise(COUNT = sum(COUNT))

png(args[2], width = 900, height = 600)
ggplot(chr_data, aes(y = CHR, yend = CHR)) +
  geom_segment(aes(x = 0, xend = LENGTH), color = "gray50") +
  geom_point(aes(x = CENT + 1500000), shape = 5,
               size = 1.5, color = "gray50") +
  geom_segment(data = cgs, 
               aes(x = START, xend = START + 1000000, color = COUNT, size = COUNT)) +
  scale_color_viridis_c( trans = "log2") +
  theme_bw() +
  xlab("") +
  ylab("") +
  ggtitle(paste(args[3], "Coverage")) +
  theme(panel.grid = element_blank(), 
        axis.ticks.x = element_blank(), 
        axis.text.x = element_blank())
  

