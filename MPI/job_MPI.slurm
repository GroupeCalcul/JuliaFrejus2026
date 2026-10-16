#!/bin/bash
#SBATCH --job-name "mpi_example"
#SBATCH --output %x.%j.out
#SBATCH --error %x.%j.err
#SBATCH --partition ar_fin
#SBATCH --time 00:10:00

#SBATCH --ntasks 8            # number of MPI tasks
#SBATCH --cpus-per-task 1     # 1 CPU = 1 MPI task
#SBATCH --hint nomultithread  # disable hyperthreading

# Maximum memory per compute node (MB)
# #SBATCH --mem 732000 

# MPI tasks per compute node
# (on Austral if a MPI task needs > 3916 MB of memory)
# #SBATCH --ntasks-per-node 96

module load cpe_env/gcc13.2.1-mpich8.1.30-milan-02.25 
export SHARE=/home/2500001/PROJETS/M26182/PARTAGE/
export MODULEPATH=$SHARE/privatemodules:$MODULEPATH
module load julia
module list

echo "Working directory: $PWD"
julia --project -e "import Pkg; Pkg.instantiate()"
srun julia --project --color=yes hello_mpi.jl > mpicode.log
