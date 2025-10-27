#!/bin/bash
#=============================================================================
# SLURM Job Script for TOBIAS Analysis
#=============================================================================
# This script runs TOBIAS analysis using job arrays for parallel processing
# Each array task processes one sample from samples.txt
#
# BEFORE SUBMITTING:
# 1. Update --mail-user with your UFL email
# 2. Update --account with your HiPerGator account
# 3. Update --qos with your QOS allocation
# 4. Update --array=1-N where N = number of lines in samples.txt
# 5. Update PIPELINE_DIR with path to TOBIAS_snakemake installation
# 6. Ensure LOGS/ directory exists: mkdir -p LOGS

#-----------------------------------------------------------------------------
# SLURM Job Parameters
#-----------------------------------------------------------------------------

#SBATCH --job-name=tobias_analysis
#SBATCH -o LOGS/tobias.%A_%a.out              # Output log: JOBID_TASKID.out
#SBATCH -e LOGS/tobias.%A_%a.err              # Error log: JOBID_TASKID.err
#SBATCH --mail-type=ALL                       # Email on job start, end, fail
#SBATCH --mail-user=YOUR_EMAIL@ufl.edu        # *** UPDATE THIS ***

#-----------------------------------------------------------------------------
# Resource Allocation
#-----------------------------------------------------------------------------

#SBATCH --ntasks=1                            # One task per array job
#SBATCH --cpus-per-task=8                     # CPUs per task (match --cores below)
#SBATCH --mem=24Gb                            # Memory per task (increase if OOM errors)
#SBATCH --time=48:00:00                       # Max runtime: 48 hours (HH:MM:SS)

#-----------------------------------------------------------------------------
# Account and QOS
#-----------------------------------------------------------------------------

#SBATCH --account=YOUR_ACCOUNT                # *** UPDATE THIS *** (e.g., cancercenter-dept)
#SBATCH --qos=YOUR_QOS                        # *** UPDATE THIS *** (e.g., cancercenter-dept-b)

#-----------------------------------------------------------------------------
# Job Array Configuration
#-----------------------------------------------------------------------------
# Creates N parallel jobs, one for each line in samples.txt
# IMPORTANT: Update --array=1-N where N = number of samples
# Example: If samples.txt has 3 lines, use --array=1-3

#SBATCH --array=1-2                           # *** UPDATE THIS *** (match line count in samples.txt)

#=============================================================================
# Script Execution
#=============================================================================

# Change to submission directory
cd $SLURM_SUBMIT_DIR

# Load conda module
ml conda

# Activate TOBIAS conda environment
# Environment must be created first (see README.md)
conda activate tobias_snakemake_env

#-----------------------------------------------------------------------------
# Path Configuration
#-----------------------------------------------------------------------------

# Path to centrally installed TOBIAS_snakemake pipeline
# *** UPDATE THIS *** with your pipeline installation location
# Example: /blue/cancercenter-dept/pipelines/TOBIAS_snakemake
PIPELINE_DIR='/blue/YOUR_GROUP/pipelines/TOBIAS_snakemake'

# Path to samples file in current directory
DESIGN_FILE='config-names.txt'

#-----------------------------------------------------------------------------
# Read Sample Name for This Array Task
#-----------------------------------------------------------------------------

# Extract the line number corresponding to this array task ID
# Array task 1 reads line 1, task 2 reads line 2, etc.
SAMPLE_NAME=$(sed -n "${SLURM_ARRAY_TASK_ID}p" $DESIGN_FILE)

# Check if sample name was successfully read
if [ -z "$SAMPLE_NAME" ]; then
    echo "ERROR: Could not read sample name for array task ${SLURM_ARRAY_TASK_ID}"
    echo "Check that samples.txt has at least ${SLURM_ARRAY_TASK_ID} lines"
    exit 1
fi

echo "=================================================="
echo "Processing sample: ${SAMPLE_NAME}"
echo "Array Task ID: ${SLURM_ARRAY_TASK_ID}"
echo "Config file: config_${SAMPLE_NAME}_config.yaml"
echo "Pipeline directory: ${PIPELINE_DIR}"
echo "=================================================="

#-----------------------------------------------------------------------------
# Run Snakemake Pipeline
#-----------------------------------------------------------------------------

# Run TOBIAS pipeline for this sample
# --use-conda: Use conda environments defined in pipeline
# --cores: Number of cores to use (should match --cpus-per-task)
snakemake \
    -s ${PIPELINE_DIR}/Snakefile \
    --configfile ${SAMPLE_NAME}-config.yaml \
    --use-conda \
    --cores 8

# Check exit status
if [ $? -eq 0 ]; then
    echo "SUCCESS: Analysis completed for ${SAMPLE_NAME}"
else
    echo "ERROR: Analysis failed for ${SAMPLE_NAME}"
    exit 1
fi

#=============================================================================
# Notes:
#=============================================================================
# - Each array task is independent and can fail without affecting others
# - Monitor jobs with: squeue -u $USER
# - Check logs in: LOGS/tobias.JOBID_TASKID.out
# - Cancel all array jobs: scancel JOBID
# - Cancel specific task: scancel JOBID_TASKID
#
# Common Issues:
# - Config not found: Ensure config_SAMPLENAME_config.yaml exists
# - OOM errors: Increase --mem (e.g., --mem=48Gb)
# - Timeout: Increase --time
# - Wrong array size: Match --array to line count in samples.txt
#=============================================================================
