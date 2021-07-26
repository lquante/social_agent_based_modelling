#functions for slurm HPC submissions
using DrWatson
@quickactivate "Social Agent Based Modelling"
function schedule_script(;
        script="test.jl",
        account="compacts",
        autorelease=true,
        cpus=1,
        jobname="test_script_submission",
        time="12:00:00",
        notify=true,
        partition="standard",
        prelimitseconds=60 * 60,
        qos="short",
        workdir=".",
        memory=60000)

    logdir = workdir
    mkpath(workdir)
    mkpath(logdir)

    other_options = ""
    if notify
        other_options * """#SBATCH --mail-type=END,FAIL,TIME_LIMIT\n"""
    end
    output = """%j"""
    batch = """
    #!/usr/bin/env bash
    #SBATCH --account=$account
    #SBATCH --acctg-freq=energy=0
    #SBATCH --constraint=haswell
    #SBATCH --ntasks=1
    #SBATCH --cpus-per-task=$cpus
    #SBATCH --mem=$memory
    #SBATCH --error=$logdir/error_$output.txt
    #SBATCH --exclusive
    #SBATCH --export=ALL,OMP_PROC_BIND=FALSE,OMP_NUM_THREADS=$cpus
    #SBATCH --job-name=$jobname
    #SBATCH --nice=0
    #SBATCH --nodes=1
    #SBATCH --output=$logdir/$output.txt
    #SBATCH --partition=$partition
    #SBATCH --qos=$qos
    #SBATCH --time=$time
    #SBATCH --workdir=$workdir
    $other_options

    module load julia/1.6.1
    julia -p $cpus $script """

    io = open("sbatch.sh", "w")
    println(io, batch)
    close(io)
    run(`sbatch sbatch.sh `)
    rm("sbatch.sh")
end
