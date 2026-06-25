#!/bin/bash -l
#SBATCH --job-name=vrsbench-test
#SBATCH --ntasks=1
#SBATCH --mem-per-cpu=16g
#SBATCH --time=12:00:00
#SBATCH --gpus=rtx_4090:1
#SBATCH --output=logs/vrsbench_test_%j.out
#SBATCH --error=logs/vrsbench_test_%j.err
#SBATCH --account=your-slurm-account   # update

module load eth_proxy
module load stack/2024-06
module load cuda/12.4.1
source "${CONDA_HOME:-$HOME/miniconda3}/etc/profile.d/conda.sh"
conda activate lmms-eval-env            # update to your env name

export HF_HUB_CACHE="${HF_HUB_CACHE}"
export HF_HUB_OFFLINE=1

# Directory containing Images_val/ and the VRSBench JSON eval files
export VRSBENCH_IMG_DIR=/cluster/scratch/hshang/VRSBench/Images_val

cd "$(dirname "$(realpath "$0")")"

python -m lmms_eval \
    --model qwen2_5_vl \
    --model_args pretrained=Qwen/Qwen2.5-VL-3B-Instruct \
    --tasks vrsbench \
    --batch_size 1 \
    --output_path ./results/vrsbench_test \
    --log_samples \
    --verbosity INFO
