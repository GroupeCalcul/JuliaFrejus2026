# ANF Julia HPC Frejus 2026

Le Groupe Calcul organise une Action Nationale de Formation (ANF) Julia4HPC qui a lieu du 12 au 16 octobre 2026 à Fréjus. 
Cette formation s'adresse à tous les ingénieur·e·s et chercheur·e·s souhaitant progresser en Julia. En fonction des objectifs propres à chacun des participant·e·s, cette semaine de formation est aussi une occasion pour la communauté francophone de développeurs Julia issus du monde académique, d'échanger et collaborer.

Les objectifs de la formation sont:
- Créer des codes génériques adaptables à différents types de données.
- Analyser et optimiser leur code Julia pour réduire la consommation CPU.
- Gérer efficacement la mémoire et minimiser l’usage du "garbage collector".
- Utiliser Julia sur un cluster HPC, paralléliser avec SIMD, "multithreading", calcul distribué natif ou MPI.
- Exploiter des cartes GPU dédiées au calcul.

Ce  dépôt contient quelques supports pour la formation, notamment les scripts SLURM pour soummettre 
des travaux sur le cluster [Artic du CRIANN](https://services.criann.fr/services/hpc/cluster-austral/guide/). Trois projets 
sont disponibles:

- AMDGPU : pour utiliser les GPU AMD 
- CUDA : pourutiliser les cartes NVIDIA
- MPI : pour lancer un programme utilisant cette bibliothèque parallèle.

## Exemple

```bash
ssh -l votre_login arctic.criann.fr
git clone https://github.com/GroupeCalcul/JuliaFrejus2026
cd JuliaFrejus2026/MPI
sbatch job_MPI.sl
cat mpicode.log
```

```
Hello world, I am 7 of 8
Hello world, I am 5 of 8
Hello world, I am 0 of 8
Hello world, I am 1 of 8
Hello world, I am 2 of 8
Hello world, I am 3 of 8
Hello world, I am 4 of 8
Hello world, I am 6 of 8
```
## Jupyter Julia Kernel

Pour avoir accès au noyau Julia sur l'interface Jupyter du CRIANN, il suffit de faire les commandes suivantes
sur votre serveur avant de démarrer l'instance sur l'interface Jupyter

```bash
export SHARE=/home/2500001/PROJETS/M26182/PARTAGE/
export MODULEPATH=$SHARE/privatemodules:$MODULEPATH
module load julia
julia -e 'import Pkg; Pkg.build("IJulia")'
```

