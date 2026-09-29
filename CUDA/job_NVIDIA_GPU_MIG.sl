#!/bin/bash

#SBATCH -J "gpu_mig"
#SBATCH --output gpu_mig.o%J
#SBATCH --error gpu_mig.e%J
#SBATCH --partition ar_mig

# GPUs devices
#   gpu:a100_3g.40gb (until 4) 
#   gpu:a100_2g.20gb (until 17) 
#   gpu:a100_1g.10gb (until 10) 
#SBATCH --gres gpu:a100_2g.20gb:1

# CPUs per task
# Set the number of cpu in proportion to the number of GPU's devices :
#SBATCH --cpus-per-gpu 4

# Job time (hh:mm:ss)
#SBATCH --time 00:10:00

# Job maximum memory (MB)
# Set the maximum memory in proportion to the number of GPU's devices :
#SBATCH --mem 15000

module purge
export SHARE=/home/2500001/PROJETS/M26182/PARTAGE/
export MODULEPATH=$SHARE/privatemodules:$MODULEPATH
module load julia
module load cuda/12.3
module list

echo Working directory : $PWD

julia --project -e 'import Pkg; Pkg.add("CUDA")'
srun julia --project test_gpu.jl > gpu_code.log 
