#!/bin/bash
#SBATCH --qos=priority
#SBATCH --mem=60000
#SBATCH --cpus=16
#SBATCH --job-name=DeMo_ensemble
#SBATCH --account=compacts
#SBATCH --output=%j.out
#SBATCH --error=%j.err
#SBATCH --workdir=/p/projects/compacts/projects/DeMo/social_agent_based_modelling/HPC_scripts
#SBATCH --time=0-00:30:00
module load julia/1.6.1
srun julia /p/projects/compacts/projects/DeMo/social_agent_based_modelling/scripts/social_ensembles.jl 
