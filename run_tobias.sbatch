#!/bin/bash
#=============================================================================
# SLURM Job Script for TOBIAS Analysis
#=============================================================================
# See README.md for full documentation

#-----------------------------------------------------------------------------
# SLURM PARAMETERS - UPDATE THESE BEFORE SUBMITTING
#-----------------------------------------------------------------------------
#SBATCH --job-name=tobias_analysis
#SBATCH --mail-user=YOUR_EMAIL@ufl.edu                    # *** UPDATE ***
#SBATCH --account=YOUR_ACCOUNT                            # *** UPDATE ***
#SBATCH --qos=YOUR_QOS                                    # *** UPDATE ***
#SBATCH --array=1-2                                       # *** UPDATE *** (match lines in config-names.txt)
#SBATCH -o logs/tobias.%A_%a.out
#SBATCH -e logs/tobias.%A_%a.err
#SBATCH --mail-type=ALL
#SBATCH --ntasks=1
#SBATCH --cpus-per-task=8
#SBATCH --mem=24Gb
#SBATCH --time=48:00:00

#-----------------------------------------------------------------------------
# PATHS - UPDATE THESE FOR YOUR SETUP
#-----------------------------------------------------------------------------
PIPELINE_DIR='/blue/YOUR_GROUP/pipelines/TOBIAS_snakemake'           # *** UPDATE ***
ENV_DIR='/blue/YOUR_GROUP/YOUR_USERNAME/conda_envs'                  # *** UPDATE ***
CONFIG_LIST='config-names.txt'

#=============================================================================
# EXECUTION (Do not modify below this line unless you know what you're doing)
#=============================================================================

cd $SLURM_SUBMIT_DIR
ml conda
conda activate ${ENV_DIR}/tobias_snakemake_env

# Get config name for this array task
CONFIG_NAME=$(sed -n "${SLURM_ARRAY_TASK_ID}p" $CONFIG_LIST)

if [ -z "$CONFIG_NAME" ]; then
    echo "ERROR: Could not read config name for array task ${SLURM_ARRAY_TASK_ID}"
    exit 1
fi

echo "Processing: ${CONFIG_NAME}"
echo "Config file: ${CONFIG_NAME}-config.yaml"

# Run pipeline
snakemake \
    -s ${PIPELINE_DIR}/Snakefile \
    --configfile ${CONFIG_NAME}-config.yaml \
    --use-conda \
    --cores 8

if [ $? -eq 0 ]; then
    echo "SUCCESS: ${CONFIG_NAME}"
else
    echo "ERROR: ${CONFIG_NAME}"
    exit 1
fi