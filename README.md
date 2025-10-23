# TOBIAS Footprinting Analysis on HiPerGator

## Overview

This script performs **transcription factor (TF) footprinting analysis** on ATAC-seq data using TOBIAS. Footprinting identifies which transcription factors are actively bound to DNA by detecting protected regions where the Tn5 transposase couldn't cut due to protein binding.

## What the Script Does

The analysis has three main steps:

### Step 1: ATACorrect
- **What:** Corrects for Tn5 transposase sequence bias
- **Why:** The Tn5 enzyme prefers cutting certain DNA sequences over others, creating false signals
- **Input:** Raw BAM file from nf-core/atacseq
- **Output:** Bias-corrected bigWig files

### Step 2: ScoreBigwig
- **What:** Calculates footprint scores across the genome
- **Why:** Identifies regions where protein binding "protects" DNA from Tn5 cutting
- **Input:** Corrected bigWig from Step 1
- **Output:** Footprint score bigWig file

### Step 3: BINDetect
- **What:** Scans for known TF motifs and predicts which are actually bound
- **Why:** Not all motif sequences are bound - this identifies active binding sites
- **Input:** Footprint scores + TF motif database
- **Output:** List of bound TFs with statistics and binding site locations

---

## How to Use This Script

### Required: Edit These Variables

Open the script and modify lines 18-21:

```bash
################################
# ONLY EDIT THIS SECTION
################################
SAMPLE="Mav10_REP1"  # ← Your sample name (must match nf-core output)

# Filter motifs (leave empty for all 879 motifs)
FILTER_TFS="RELA,TP53,CTCF,SPI1,STAT3"  # Comma-separated TF names, or "" for all
################################
```

### Parameter 1: SAMPLE

**What to put:** The exact sample name from your nf-core/atacseq output.

**Where to find it:** Look in `/blue/licht/runs/NSD2-E1099K-Project/NS4370/OUTPUT/bowtie2/merged_library/`

Examples:
- `Mav10_REP1`
- `Mino165_REP2`
- `Mav22_REP3`

**Why it matters:** The script auto-constructs file paths from this name:
- BAM: `${SAMPLE}.mLb.clN.sorted.bam`
- Peaks: `${SAMPLE}.mLb.clN_peaks.broadPeak`

### Parameter 2: FILTER_TFS

**Purpose:** Control which transcription factors to analyze.

#### Option A: Test with specific TFs (faster, recommended for first run)
```bash
FILTER_TFS="RELA,TP53,CTCF,SPI1,STAT3"
```
- **Runtime:** ~15-30 minutes for BINDetect
- **Use when:** Testing, or you know which TFs you care about
- **How to choose TFs:** Based on your biological question

Common TFs by function:
- **Inflammation:** RELA (NF-κB), STAT3, STAT1
- **Cell cycle:** TP53, MYC, E2F1
- **Chromatin structure:** CTCF
- **Hematopoiesis:** SPI1 (PU.1), GATA1, RUNX1

#### Option B: Analyze all 879 TFs (comprehensive)
```bash
FILTER_TFS=""
```
- **Runtime:** ~1-2 hours for BINDetect
- **Use when:** Exploratory analysis, you want to see everything
- **Output:** Complete landscape of TF binding

---

## Running the Script

### Step 1: Make sure you have logs directory
```bash
mkdir -p logs
```

### Step 2: Submit the job
```bash
sbatch 02-footprinting.sh
```

### Step 3: Monitor progress
```bash
# Check job status
squeue -u $USER

# Watch log file (replace JOBID with actual number)
tail -f logs/tobias_Mav10_REP1_JOBID.log
```

---

## Output Files

Results are organized in `./tobias_output/${SAMPLE}/`:

```
tobias_output/
└── Mav10_REP1/
    ├── corrected/
    │   ├── Mav10_REP1_corrected.bw      # Bias-corrected signal
    │   ├── Mav10_REP1_uncorrected.bw    # Original signal
    │   ├── Mav10_REP1_bias.bw           # Estimated bias
    │   └── Mav10_REP1_atacorrect.pdf    # QC plots
    ├── Mav10_REP1_footprints.bw         # Footprint scores
    └── bindetect/
        ├── bindetect_results.txt        # ← Main results table
        ├── *_overview.txt               # Per-TF summaries
        └── beds/                        # Binding site coordinates
```

### Key Output: `bindetect_results.txt`

Columns include:
- **name:** Transcription factor name
- **total_tfbs:** Total predicted binding sites
- **percent_bound:** % of sites showing footprint signal
- **pvalue:** Statistical significance of binding

---

## Resource Requirements

Current settings (should work for most samples):
- **CPUs:** 16 cores
- **Memory:** 64 GB
- **Time:** 24 hours

### When to adjust:

**Increase memory** (to 128GB) if you see "out of memory" errors:
```bash
#SBATCH --mem=128gb
```

**Increase time** if analyzing all 879 TFs with many samples:
```bash
#SBATCH --time=48:00:00
```

---

## Troubleshooting

### Error: "BAM file not found"
- Check that `SAMPLE` name exactly matches file in merged_library directory
- Common issue: Extra spaces, typos, or wrong replicate number

### Error: "Peak file not found"
- Verify nf-core/atacseq completed successfully
- Check `macs2/broad_peak/` directory for peak files

### BINDetect takes too long
- Use `FILTER_TFS` to limit to specific TFs of interest
- Check that you're using 16 cores (`--cpus-per-task=16`)

### No TFs found in filtering
- TF names are case-sensitive
- Check available motif files: `ls /blue/cancercenter-dept/PIPELINES/TOBIAS_SNAKEMAKE/TOBIAS_snakemake/jaspar/`
- Try searching: `grep -l "STAT" /blue/cancercenter-dept/PIPELINES/TOBIAS_SNAKEMAKE/TOBIAS_snakemake/jaspar/*.jaspar`

---

## Processing Multiple Samples

To analyze multiple samples, you have two options:

### Option 1: Submit separate jobs (simple)
```bash
# Edit SAMPLE in script each time, then:
sbatch 02-footprinting.sh  # Sample 1
sbatch 02-footprinting.sh  # Sample 2
sbatch 02-footprinting.sh  # Sample 3
```

### Option 2: Array job (efficient)
Coming soon - processes all samples in parallel.

---

## Questions?

- **TOBIAS documentation:** https://github.com/loosolab/TOBIAS
- **Contact:** hkates@ufl.edu

## Citation

If you use this analysis, please cite:

> Bentsen, M., Goymann, P., Schultheis, H. et al. ATAC-seq footprinting unravels kinetics of transcription factor binding during zygotic genome activation. Nat Commun 11, 4267 (2020). https://doi.org/10.1038/s41467-020-18035-1
