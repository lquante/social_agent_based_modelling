#!/bin/bash

jobid1=$(sbatch -W HPC_scripts/submitSLURM.sh)
echo $jobid1

# sbatch --dependency=afterok:${jobid1//[^0-9]/} HPC_scripts/postSubmit.sh

#until [ -f log/.out#do
#    sleep 5
#done

wait

latest_file=$(ls -t data/avantgarde | head -n1)

# rename slurm output files
cd log/
#mv post.out ${latest_file%.*}_post.out
#mv post.err ${latest_file%.*}_post.err

mv "${jobid1//[^0-9]}.out" "${latest_file%.*}.out"
mv "${jobid1//[^0-9]}.err" "${latest_file%.*}.err"
