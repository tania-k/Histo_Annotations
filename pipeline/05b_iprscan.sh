#!/bin/bash -l
#SBATCH --ntasks 64 --nodes 1 --mem 96G --time 12:00:00 --out logs/iprscan.%a.log
conda activate funannotate
#conda activate funannotate_3.9
module load interproscan/5.63-95.0
module unload python/3.9.6
unset python
CPU=1

if [ ! -z $SLURM_CPUS_ON_NODE ]; then
  CPU=$SLURM_CPUS_ON_NODE
fi
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

if [ $N -gt $MAX ]; then
  echo "$N is too big, only $MAX lines in $SAMPFILE"
  exit
fi
IFS=,
tail -n +2 $SAMPFILE | sed -n ${N}p | while read SPECIES STRAIN PHYLUM LOCUSTAG
do
  BASE=$(echo -n "$SPECIES $STRAIN" | perl -p -e 's/\s+/_/g')
  name=$BASE
  echo "$BASE"
  if [ ! -d $OUTDIR/$name ]; then
    echo "No annotation dir for ${name}"
    exit
  fi
  mkdir -p $OUTDIR/$name/annotate_misc
  XML=$OUTDIR/$name/annotate_misc/iprscan.xml
  IPRPATH=$(which interproscan.sh)
  if [ ! -f $XML ]; then
    echo "running on $OUTDIR/$name"
    funannotate iprscan -i $OUTDIR/$name -o $XML -m local -c $CPU --iprscan_path $IPRPATH
  fi
done
