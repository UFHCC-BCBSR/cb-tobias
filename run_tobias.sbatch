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
PIPELINE_DIR='/blue/cancercenter-dept/PIPELINES/TOBIAS_SNAKEMAKE/TOBIAS_snakemake/'   # *** UPDATE ***
ENV_DIR='/blue/cancercenter-dept/conda_envs'                                           # *** UPDATE ***
CONFIG_LIST='config-names.txt'

# Shared/reusable Snakemake Conda env cache (hash-named envs live here)
SNAKE_CONDA_PREFIX='/blue/cancercenter-dept/conda_envs'                                # *** UPDATE (keep persistent) ***
mkdir -p "$SNAKE_CONDA_PREFIX" logs

#=============================================================================
# EXECUTION (Do not modify below this line unless you know what you're doing)
#=============================================================================

set -euo pipefail
cd "$SLURM_SUBMIT_DIR"

ml conda
conda activate "${ENV_DIR}/tobias_snakemake_env"

# Get config name for this array task
CONFIG_NAME="$(sed -n "${SLURM_ARRAY_TASK_ID}p" "$CONFIG_LIST")"

if [[ -z "${CONFIG_NAME:-}" ]]; then
    echo "ERROR: Could not read config name for array task ${SLURM_ARRAY_TASK_ID}"
    exit 1
fi

CONFIG_FILE="${CONFIG_NAME}-config.yaml"
if [[ ! -f "$CONFIG_FILE" ]]; then
    echo "ERROR: Config file not found: ${CONFIG_FILE}"
    exit 1
fi

if [[ ! -f "${PIPELINE_DIR}/Snakefile" ]]; then
    echo "ERROR: Snakefile not found in ${PIPELINE_DIR}"
    exit 1
fi

CORES="${SLURM_CPUS_PER_TASK:-8}"

echo "Processing:      ${CONFIG_NAME}"
echo "Config file:     ${CONFIG_FILE}"
echo "Pipeline dir:    ${PIPELINE_DIR}"
echo "Conda env cache: ${SNAKE_CONDA_PREFIX}"
echo "Cores:           ${CORES}"

# Run pipeline
snakemake \
    -s "${PIPELINE_DIR}/Snakefile" \
    --configfile "${CONFIG_FILE}" \
    --use-conda \
    --conda-prefix "${SNAKE_CONDA_PREFIX}" \
    --cores "${CORES}" \
    --printshellcmds

if [[ $? -eq 0 ]]; then
    echo "SUCCESS: ${CONFIG_NAME}"
else
    echo "ERROR: ${CONFIG_NAME}"
    exit 1
fi
