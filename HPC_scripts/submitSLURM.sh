#!/bin/bash
#SBATCH --qos=priority
#SBATCH --mem=60000
#SBATCH --cpus=5
#SBATCH --job-name=DeMo_ensemble
#SBATCH --account=compacts
#SBATCH --output=log/%j.out
#SBATCH --error=log/%j.err
#SBATCH --workdir=/p/projects/compacts/projects/DeMo/social_agent_based_modelling
#SBATCH --time=0-01:00:00

module load julia/1.6.1
srun julia /p/projects/compacts/projects/DeMo/social_agent_based_modelling/scripts/social_ensembles.jl 
