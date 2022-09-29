#!/bin/bash

#SBATCH --qos=short
#SBATCH --time=00:10:00
#SBATCH --mem=2gb
#SBATCH --job-name=post_processing_DeMo_Agents
#SBATCH --account=compacts
#SBATCH --output=log/post.out
#SBATCH --error=log/post.err
#SBATCH --workdir=/p/projects/compacts/projects/DeMo/social_agent_based_modelling

latest_file=$(ls -t data/avantgarde | head -n1)

module load anaconda/2020.07
python3 post-processing/avantgarde_post.py "data/avantgarde/$latest_file"
