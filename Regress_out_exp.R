args <- commandArgs(trailingOnly=TRUE)
ed_file <- args[1]
tissue <- args[2]
out_file <- args[3]

library(gtools)
#load(file="/labs/lilab/qin/GTEx/Expression_vs_editing/Thyroid.RData")
#ed <- read.delim(file="/labs/lilab/qin/GTEx/edQTL/V8_cis/FineTissue/Muscle-Skeletal/Muscle-Skeletal.edMat.20cov.60samps.noXYM.qqnorm.gid.bed.gz",as.is = T, check.names = F, stringsAsFactors = F)
ed <- read.delim(file=ed_file,as.is = T, check.names = F, stringsAsFactors = F)

ensgID2GeneName <- read.delim(file="/labs/lilab/shared-data/GTEx/Databases/ENSGID_to_GeneName.txt", header = T, stringsAsFactors = F)

ExpressionLevel.V8 <- readRDS(file="/labs/lilab/qin/GTEx/Expression_vs_editing/ExpressionLevel.V8.RDS")
colnames(ExpressionLevel.V8) <- gsub(pattern = "\\.",replacement = "-",x = colnames(ExpressionLevel.V8), perl = T)
SampleDiscription <- read.delim("/labs/lilab/qin/GTEx/Expression_vs_editing/GTEx_Analysis_2017-06-05_v8_Annotations_SampleAttributesDS.txt", stringsAsFactors = F)

tissue_table <- read.delim(file="/labs/lilab/qin/GTEx/scripts/Tissue_type_fix.txt",header = T, stringsAsFactors = F)
tissue_new <- tissue_table[which(tissue_table$Fix == tissue),1]
idx <- which(colnames(ExpressionLevel.V8) %in% as.character(SampleDiscription$SAMPID[which(SampleDiscription$SMTSD == tissue_new)]))

exp <- ExpressionLevel.V8[idx]
colnames(exp) <- apply(sapply(strsplit(colnames(exp), split = "-", fixed=TRUE), "[",c(1,2)),2,paste,collapse="-")
exp$ENSG <- sapply(strsplit(rownames(exp), split = "\\.", perl = T), "[",1)

exp <- merge(exp,ensgID2GeneName, by.x = "ENSG",by.y = "Gene.stable.ID")
ed_new <- (ed[FALSE,-c(1:6)])

for (i in 1:nrow(ed)){
  cat(i,"/",nrow(ed),"\n")
  site <- data.frame(t(ed[i,-c(1:6)]))
  gene <- ed$gid[i]
  idx <- which(exp$Gene.name == gene)
  if (length(idx) > 0){
    exp <- data.frame(t(exp[idx,]))
    mat <- merge(site,exp, by = "row.names")
    lm <- lm(as.numeric(mat[,2])~as.numeric(mat[,3]))
    res <- data.frame(t(lm$residuals))
    colnames(res) <- mat$Row.names
    ed_new[i,] <- res[,colnames(ed_new)]
  } else {
    ed_new[i,] <- data.frame(t(site))
  }
}

ed_new <- cbind(ed[,1:6],ed_new)
#write.table(x = ed_new,file = "Muscle-Skeletal.edMat.exp_regress.20cov.60samps.noXYM.qqnorm.gid.bed",quote = F, row.names = F, col.names = T,sep = "\t")
write.table(x = ed_new,file = out_file, quote = F, row.names = F, col.names = T,sep = "\t")
