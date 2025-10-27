# cb-tobias: TOBIAS Analysis Pipeline Template for HiPerGator

## Overview
This repository provides a ready-to-use template for running TOBIAS (Transcription Factor Binding Analysis) on UF HiPerGator using SLURM job arrays. Clone this repo for each new project and point to a centrally installed TOBIAS pipeline.

## One-Time Pipeline Setup (Do Once Per Group)

```bash
# Install tobias snakemake pipeline from Github to shared location
cd /blue/YOUR_GROUP/pipelines/
git clone https://github.com/loosolab/TOBIAS_snakemake.git

# Create conda environment in /blue (not home directory which fills up fast)
ml conda
cd TOBIAS_snakemake
conda env create -f environments/tobias_snakemake.yaml 
    --prefix /blue/YOUR_GROUP/YOUR_USERNAME/conda_envs/tobias_snakemake_env
```

## Usage: Running an Analysis

### 1. Clone This Template

```bash
cd /blue/YOUR_GROUP/YOUR_USERNAME/
git clone https://github.com/UFHCC-BCBSR/cb-tobias.git my_tobias_analysis_2025
cd my_tobias_analysis_2025
mkdir -p logs
```

### 2. Create Configuration Files

**Rename and edit the example configs for your comparisons:**

```bash
# Rename examples (create as many as needed)
mv contrast1-config.yaml treatment_vs_control-config.yaml
mv contrast2-config.yaml timepoint1_vs_timepoint2-config.yaml

# Edit with your BAM files and reference paths
nano treatment_vs_control-config.yaml
```

**Key fields to update in each config:**
- `data:` - Your BAM file paths
- `fasta:` - Reference genome (e.g., `/orange/cancercenter-dept/GENOMES/iGenomes/references/Homo_sapiens/Ensembl/GRCh38/Sequence/WholeGenomeFasta/genome.fa`)
- `blacklist:` - Blacklist BED (e.g., `/orange/cancercenter-dept/resources/BLACKLISTS/hg38-blacklist.v2.bed`)
- `gtf:` - Gene annotation GTF
- `motifs:` - Motif database (download from [JASPAR](https://jaspar.genereg.net/downloads/))
- `output:` - Output directory name

See full config documentation in the [example config file](contrast1-config.yaml).

### 3. Create Config List File

List all your config names (one per line, without `-config.yaml` suffix):

```bash
cat > config-names.txt << EOF
treatment_vs_control
timepoint1_vs_timepoint2
EOF
```

**Important:** If config-names.txt contains `treatment_vs_control`, you must have `treatment_vs_control-config.yaml`.

### 4. Update SLURM Script

```bash
nano run_tobias.sbatch
```

Update these variables:
- `PIPELINE_DIR` - Path to TOBIAS_snakemake installation
- `ENV_DIR` - Path to your conda environments
- `--mail-user` - Your email
- `--account` - Your HiPerGator account
- `--qos` - Your QOS
- `--array=1-N` - Set N to number of lines in config-names.txt

### 5. Submit Job

```bash
sbatch run_tobias.sbatch
```

### 6. Monitor and Access Results

```bash
# Check job status
squeue -u $USER

# Watch logs
tail -f logs/tobias.*.out

# Results will be in directories specified by config 'output:' field
ls results/
```

---

## Directory Structure

**Your project:**
```
my_analysis_2024/
├── treatment_vs_control-config.yaml
├── timepoint1_vs_timepoint2-config.yaml
├── config-names.txt
├── run_tobias.sbatch
├── logs/
└── results/
    ├── treatment_vs_control_output/
    └── timepoint1_vs_timepoint2_output/
```

**Shared pipeline (separate location):**
```
/blue/YOUR_GROUP/pipelines/TOBIAS_snakemake/
```

---

## Understanding Job Arrays

SLURM job arrays run multiple analyses in parallel. If you have:

```
# config-names.txt
sample_A
sample_B
sample_C
```

And set `#SBATCH --array=1-3`, it creates 3 parallel jobs:
- Task 1 → `sample_A-config.yaml`
- Task 2 → `sample_B-config.yaml`
- Task 3 → `sample_C-config.yaml`

**The `--array` count must match the lines in config-names.txt!**

---

## Common Issues

| Issue | Solution |
|-------|----------|
| Config file not found | Ensure filename is `{name}-config.yaml` matching config-names.txt |
| Snakefile not found | Update `PIPELINE_DIR` in run_tobias.sbatch |
| Array size mismatch | Set `--array=1-N` where N = `wc -l config-names.txt` |
| Out of memory | Increase `--mem` in run_tobias.sbatch (e.g., 48Gb) |
| Conda env not found | Check `ENV_DIR` path or recreate environment |
| Permission denied | Ensure output paths are in /blue, not /orange |

---

## Tips & Best Practices

1. **Test first:** Set `--array=1-1` to test with one sample
2. **Descriptive names:** Use clear config names like `H3K27ac_treated_vs_control`
3. **Check logs:** Always review logs/ before assuming success
4. **Resource estimation:** 
   - Small datasets (~10M reads): Default resources work
   - Large datasets: Increase `--mem` to 48-64Gb and `--time` as needed
5. **Multiple projects:** Clone this template for each new analysis - they all share the same pipeline installation

---

## TOBIAS Output

Each `results/*_output/` directory contains:
- **ATACorrect/** - Bias-corrected ATAC-seq signal
- **ScoreBigwig/** - Footprint scores
- **BINDetect/** - Differential TF binding analysis
- **Plots/** - Visualizations

See [TOBIAS documentation](https://github.com/loosolab/TOBIAS) for details.

---

## Resources

- [TOBIAS GitHub](https://github.com/loosolab/TOBIAS) | [Documentation](https://loosolab.github.io/TOBIAS/)
- [TOBIAS Paper](https://www.nature.com/articles/s41467-020-18035-1)
- [HiPerGator Guide](https://help.rc.ufl.edu/) | [SLURM Job Arrays](https://help.rc.ufl.edu/doc/SLURM_Job_Arrays)
- [JASPAR Motifs](https://jaspar.genereg.net/)

## Getting Help

- Template issues: [GitHub Issues](https://github.com/UFHCC-BCBSR/cb-tobias/issues)
- HiPerGator: [rc-support@ufl.edu](mailto:rc-support@ufl.edu)
- TOBIAS pipeline: [TOBIAS GitHub Issues](https://github.com/loosolab/TOBIAS/issues)

## Citation

> Bentsen M, Goymann P, Schultheis H, et al. ATAC-seq footprinting unravels kinetics of transcription factor binding during zygotic genome activation. Nat Commun 11, 4267 (2020). https://doi.org/10.1038/s41467-020-18035-1

---

**License:** This template - MIT | TOBIAS pipeline - [See License](https://github.com/loosolab/TOBIAS/blob/master/LICENSE)