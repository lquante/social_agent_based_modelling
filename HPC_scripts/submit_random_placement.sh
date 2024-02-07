#!/bin/bash
#SBATCH --qos=short
#SBATCH --mem=60000
#SBATCH --cpus=16
#SBATCH --job-name=DeMo_random_placement
#SBATCH --account=compacts
#SBATCH --output=log/%j.out
#SBATCH --error=log/%j.err
#SBATCH --workdir=/p/projects/compacts/projects/DeMo/social_agent_based_modelling/
#SBATCH --time=0-23:59:00

module load julia/1.6.1
simulation='/p/projects/compacts/projects/DeMo/social_agent_based_modelling/scripts/self_reliance_random_placement.jl'

srun julia $simulation