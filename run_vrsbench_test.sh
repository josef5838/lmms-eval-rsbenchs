#!/bin/bash -l
#SBATCH --job-name=vrsbench-test
#SBATCH --ntasks=1
#SBATCH --mem-per-cpu=16g
#SBATCH --time=12:00:00
#SBATCH --gpus=rtx_4090:1
#SBATCH --output=logs/vrsbench_test_%j.out
#SBATCH --error=logs/vrsbench_test_%j.err
#SBATCH --account=your-slurm-account   # update

# Platform-specific module loads — uncomment if needed for your cluster
# module load eth_proxy
# module load stack/2024-06
# module load cuda/12.4.1

source "${CONDA_HOME:-$HOME/miniconda3}/etc/profile.d/conda.sh"
conda activate lmms-eval-env            # update to your env name

export HF_HUB_CACHE="${HF_HUB_CACHE:-$HOME/.cache/huggingface}"
export HF_DATASETS_CACHE="${HF_HUB_CACHE}/datasets"
# export HF_HUB_OFFLINE=1              # uncomment for offline compute nodes

# Directory containing Images_val/ (annotation JSONs load from HF Hub automatically)
export VRSBENCH_DIR=/path/to/VRSBench   # update — only needed for images

cd "$(dirname "$(realpath "$0")")"

python -m lmms_eval \
    --model qwen2_5_vl \
    --model_args pretrained=Qwen/Qwen2.5-VL-3B-Instruct \
    --tasks vrsbench \
    --batch_size 1 \
    --output_path ./results/vrsbench_test \
    --log_samples \
    --verbosity INFO
