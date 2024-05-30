#!/usr/bin/bash -l
#SBATCH --time 48:00:00 --ntasks 16 --nodes 1 --mem 250G --out logs/predict.%a.log

conda activate funannotate
ml augustus
# this will define $SCRATCH variable if you don't have this on your system you can basically do this depending on
# where you have temp storage space and fast disks
# SCRATCH=/tmp/${USER}_$$
# mkdir -p $SCRATCH

CPU=1
if [ $SLURM_CPUS_ON_NODE ]; then
    CPU=$SLURM_CPUS_ON_NODE
fi

BUSCO=eurotiomycetes # This could be changed to the core BUSCO set you want to use
INDIR=genomes
OUTDIR=annotate
PREDS=$(realpath prediction_support)
mkdir -p $OUTDIR
SAMPFILE=samples.csv
N=${SLURM_ARRAY_TASK_ID}

if [ ! $N ]; then
    N=$1
    if [ ! $N ]; then
        echo "need to provide a number by --array or cmdline"
        exit
    fi
fi
MAX=`wc -l $SAMPFILE | awk '{print $1}'`

if [ $N -gt $MAX ]; then
    echo "$N is too big, only $MAX lines in $SAMPFILE"
    exit
fi

export AUGUSTUS_CONFIG_PATH=$(realpath lib/augustus/3.3/config)
export FUNANNOTATE_DB=/nas/longleaf/home/taniak/.conda/envs/funannotate/
export GENEMARK_PATH=/nas/longleaf/home/taniak/.conda/envs/gmes_linux_64_4/

SEED_SPECIES=histoplasma

IFS=,
tail -n +2 $SAMPFILE | sed -n ${N}p | while read SPECIES STRAIN PHYLUM LOCUSTAG
do
    SEQCENTER=UNC
    BASE=$(echo -n "$SPECIES $STRAIN" | perl -p -e 's/\s+/_/g')
    echo "sample is $BASE"
    MASKED=$(realpath $INDIR/$BASE.masked.fasta)
    if [ ! -f $MASKED ]; then
      echo "Cannot find $BASE.masked.fasta in $INDIR - may not have been run yet"
      exit
    fi
    if [[ -f $PREDS/$BASE.genemark.gtf ]]; then
    funannotate predict --cpus $CPU --keep_no_stops --SeqCenter $SEQCENTER --busco_db $BUSCO --optimize_augustus \
        --strain $STRAIN --min_training_models 100 --AUGUSTUS_CONFIG_PATH $AUGUSTUS_CONFIG_PATH \
        -i $INDIR/$BASE.masked.fasta --name $LOCUSTAG --protein_evidence $FUNANNOTATE_DB/uniprot_sprot.fasta \
        -s "$SPECIES"  -o $OUTDIR/$BASE --busco_seed_species $SEED_SPECIES --genemark_gtf $PREDS/$BASE.genemark.gtf --force
    else
    funannotate predict --cpus $CPU --keep_no_stops --SeqCenter $SEQCENTER --busco_db $BUSCO --optimize_augustus \
	--strain $STRAIN --min_training_models 100 --AUGUSTUS_CONFIG_PATH $AUGUSTUS_CONFIG_PATH \
	-i $INDIR/$BASE.masked.fasta --name $LOCUSTAG --protein_evidence $FUNANNOTATE_DB/uniprot_sprot.fasta \
	-s "$SPECIES"  -o $OUTDIR/$BASE --busco_seed_species $SEED_SPECIES --force
    fi
done
