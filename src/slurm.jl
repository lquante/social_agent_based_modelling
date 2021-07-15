#functions for slurm HPC submissions
using DrWatson
@quickactivate "Social Agent Based Modelling"
function schedule_script(;
        script="test.jl",
        account="compacts",
        autorelease=true,
        cpus=1,
        jobname="julia_script_submission",
        time="0-12:00:00",
        partition="standard",
        qos="short",
        workdir=".",
        memory=60000)

    mkpath(workdir)

    output = """%j"""
    batch = """
    #!/usr/bin/env bash
    #SBATCH --account=$account
    #SBATCH --acctg-freq=energy=0
    #SBATCH --ntasks=1
    #SBATCH --exclusive
    #SBATCH --cpus-per-task=$cpus
    #SBATCH --mem=$memory
    #SBATCH --error=$workdir/$output.txt
    #SBATCH --export=ALL,OMP_PROC_BIND=FALSE,OMP_NUM_THREADS=$cpus
    #SBATCH --job-name=$jobname
    #SBATCH --nice=0
    #SBATCH --nodes=1
    #SBATCH --output=$workdir/$output.txt
    #SBATCH --partition=$partition
    #SBATCH --qos=$qos
    #SBATCH --time=$time
    #SBATCH --workdir=$workdir
    #SBATCH --mail-type=END,FAIL,TIME_LIMIT
    module load julia/1.6.1
    srun -n 1 julia -p $cpus $script """

    io = open("sbatch.sh", "w")
    println(io, batch)
    close(io)
    run(`sbatch sbatch.sh`)
    rm("sbatch.sh")
end
