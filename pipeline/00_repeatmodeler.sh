#!/usr/bin/bash -l
#SBATCH --time 2-0:00:00 --ntasks 4 --nodes 1 --mem 84G --out logs/repeatmodeler_attempt.%a.NEW.log

CPU=1
if [ $SLURM_CPUS_ON_NODE ]; then
    CPU=$SLURM_CPUS_ON_NODE
fi

INDIR=genomes
OUTDIR=genomes

mkdir -p repeat_library

SAMPFILE=samples.csv
#SAMPFILE=strains_copy.csv
N=${SLURM_ARRAY_TASK_ID}

if [ ! $N ]; then
    N=$1
    if [ ! $N ]; then
        echo "need to provide a number by --array or cmdline"
        exit
    fi
fi
MAX=$(wc -l $SAMPFILE | awk '{print $1}')
if [ $N -gt $(expr $MAX) ]; then
    MAXSMALL=$(expr $MAX)
    echo "$N is too big, only $MAXSMALL lines in $SAMPFILE"
    exit
fi

IFS=,
tail -n +2 $SAMPFILE | sed -n ${N}p | while read SPECIES STRAIN PHYLUM LOCUS
do
  name=$(echo -n ${SPECIES}_${STRAIN} | perl -p -e 's/\s+/_/g')
  echo "$name"
     #module load repeatmasker/4.1.5
     #module load blast/2.13.0
     #conda activate rmblast
     #conda activate RepeatModeler
     export AUGUSTUS_CONFIG_PATH=$(realpath lib/augustus/3.3/config)
	#makeblastdb -in $INDIR/$name.sorted.fasta -dbtype nucl -out repeat_library/$name
	/nas/longleaf/home/taniak/.conda/envs/RepeatModeler/RepeatModeler-2.0.3/BuildDatabase -name repeat_library/$SPECIES $INDIR/$SPECIES.scaffolds.fasta
	/nas/longleaf/home/taniak/.conda/envs/RepeatModeler/RepeatModeler-2.0.3/RepeatModeler -database repeat_library/$SPECIES -pa $CPU
done
