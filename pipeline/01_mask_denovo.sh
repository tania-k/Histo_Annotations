#!/usr/bin/bash -l
#SBATCH --ntasks 96 -N 1 --mem 96gb --out logs/mask.%a.log

CPU=1
if [ $SLURM_CPUS_ON_NODE ]; then
    CPU=$SLURM_CPUS_ON_NODE
fi

INDIR=genomes
OUTDIR=genomes

SAMPFILE=samples.csv
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
  if [ ! -f $INDIR/${name}.sorted.fasta ]; then
     echo "Cannot find $name in $INDIR - may not have been run yet"
     exit
  fi
  echo "$name"

  if [ ! -f $OUTDIR/${name}.masked.fasta ]; then
     conda activate funannotate
     #module load repeatmasker
     export AUGUSTUS_CONFIG_PATH=$(realpath lib/augustus/3.3/config)
     if [ -f repeat_library/${name}-families.fa ]; then
    	  LIBRARY=$(realpath repeat_library/${name}-families.fa)
     fi
     echo "LIBRARY is $LIBRARY"
     which rmblastn
     funannotate mask --cpus $CPU -i $INDIR/${name}.sorted.fasta -o $OUTDIR/${name}.masked.fasta --method repeatmasker -l $LIBRARY
     # this 
     mv funannotate-mask.log logs/masklog_long.$name.log
  else
     echo "Skipping ${name} as masked already"
  fi
done
