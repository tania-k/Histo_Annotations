#!/usr/bin/bash -l

#SBATCH --nodes=1
#SBATCH --ntasks=16
#SBATCH --mem 500gb -p intel
#SBATCH --time=3-00:15:00
#SBATCH --output=logs/train.%a.log
#SBATCH --job-name="TrainFun"

# Define program name
# Load software
conda activate funannotate
MEM=128G

export AUGUSTUS_CONFIG_PATH=$(realpath lib/augustus/3.3/config)
# Set some vars
export FUNANNOTATE_DB=/nas/longleaf/home/taniak/.conda/envs/funannotate/
#export PASACONF=$HOME/pasa.config.txt
#export PASAHOMEPATH=$(dirname `which Launch_PASA_pipeline.pl`)
#export PASAHOME=$HOME/.pasa
export TRINITY=$(realpath `which Trinity`)
export TRINITYHOMEPATH=$(dirname $TRINITY)

# Determine CPUS
if [[ -z ${SLURM_CPUS_ON_NODE} ]]; then
    CPUS=1
else
    CPUS=${SLURM_CPUS_ON_NODE}
fi


N=${SLURM_ARRAY_TASK_ID}

if [ -z $N ]; then
    N=$1
    if [ -z $N ]; then
        echo "need to provide a number by --array or cmdline"
        exit
    fi
fi
ODIR=annotate
INDIR=genomes
RNAFOLDER=lib/RNA
SAMPLEFILE=samples.csv
IFS=,
tail -n +2 $SAMPLEFILE | sed -n ${N}p | while read SPECIES STRAIN PHYLUM LOCUSTAG
do
    RNASEQ=$RNAFOLDER/Histoplasma_capsulatum_G186AR.rna.fna

    echo "SPECIES is $SPECIES"
    SPECIESNOSPACE=$(echo -n "$SPECIES" | perl -p -e 's/\s+/_/g')
    if [[ ! -f $RNAFOLDER/Forward.fq.gz ]]; then
	     echo "For training step Need RNASeq files in folder  $RNAFOLDER/ as  $RNAFOLDER/Forward.fq.gz and  $RNASEQ/Reverse.fq.gz"
	     exit
    fi
    BASE=$(echo -n "$SPECIES $STRAIN" | perl -p -e 's/\s+/_/g')
    echo "sample is $BASE"
    MASKED=$(realpath $INDIR/$BASE.masked.fasta)
    if [ ! -f $MASKED ]; then
	     echo "Cannot find $BASE.masked.fasta in $INDIR - may not have been run yet"
       exit
    fi

    echo $ODIR/$BASE/training
    funannotate train -i $MASKED -o $ODIR/$BASE \
   	--jaccard_clip --species "$SPECIES" --isolate $STRAIN \
  	--cpus $CPUS --memory $MEM \
  	--left $RNAFOLDER/Forward.fq.gz --right $RNAFOLDER/Reverse.fq.gz
    # add --pasa_db mysql to the options above if you have installed mysql and configured it in your ~/pasa.config.txt file
done
