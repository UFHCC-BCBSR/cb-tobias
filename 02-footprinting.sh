#!/bin/bash
#SBATCH --job-name=tobias_%x
#SBATCH --mail-type=END,FAIL
#SBATCH --mail-user=hkates@ufl.edu
#SBATCH --ntasks=1
#SBATCH --cpus-per-task=16
#SBATCH --mem=64gb
#SBATCH --time=24:00:00
#SBATCH --error=logs/tobias_%x_%j.error
#SBATCH --output=logs/tobias_%x_%j.log
#SBATCH --account=cancercenter-dept
#SBATCH --qos=cancercenter-dept-b

################################
# ONLY EDIT THIS SECTION
################################
SAMPLE="Mav10_REP1"  # ← Change this for each sample

# Filter motifs (leave empty for all 879 motifs)
FILTER_TFS="RELA,TP53,CTCF,SPI1,STAT3"  # Comma-separated TF names, or leave as "" for all

################################

# Load modules and activate environment
module load conda
conda activate /blue/cancercenter-dept/hkates/conda_envs/tobias

# Base paths
NFCORE_BASE="/blue/licht/runs/NSD2-E1099K-Project/NS4370/OUTPUT"
BAM_DIR="${NFCORE_BASE}/bowtie2/merged_library"
PEAK_DIR="${NFCORE_BASE}/bowtie2/merged_library/macs2/broad_peak"
GENOME="${NFCORE_BASE}/genome/Homo_sapiens.GRCh38.dna.primary_assembly.fa"
MOTIF_DIR="/blue/cancercenter-dept/PIPELINES/TOBIAS_SNAKEMAKE/TOBIAS_snakemake/jaspar"

# Auto-construct file paths
BAM_FILE="${BAM_DIR}/${SAMPLE}.mLb.clN.sorted.bam"
PEAKS="${PEAK_DIR}/${SAMPLE}.mLb.clN_peaks.broadPeak"
OUTDIR="./tobias_output/${SAMPLE}"
mkdir -p ${OUTDIR} logs

# Handle motif filtering
if [[ -n "$FILTER_TFS" ]]; then
    echo "=== Filtering motifs for TFs: ${FILTER_TFS} ==="
    MOTIF_WORK="${OUTDIR}/filtered_motifs"
    mkdir -p ${MOTIF_WORK}
    
    # Copy and combine filtered motifs
    > ${MOTIF_WORK}/filtered.jaspar  # Empty the file
    
    IFS=',' read -ra TF_ARRAY <<< "$FILTER_TFS"
    for TF in "${TF_ARRAY[@]}"; do
        TF=$(echo $TF | xargs)  # Trim whitespace
        echo "Looking for motif: ${TF}"
        # Find motif files containing this TF name
        grep -l ">${TF}" ${MOTIF_DIR}/*.jaspar | while read motif_file; do
            echo "  Found: $(basename $motif_file)"
            cat "$motif_file" >> ${MOTIF_WORK}/filtered.jaspar
        done
    done
    
    MOTIFS="${MOTIF_WORK}/filtered.jaspar"
    echo "Using $(grep -c "^>" ${MOTIFS}) filtered motifs"
else
    echo "=== Using all 879 motifs ==="
    MOTIFS="${MOTIF_DIR}"
fi

# Verify files exist
echo "Checking input files..."
if [[ ! -f ${BAM_FILE} ]]; then echo "ERROR: BAM file not found: ${BAM_FILE}"; exit 1; fi
if [[ ! -f ${PEAKS} ]]; then echo "ERROR: Peak file not found: ${PEAKS}"; exit 1; fi
if [[ ! -f ${GENOME} ]]; then echo "ERROR: Genome file not found: ${GENOME}"; exit 1; fi
echo "All input files found!"

# Step 1: ATACorrect
echo "=== Starting ATACorrect for ${SAMPLE} ==="
TOBIAS ATACorrect \
    --bam ${BAM_FILE} \
    --genome ${GENOME} \
    --peaks ${PEAKS} \
    --outdir ${OUTDIR}/corrected \
    --prefix ${SAMPLE} \
    --cores ${SLURM_CPUS_PER_TASK}

# Step 2: ScoreBigwig
echo "=== Starting ScoreBigwig for ${SAMPLE} ==="
TOBIAS ScoreBigwig \
    --signal ${OUTDIR}/corrected/${SAMPLE}_corrected.bw \
    --regions ${PEAKS} \
    --output ${OUTDIR}/${SAMPLE}_footprints.bw \
    --cores ${SLURM_CPUS_PER_TASK}

# Step 3: BINDetect
echo "=== Starting BINDetect for ${SAMPLE} ==="
TOBIAS BINDetect \
    --motifs ${MOTIFS} \
    --signals ${OUTDIR}/${SAMPLE}_footprints.bw \
    --genome ${GENOME} \
    --peaks ${PEAKS} \
    --outdir ${OUTDIR}/bindetect \
    --cores ${SLURM_CPUS_PER_TASK}

echo "=== TOBIAS analysis complete for ${SAMPLE}! ==="
