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
simulation='/home/damianho/projects/social_agent_based_modelling/scripts/social_ensembles.jl'
srun julia $simulation 100
srun julia $simulation 101
srun julia $simulation 102
srun julia $simulation 103
srun julia $simulation 104
srun julia $simulation 105
srun julia $simulation 106
srun julia $simulation 107
srun julia $simulation 108
srun julia $simulation 109
