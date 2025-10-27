# cb-tobias: TOBIAS Analysis Pipeline Template for HiPerGator

## Overview
This repository provides a ready-to-use template for running TOBIAS (Transcription Factor Binding Analysis) on UF HiPerGator using SLURM job arrays. Clone this repo for each new project and point to a centrally installed TOBIAS pipeline.

## One-Time Pipeline Installation

Install the TOBIAS pipeline once in a shared location (do this once per group):

```bash
# Install to a shared group location
cd /blue/YOUR_GROUP/pipelines/
git clone https://github.com/loosolab/TOBIAS_snakemake.git

# Set up conda environment
ml conda
cd TOBIAS_snakemake
conda env create -f environments/tobias_snakemake.yaml --prefix /blue/YOUR_GROUP/YOUR_USERNAME/conda_envs/tobias_snakemake_env
```

## Quick Start for New Project

```bash
# 1. Clone this template
cd /blue/YOUR_GROUP/YOUR_USERNAME/
git clone https://github.com/UFHCC-BCBSR/cb-tobias.git my_tobias_project
cd my_tobias_project

# 2. Edit configuration files (see [Configuration Files](#configuration-files))
nano run_tobias.sbatch            # Update PIPELINE_DIR, account, email
nano contrast1-config.yaml        # Rename and update with your data paths (do this for each config, create more as needed)
nano config-names.txt             # List your {config-names} from  {config-name}-config.yaml. config file names must follow this naming syntax.

# 3. Create logs directory for SLURM logs
mkdir -p logs

# 4. Submit
sbatch run_tobias.sbatch
```

## Repository Structure

```
cb-tobias/                         # This template repo
├── README.md                      # This file
├── contrast1-config.yaml          # Example config file
├── contrast2-config.yaml          # Example config file
├── config-names.txt               # Example config files list
├── run_tobias.sbatch              # SLURM submission script
└── .gitignore                     # Ignore logs and results
```

## Your Project Structure (After Setup)

```
my_tobias_project/
├── group1_vs_group2-config.yaml    # Your comparison configs
├── group3_vs_group4-config.yaml
├── config-names.txt                # Your comparison list (one line per config file)
├── run_tobias.sbatch               # Modified SLURM script
├── logs/                           # SLURM logs (create this)
│   ├── tobias.123456_1.out
│   └── tobias.123456_1.err
├── results/                        # Analysis outputs (auto-created)
│   ├── group1_vs_group2_output/
│   └── group3_vs_group4_output/
└── README.md
```

**Separate pipeline installation:**
```
/blue/YOUR_GROUP/pipelines/
└── TOBIAS_snakemake/              # Shared pipeline (installed once)
    ├── Snakefile
    ├── snakefiles/
    ├── scripts/
    └── environments/
```

## Configuration Files

### 1. config-names.txt

Plain text file with one run/config per line. Each line corresponds to a config file.

**Format:**
```
group1_vs_group2
group3_vs_group4
```


**Important:** If your config-names.txt contains `group1_vs_group2`, you must have a file named EXACTLY `group1_vs_group2-config.yaml`.

---

### 2. {config-name}-config.yaml

YAML configuration file for each run. Rename the example configs and edit with your data.

**Naming convention:**
- config-names.txt line: `group1_vs_group2`
- Config filename:  `group1_vs_group2-config.yaml`

**Key sections:**

```yaml
data:
  condition1: [/path/to/condition1.bam]       # Path to BAM file(s)
  condition2: [/path/to/condition2.bam]       # Path to BAM file(s)

run_info:
  organism: human                              # human/mouse/zebrafish
  fasta: /path/to/genome.fa                   # Reference genome FASTA
  blacklist: /path/to/blacklist.bed           # Blacklist regions BED file
  gtf: /path/to/annotation.gtf                # Gene annotation GTF
  motifs: /path/to/motifs/*                   # Motif database files
  output: group1_vs_group2_output           # Output directory name

flags:
  plot_comparison: True
  plot_correction: True
  plot_venn: True
  coverage: True
  wilson: True
```

**Example HiPerGator resource paths:**
- **Genomes:** `/orange/cancercenter-dept/GENOMES/iGenomes/references/`
  - Example: `/orange/cancercenter-dept/GENOMES/iGenomes/references/Homo_sapiens/Ensembl/GRCh38/Sequence/WholeGenomeFasta/genome.fa`
- **Blacklists:** `/orange/cancercenter-dept/resources/BLACKLISTS/`
  - Example: `/orange/cancercenter-dept/resources/BLACKLISTS/hg38-blacklist.v2.bed`
- **GTF:** `/orange/cancercenter-dept/GENOMES/iGenomes/references/`
  - Example: `/orange/cancercenter-dept/GENOMES/iGenomes/references/Homo_sapiens/Ensembl/GRCh38/Annotation/Genes/genes.gtf`
