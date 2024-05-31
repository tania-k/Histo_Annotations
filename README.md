# Histoplasma Annotation Pipeline

## Repository for scripts used to annotate Histoplasma isolates using Funannotate fungal genome annotation pipeline.

How to run Funannotate on UNC longleaf cluster.
This program requires a ton of dependencies. Follow https://funannotate.readthedocs.io/en/latest/ for all the information.

If you are running on the UNC longleaf cluster follow below steps to setup your environment so you too can annotate fungal genomes.

1. Clone this repository to your directory you'll be working in. Create a `logs/`, `genomes/`, and `lib/` folder. Genomes contains all of your assembled genomes ready to be annotated.
2. The pipeline folder contains the different steps you'll be following for your analysis.

```
* 000_start_mysql.sh (Use this script only if you have mysql set up. I couldn't figure it out for myself - you can skip this as it allows your analysis to be run faster.)
* 00_repeatmodeler.sh 
* 01_mask_denovo.sh
* 02_train_RNA.sh
* 03_predict.sh
* 04_update.sh
* 05a_antismash_local.sh
* 05b_iprscan.sh
* 06_annotate_function.sh
```

3. Prepare a samples.csv file. My scripts have been set up to run iteratively when submitting an array.
i.e. Your samples.csv has 20 lines of code, you would be submitting your analysis as ` sbatch -p general --array=1-20 pipeline/03_predict.sh `
I have added my samples.csv file for you to follow. Make sure the first line, BASE,SPECIES,STRAIN,BUSCO,LOCUS is also added to your samples.csv file.
To add augustus to your lib folder run `cp -r /nas/longleaf/home/taniak/taniak/Annotation/lib ` this should copy the contents there.

4. Add this in the conda portion of the scripts to the full path to my funannotate conda environment `conda activate /nas/longleaf/home/taniak/taniak/.conda/funannotate`
5. If you have RNA-seq data you can run the training step (though this is optional) it will provide you with better accurate gene prediction sites for the prediction step (step 3).
6. To add RNA to your analysis, add a RNAseq folder in your lib folder. Add `sra_download.pl` to your RNA folder along with a text file with only your SRR info with a hard enter between each. To run do `perl sra_download.pl SRA.txt` and it should download the files in the proper format.
7. Steps 05a and 05b are necessary for your protein prediction as they provide with two different kinds of data.
8. Final 06 step will provide you with your files including annotated gff3 files, along with an annotations.txt file which places your results in a table format along with amino acid genome and DNA genome files. A final sqn file is also generated with your table + gff3 file which can be submitted to NCBI.

