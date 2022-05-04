args <- commandArgs(trailingOnly=TRUE)
ed_file <- args[1]
annot_study <- args[2]
out_file <- args[3]

#ed <- read.table(file="Thyroid.edMat.20cov.60samps.noXYM.qqnorm.bed.gz",header = T, as.is = T, check.names = F, stringsAsFactors = F, comment.char = "")
ed <- read.table(file=ed_file,header = T, as.is = T, check.names = F, stringsAsFactors = F, comment.char = "")
ed$`chr#Chr_end` <- paste(ed$`#Chr`,ed$end+1,sep="_")

#annot <- read.table(file="/labs/lilab/qin/GTEx/scripts/All.AG.stranded.annovar.Hg38_multianno.AnnoAlu.AnnoRep.NR.AnnoVar_Genes.txt", header = T, as.is = T, check.names = F, stringsAsFactors = F, comment.char = "")
annot <- read.table(file=annot_study, header = T, as.is = T, check.names = F, stringsAsFactors = F, comment.char = "")

merge <- merge(annot, ed, by.y="chr#Chr_end", by.x="Chr_Start",all.y = T)
merge$pid <- paste(merge$Chr,merge$end,sep="_")
merge$gid <- merge$Gene.refGene
merge$strand <- "+"
idx <- which(merge$Ref == "T")
merge$strand[idx] <- "-"

out <- cbind(merge[,c(6,7,8)],pid=merge$pid,gid=merge$gid,strand=merge$strand,merge[,c(9:(dim(merge)[2]-3))])

write.table(file=out_file,x = out,sep = "\t",quote = F,row.names = F,col.names = T)