- **JASPAR motifs:** Download from [JASPAR database](https://jaspar.genereg.net/downloads/)

---

### 3. run_tobias.sbatch

SLURM batch script that submits your analysis as a job array.

**Critical parameters to update:**

```bash
# Path to centrally installed pipeline
PIPELINE_DIR='/blue/YOUR_GROUP/pipelines/TOBIAS_snakemake'  # UPDATE THIS

# SLURM account settings
#SBATCH --mail-user=YOUR_EMAIL@ufl.edu        # UPDATE THIS
#SBATCH --account=YOUR_ACCOUNT                 # UPDATE THIS (e.g., cancercenter-dept)
#SBATCH --qos=YOUR_QOS                         # UPDATE THIS (e.g., cancercenter-dept-b)
#SBATCH --array=1-N                            # UPDATE N to match lines in samples.txt
```

**Resource settings:**
- `--cpus-per-task=8` - CPUs per job
- `--mem=24Gb` - Memory per job (increase if needed)
- `--time=48:00:00` - Max runtime (48 hours)
- `--cores 8` in snakemake command must match `--cpus-per-task`

**How it works:**
1. Each array task reads one line from config-names.txt
2. Finds the corresponding config file
3. Runs Snakemake with that config
4. All jobs run in parallel

---

## Step-by-Step Usage Guide

### Step 1: One-Time Pipeline Installation (Once Per Group)

```bash
# Install pipeline to shared location
cd /blue/YOUR_GROUP/pipelines/
git clone https://github.com/loosolab/TOBIAS_snakemake.git

# Create conda environment
ml conda
cd TOBIAS_snakemake
# Instead of -n (name), use --prefix (path) to install the environment in a shared location and/or with more space than default ~
conda env create -f environments/tobias_snakemake.yaml --prefix /blue/YOUR_GROUP/YOUR_USERNAME/conda_envs/tobias_snakemake_env
cd ..
```

---

### Step 2: Create New Project

```bash
# Clone this template
cd /blue/YOUR_GROUP/YOUR_USERNAME/projects/
git clone https://github.com/UFHCC-BCBSR/cb-tobias.git my_tobias_analysis
cd my_tobias_analysis

# Create logs directory
mkdir -p logs
```

---

### Step 3: Configure Analysis

#### A. Update run_tobias.sbatch

```bash
nano run_tobias.sbatch
```

Update these lines:
```bash
PIPELINE_DIR='/blue/cancercenter-dept/pipelines/TOBIAS_snakemake'  # Your pipeline path
#SBATCH --mail-user=yourname@ufl.edu                               # Your email
#SBATCH --account=cancercenter-dept                                # Your account
#SBATCH --qos=cancercenter-dept-b                                  # Your QOS
#SBATCH --array=1-2                                                # Match sample count
```

#### B. Create Config Files

```bash
# Rename example configs
mv config_sample1.yaml config_treatment1_vs_control_config.yaml
mv config_sample2.yaml config_treatment2_vs_control_config.yaml

# Edit first config
nano config_treatment1_vs_control_config.yaml
```

Update paths in each config:
- `data:` section with your BAM files
- `fasta:`, `blacklist:`, `gtf:`, `motifs:` with appropriate paths
- `output:` with desired output directory name

#### C. Create samples.txt

```bash
cat > samples.txt << EOF
treatment1_vs_control
treatment2_vs_control
EOF
```

---

### Step 4: Submit Job

```bash
```

---

### Step 5: Monitor Progress

```bash
# Check job status
squeue -u $USER

# View output logs in real-time
tail -f logs/tobias.*.out

# Check for errors
tail -f logs/tobias.*.err

# Check specific array task
tail -f logs/tobias.JOBID_1.out  # Replace JOBID with actual job ID
```

---

### Step 6: Access Results

Results will be in directories specified by the `output:` field in each config:

```bash
ls results/treatment1_vs_control_output/
ls results/treatment2_vs_control_output/
```

---

## Understanding Job Arrays

Job arrays allow parallel processing of multiple samples efficiently.

**How it works:**

```bash
#SBATCH --array=1-3  # Creates 3 parallel jobs
```

If samples.txt contains:
```
sample_A
sample_B
sample_C
```

Then:
- Array task 1 processes `config_sample_A_config.yaml`
- Array task 2 processes `config_sample_B_config.yaml`
- Array task 3 processes `config_sample_C_config.yaml`

**Important:** The `--array` range must match the number of lines in samples.txt!

---

## Common Issues & Solutions

### ❌ Config File Not Found

**Error:**
```
FileNotFoundError: [Errno 2] No such file or directory: 'sample1_config.yaml'
```

**Solution:**
- Config files must be named: `config_{name}_config.yaml`
- If samples.txt has `sample1`, you need `config_sample1_config.yaml`

---

### ❌ Pipeline/Snakefile Not Found

**Error:**
```
WorkflowError: Snakefile not found
```

**Solution:**
Update `PIPELINE_DIR` in run_tobias.sbatch to point to your TOBIAS_snakemake installation:
```bash
PIPELINE_DIR='/blue/YOUR_GROUP/pipelines/TOBIAS_snakemake'
```

---

### ❌ Array Size Mismatch

**Error:** Some array tasks fail immediately with empty output

**Solution:**
Ensure `--array=1-N` where N = number of lines in samples.txt:
```bash
# Count lines
wc -l samples.txt

# Update array in run_tobias.sbatch
#SBATCH --array=1-N  # Replace N with your count
```

---

### ❌ Out of Memory (OOM)

**Error:** Job killed, logs show `oom-kill` or memory errors

**Solution:**
Increase memory in run_tobias.sbatch:
```bash
#SBATCH --mem=48Gb  # or 64Gb, 96Gb
```

---

### ❌ Conda Environment Not Found

**Error:**
```
CondaEnvironmentError: environment does not exist: tobias_snakemake_env
```

**Solution:**
Create the environment:
```bash
ml conda
cd /blue/YOUR_GROUP/pipelines/TOBIAS_snakemake
conda env create -f environments/tobias_snakemake.yaml --prefix /blue/YOUR_GROUP/YOUR_USERNAME/conda_envs/tobias_snakemake_env
```

---

### ❌ Permission Denied

**Error:** Cannot write to output directory

**Solution:**
Ensure your `output:` path in the config is in a directory you have write access to (not /orange, use /blue)

---

## Multiple Projects

You can clone this template multiple times for different analyses:

```bash
cd /blue/YOUR_GROUP/YOUR_USERNAME/
git clone https://github.com/UFHCC-BCBSR/cb-tobias.git project_2024_Q1
git clone https://github.com/UFHCC-BCBSR/cb-tobias.git project_2024_Q2
git clone https://github.com/UFHCC-BCBSR/cb-tobias.git manuscript_fig3
```

All projects share the same centrally installed TOBIAS pipeline.

---

## Version Control

**Files tracked in git:**
- Configuration files (*.yaml)
- samples.txt
- run_tobias.sbatch (your modifications)
- README.md

**Files ignored (.gitignore):**
- logs/ (SLURM logs)
- results/ (analysis output)
- *.bam, *.bai (data files)
- *_output/ (output directories)

To save your project configuration:
```bash
git add config_*.yaml samples.txt run_tobias.sbatch
git commit -m "Analysis configuration for PROJECT_NAME"
git push
```

---

## Updating the Pipeline

To update the centrally installed TOBIAS pipeline:

```bash
cd /blue/YOUR_GROUP/pipelines/TOBIAS_snakemake
git pull origin main
```

All projects will automatically use the updated version on their next run.

---

## Tips & Best Practices

1. **Test with one sample first:** Set `--array=1-1` to test your configuration
2. **Use descriptive names:** Name configs clearly (e.g., `H3K27ac_treat_vs_ctrl`)
3. **Check logs:** Always check logs/ for errors before assuming success
4. **Dry run:** Test Snakemake with `--dryrun` flag first
5. **Resource estimation:** Small datasets (~10M reads) work with default resources; larger datasets may need more memory/time

---

## TOBIAS Output

TOBIAS generates several key outputs in each `*_output/` directory:

- **ATACorrect/** - Bias-corrected ATAC-seq signal
- **ScoreBigwig/** - Footprint scores
- **BINDetect/** - Differential TF binding analysis
- **Plots/** - Visualization of results

See [TOBIAS documentation](https://github.com/loosolab/TOBIAS) for detailed output descriptions.

---

## Resources

- [TOBIAS GitHub](https://github.com/loosolab/TOBIAS)
- [TOBIAS Documentation](https://loosolab.github.io/TOBIAS/)
- [TOBIAS Paper](https://www.nature.com/articles/s41467-020-18035-1)
- [HiPerGator Documentation](https://help.rc.ufl.edu/)
- [SLURM Job Arrays Guide](https://help.rc.ufl.edu/doc/SLURM_Job_Arrays)
- [JASPAR Motif Database](https://jaspar.genereg.net/)
- [Snakemake Documentation](https://snakemake.readthedocs.io/)

---

## Getting Help

**Template issues:** [GitHub Issues](https://github.com/UFHCC-BCBSR/cb-tobias/issues)

**HiPerGator support:** [rc-support@ufl.edu](mailto:rc-support@ufl.edu)

**TOBIAS pipeline issues:** [TOBIAS GitHub Issues](https://github.com/loosolab/TOBIAS/issues)

**Bioinformatics consultation:** Contact UF Health Cancer Center Bioinformatics Core

---

## Citation

If you use TOBIAS in your research, please cite:

> Bentsen M, Goymann P, Schultheis H, et al. ATAC-seq footprinting unravels kinetics of transcription factor binding during zygotic genome activation. Nat Commun 11, 4267 (2020). https://doi.org/10.1038/s41467-020-18035-1

---

## License

This template repository: MIT License

TOBIAS pipeline: See [TOBIAS License](https://github.com/loosolab/TOBIAS/blob/master/LICENSE)
