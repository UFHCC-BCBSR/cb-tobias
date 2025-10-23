# Interactive session
#srun --ntasks=1 --cpus-per-task=2 --mem=8gb --time=2:00:00 --pty bash -i

module load conda

# Create a basic conda environment with just python
conda create -p /blue/cancercancer-dept/hkates/conda_envs/tobias python=3.9 -y

# Activate it
conda activate /blue/cancercenter-dept/hkates/conda_envs/tobias

# Install TOBIAS with pip (much faster)
pip install tobias
