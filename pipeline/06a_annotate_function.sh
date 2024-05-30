#!/usr/bin/bash -l
#SBATCH --nodes=1
#SBATCH --ntasks=16 --mem 48gb
#SBATCH --output=logs/annotfunc.13_NEW.log
#SBATCH --time=2-0:00:00
#SBATCH -J annotfunc

conda activate funannotate
module unload python/3.9.6
unset python

export AUGUSTUS_CONFIG_PATH=$(realpath lib/augustus/3.3/config)
# Set some vars
export FUNANNOTATE_DB=/nas/longleaf/home/taniak/.conda/envs/funannotate/
export TRINITY=$(realpath `which Trinity`)
export TRINITYHOMEPATH=$(dirname $TRINITY)
export BUSCO_CONFIG_FILE="/nas/longleaf/home/taniak/Histoplasma_Assembly/busco_files/myconfig.ini"
export EGGNOG_DB=/nas/longleaf/home/taniak/.conda/envs/funannotate/lib/python3.8/site-packages/data/

CPUS=$SLURM_CPUS_ON_NODE
OUTDIR=annotate
INDIR=genomes
SAMPFILE=samples.csv
BUSCO=eurotiomycetes
#CONFIG=busco_files/myconfig.ini


if [ -z $CPUS ]; then
  CPUS=1
fi

TEMPLATE=$(realpath lib/Histoplasma.sbt)
if [ ! -f $TEMPLATE ]; then
  echo "NO TEMPLATE for $name"
  exit
fi
funannotate annotate --sbt $TEMPLATE --busco_db $BUSCO -i annotate/Histoplasma_capsulatum_602-TD --species "capsulatum" --strain "602-TD" --cpus $CPUS $MOREFEATURE $EXTRAANNOT --rename 602-TD --force

