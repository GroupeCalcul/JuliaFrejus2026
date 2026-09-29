#!/bin/bash
#SBATCH --exclusive
#SBATCH -J "mpi.run"
#SBATCH --output mpi.run.o%J
#SBATCH --error mpi.run.e%J
#SBATCH --partition ar_fin
#SBATCH --time 00:10:00

# MPI tasks number
#SBATCH --ntasks 8 

# Maximum memory per compute node (MB)
#SBATCH --mem 732000 

# MPI tasks per compute node
# (on Austral if a MPI task needs > 3916 MB of memory)
##SBATCH --ntasks-per-node 96

module load cpe_env/gcc13.2.1-mpich8.1.30-milan-02.25 
export SHARE=/home/2500001/PROJETS/M26182/PARTAGE/
export MODULEPATH=$SHARE/privatemodules:$MODULEPATH
module load julia
module list
echo Working directory : $PWD
julia --project -e "import Pkg; Pkg.instantiate()"
srun julia --project hello_mpi.jl > mpicode.log
