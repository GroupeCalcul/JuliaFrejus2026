#!/bin/bash

#SBATCH -J "gpu_amd"
#SBATCH --output gpu_amd.o%J
#SBATCH --error gpu_amd.e%J
#SBATCH --partition ar_mi210

# GPU devices
#SBATCH --gres gpu:mi210:1

# CPUs per task
# Set the number of cpu in proportion to the number of GPU's devices :
#SBATCH --cpus-per-gpu 16

#SBATCH --time 00:10:00

# Job maximum memory (MB)
# Set the maximum memory in proportion to the number of GPU's devices :
#SBATCH --mem 62000 

module purge
module load cpe/24.03
module load PrgEnv-cray 
module load rocm/6.1.3
module load craype-x86-milan
module load craype-accel-amd-gfx90a
export SHARE=/home/2500001/PROJETS/M26182/PARTAGE/
export MODULEPATH=$SHARE/privatemodules:$MODULEPATH
module load julia
module list
echo Working directory : $PWD
julia --project -e 'import Pkg; Pkg.add("AMDGPU")'
srun julia --project test_amd.jl > amd_code.log 
