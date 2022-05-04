module purge
unset PYTHONPATH
export PYTHONNOUSERSITE=true
module load anaconda/3_5.0.1_20180125
source activate ldsc

edQTLdir=/labs/lilab/qin/GTEx/edQTL/V8_cis/FineTissue/
GTExdir=/labs/lilab/shared-data/GTEx/GenotypeFiles/2017-06-05_v8/
mescdir=/labs/lilab/qin/software/mesc
expmat=$1
expcov=$2
chr=$3
out=$4
tmpdir=$5

touch ${mescdir}/GTEx_lasso/$out.$chr.hsq ${mescdir}/GTEx_lasso/$out.$chr.lasso

genob=${mescdir}/data/plink_files/1000G.EUR.hg38
#genob=${GTExdir}/GTEx_Analysis_2017-06-05_v8_WholeGenomeSeq_838Indiv_Analysis_Freeze_MAF005_GTonly.rsID

${mescdir}/run_mesc.py --compute-expscore-indiv \
	--plink-path ~/.conda/envs/ldsc/bin/plink \
	--expression-matrix $edQTLdir/$expmat \
	--covariates  ${edQTLdir}/$expcov \
	--exp-bfile ${GTExdir}/GTEx_Analysis_2017-06-05_v8_WholeGenomeSeq_838Indiv_Analysis_Freeze_MAF005_GTonly.rsID.$chr \
	--geno-bfile $genob.$chr \
	--columns 3,1,2,4 \
	--chr $chr \
	--out ${mescdir}/GTEx_lasso/$out \
	--est-lasso-only \
	--tmp $edQTLdir/$tmpdir
