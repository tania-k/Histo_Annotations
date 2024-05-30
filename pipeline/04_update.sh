#!/usr/bin/bash -l
#SBATCH -p general --time 96:00:00 --ntasks 16 --nodes 1 --mem 120G --out logs/update.%a.log

conda activate funannotate

#TRINITYHOMEPATH=$(dirname `which Trinity`)
export PASAHOMEPATH=$(dirname `which Launch_PASA_pipeline.pl`)

export AUGUSTUS_CONFIG_PATH=$(realpath lib/augustus/3.3/config)
export FUNANNOTATE_DB=/nas/longleaf/home/taniak/.conda/envs/funannotate/
export PASACONF=$HOME/pasa.config.txt
export PASAHOMEPATH=/nas/longleaf/home/taniak/.conda/envs/funannotate/opt/pasa-2.5.3
export PASAHOME=/nas/longleaf/home/taniak/.conda/envs/funannotate/opt/pasa-2.5.3


MEM=64G
CPU=$SLURM_CPUS_ON_NODE
if [ -z $CPU ]; then
	CPU=1
fi

INDIR=genomes
OUTDIR=annotate
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
if [ -z "$MAX" ]; then
    MAX=0
fi
if [ $N -gt $MAX ]; then
    echo "$N is too big, only $MAX lines in $SAMPFILE"
    exit
fi

SBT=$(realpath lib/Histoplasma.sbt) # this can be changed

IFS=,
tail -n +2 $SAMPFILE | sed -n ${N}p | while read SPECIES STRAIN PHYLUM LOCUSTAG
do
  BASE=$(echo -n "$SPECIES $STRAIN" | perl -p -e 's/\s+/_/g')
  echo "sample is $BASE"
  #  defaults to using sqlite - if you used mysql in the 02_train_RNASeq.sh step then you would add '--pasa_db mysql' to the options
  funannotate update --cpus $CPU -i $OUTDIR/$BASE --out $OUTDIR/$BASE --sbt $SBT --memory $MEM
done
