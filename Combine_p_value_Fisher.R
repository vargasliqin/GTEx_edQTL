args <- commandArgs(trailingOnly=TRUE)
file <- args[1]
list <- args[2]
outputfile <- args[3]

library(dplyr)
library(metap)
library(aggregation)

file <- read.table(file=file, header = FALSE, comment.char = '&', sep = " ", stringsAsFactors = FALSE, as.is = TRUE, na.strings = "NA", check.names=FALSE)
#colnames(file) <- gsub("\\.","-",colnames(file))
list <- read.table(file=list, header = FALSE,  sep = "\t", stringsAsFactors = FALSE, as.is = TRUE, skip = 1)
rownames(list) <- paste0(list$V2,"_",list$V3-1)
#rownames(file) <- file$V1
annotation <- data.frame(cbind(paste0(list$V2,"_",list$V3-1), list$V5))
colnames(annotation) <- c("Site","Gene")
rownames(annotation) <- annotation$Site

new <- merge(x=file, y=annotation, by.x="V1", by.y="Site", all.x = TRUE)
new <- na.exclude(new)

#test <- new[1:1000,]
new.sum <- new %>%
  dplyr::group_by(V8, Gene) %>%
  dplyr::summarise(chr = V2[1], coord = V3[1], mean_dist = mean(V7), pvalue = fisher(V12), beta = mean(abs(V13)))

colnames(new.sum) <- c("SNP","Gene","chr","coord","mean_dist","pvalue","beta")
new.sum <- na.exclude(new.sum)

write.table(new.sum, file=outputfile, sep = "\t", quote = FALSE, row.names = FALSE)

