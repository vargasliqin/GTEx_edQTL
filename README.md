# GTEx_edQTL
This depository contains code used to produce cis RNA editing QTL (edQTL) mapping results using the v8 GTEx data.

The edQTL mapping data is deposited at https://gtexportal.org.

## Quantification of RNA editing levels
To quantify RNA editing levels in the v8 GTEx RNA-seq data, use [Docker](https://github.com/vargasliqin/mpileup) to run [parse_pileup_query.pl](parse_pileup_query.pl)

## Combine individual editing data into a matrix
Run the [sharedsamples_sites_matrix_FastQTL_v8.pl](sharedsamples_sites_matrix_FastQTL_v8.pl) script to convert individual editing data files into a matrix. Change `minsamps` in the script to set the minimum number of samples per site (default is 60 samples). Change `mincov` to set the minimum reads coverage per site (default is 20 reads).

```bash
perl sharedsamples_sites_matrix_FastQTL_v8.pl > ${tissue}.edMat.20cov.60samps.txt
```
## Convert editing level matrices to format recognized by FastQTL
Use the [prepare_phenotype_table_for_QTLtools.V8.py](prepare_phenotype_table_for_QTLtools.V8.py) script to convert. This step will also perform quantile normalization of editing level across samples. `tabix` is also required.

```bash
python /labs/lilab/qin/GTEx/scripts/prepare_phenotype_table_for_QTLtools.V8.py -p 15 ${tissue}.edMat.20cov.60samps.noXYM.txt
sh ${tissue}.edMat.20cov.60samps.noXYM.txt_prepare.sh
zcat ${tissue}.edMat.20cov.60samps.noXYM.txt.qqnorm_chr*gz | sed 's/nan/NA/g' | sort -k 1,1 -k2n,2 | awk '{print "chr"$1,$2,$3,"chr"$1"_"$3,$0}' OFS="\t" | cut -f 1,2,3,4,9- | sed 's/^chr#/#/g' | bgzip -c > ${tissue}.edMat.20cov.60samps.noXYM.qqnorm.bed.gz
tabix -f -p bed ${tissue}.edMat.20cov.60samps.noXYM.qqnorm.bed.gz
```
## Obtain PEER factors from the combined editing level matrices
Obtain PEER factors of the editing levels using [run_PEER.R](run_PEER.R). This step will output `${tissue}.edMat.20cov.60samps.noXYM.qqnorm.PEER_covariates.txt` file containing the top 60 PEER factors.
```bash
Rscript /labs/lilab/qin/software/gtex-pipeline/qtl/src/run_PEER.R \
    ${tissue}.edMat.20cov.60samps.noXYM.qqnorm.bed.gz \
    ${tissue}.edMat.20cov.60samps.noXYM.qqnorm \
    60
```
## Combine genotype PCs with phenotype PEER factors
The genotype PCs are obtained from the genotyping VCF file (generated by the GTEx consortium). Also include sex and age information as additional covariates.
```bash
python combine_covariates.py \
    ${tissue}.edMat.20cov.60samps.noXYM.qqnorm.PEER_covariates.txt \
    ${tissue}.edMat.20cov.60samps.noXYM.qqnorm \
    -o ${tissue} \
    --add_covariates GTEx_Analysis_2017-06-05_v8_Annotations_SubjectPhenotypesDS.SEX_AGE.txt \
    --genotype_pcs GTEx_Analysis_2017-06-05_v8_WholeGenomeSeq_838Indiv_Analysis_Freeze_20genotPCs.txt
```
## Running FastQTL: nominal step
Running the cis QTL mapping nominal step with cis-window = 100kb. Genotyping information in `vcf` format is generated by the GTEx consortium.
``` bash
python3 run_FastQTL_threaded.py \
    GTEx_Analysis_2017-06-05_v8_WholeGenomeSeq_838Indiv_Analysis_Freeze_MAF005_GTonly.vcf.gz \
    ${tissue}.edMat.20cov.60samps.noXYM.qqnorm.bed.gz \
    ${tissue}.edMat.20cov.60samps.noXYM.qqnorm.nominal \
    --covariates ${tissue}.edMat.20cov.60samps.noXYM.qqnorm.combined_covariates.txt \
    --maf_threshold 0.05 \
    --ma_sample_threshold 4 \
    --threads 4 \
    --window 1e5
```
## Adaptive permutaion run
```bash
python3 run_FastQTL_threaded.py \
    GTEx_Analysis_2017-06-05_v8_WholeGenomeSeq_838Indiv_Analysis_Freeze_MAF005_GTonly.vcf.gz \
    ${tissue}.edMat.20cov.60samps.noXYM.qqnorm.bed.gz \
    ${tissue}.edMat.20cov.60samps.noXYM.qqnorm.perm \
    --covariates ${tissue}.edMat.20cov.60samps.noXYM.qqnorm.combined_covariates.txt \
    --permute 1000 10000 \
    --ma_sample_threshold 4 \
    --maf_threshold 0.05 \
    --chunks 100 \
    --threads 8 \
    --window 1e5
```
## Annotating the results and generating edSites information
Need the `GTEx_Analysis_2017-06-05_v8_WholeGenomeSeq_838Indiv_Analysis_Freeze.lookup_table.txt.gz` to provide annotation of the variants (generated by the GTEx consortium)
```bash
snp_lookup=GTEx_Analysis_2017-06-05_v8_WholeGenomeSeq_838Indiv_Analysis_Freeze.lookup_table.txt.gz
gtf_file=All.AG.stranded.annovar.Hg38_multianno.AnnoAlu.AnnoRep.NR.gtf
python3 annotate_outputs.py \
    --snp_lookup=$snp_lookup \
    --nominal_results ${tissue}.edMat.20cov.60samps.noXYM.qqnorm.nominal.txt.gz \
    -o ${tissue} \
    ${tissue}.edMat.20cov.60samps.noXYM.qqnorm.perm.txt.gz \
    0.05 \
    $gtf_file
```
Please contact Qin Li qinl@stanford.edu if there is any question.
