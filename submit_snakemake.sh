#!/bin/sh
#SBATCH --job-name="1s"
#SBATCH --mail-type=FAIL
#SBATCH --partition="unlimited"
#SBATCH --cpus-per-task=1
#SBATCH --mem=1g
#
#
# Make sure log directory exists or change the output file location on line 4.
#
#
#NOW=$(date +"%H%M%S_%m%d%Y")
NOW=$(date +"%Y%m%d_%H")
# module use /data/khanlab/apps/Modules
module load python/3.4.3
export NGS_PIPELINE="/data/Clinomics/Tools/ngs-pipeline"
#export WORK_DIR="/data/Clinomics/Tools/ngs-pipeline/test1"
export WORK_DIR=`pwd`
export DATA_DIR="${WORK_DIR}/fastq"
export DATA_DIR_fastq="/data/CCRBioinfo/fastq"
SNAKEFILE=$NGS_PIPELINE/ngs_pipeline.rules
SAM_CONFIG=$WORK_DIR/samplesheet.json
ACT_DIR="/Actionable/"

cd $WORK_DIR
##generate samplesheet.json
# if [ ! -f $SAM_CONFIG ];then
#     module load R
#     $NGS_PIPELINE/scripts/do_samplesheet2json.R -s /data/CCRBioinfo/zhujack/projects/TargetOsteosarcomaRNA/samplesheet_test.txt
# fi

if [ `cat $SAM_CONFIG |/usr/bin/json_verify -c` -ne "JSON is valid" ]; then
    echo "$SAM_CONFIG is not a valid json file"
    exit
fi

## log folder is required
if [ ! -d log ];then
    mkdir log
fi

if [ ! -d annovar ]; then 
	mkdir annovar
	touch annovar/AnnotationInput.final.txt
fi

snakemake\
    --directory $WORK_DIR \
    --snakefile $SNAKEFILE \
    --configfile $SAM_CONFIG \
    --jobname '1s{jobid}.{params.rulename}' \
    --rerun-incomplete \
    --nolock \
    -k -p -T \
    -j 3000 \
    --stats ngs_pipeline_${NOW}.stats \
    --cluster "sbatch --mail-type=FAIL -o log/{params.rulename}.%j.o -e log/{params.rulename}.%j.e {params.batch}"\
    >& ngs_pipeline_${NOW}.log

# Summary 
#  snakemake --directory $WORK_DIR --snakefile $SNAKEFILE --configfile $SAM_CONFIG --summary

## DRY Run with Print out the shell commands that will be executed
#  snakemake --directory $WORK_DIR --snakefile $SNAKEFILE --configfile $SAM_CONFIG --npr

#DAG 
#  snakemake --directory $WORK_DIR --snakefile $SNAKEFILE --configfile $SAM_CONFIG --dag | dot -Tpng > dag.png

#Rulegraph
#  snakemake --directory $WORK_DIR --snakefile $SNAKEFILE --configfile $SAM_CONFIG -n --forceall --rulegraph | dot -Tpng > rulegraph.png

# Mail Rulegraph and DAG to self
#  echo DAG |mutt -s "DAG" -a dag.png -a rulegraph.png -- patidarr@mail.nih.gov
