#!/bin/bash
#SBATCH --qos=short
#SBATCH --mem=60000
#SBATCH --cpus=16
#SBATCH --job-name=DeMo_ensemble
#SBATCH --account=compacts
#SBATCH --output=log/%j.out
#SBATCH --error=log/%j.err
#SBATCH --workdir=/p/projects/compacts/projects/DeMo/social_agent_based_modelling/
#SBATCH --time=0-04:00:00

module load julia/1.6.1
simulation='/p/projects/compacts/projects/DeMo/social_agent_based_modelling/scripts/social_ensembles.jl'
srun julia $simulation 100 #change ensemble size via argument