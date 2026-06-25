#!/bin/bash -l
#SBATCH --job-name=geobench-test
#SBATCH --ntasks=1
#SBATCH --mem-per-cpu=16g
#SBATCH --time=23:59:59
#SBATCH --gpus=rtx_4090:1
#SBATCH --output=logs/geobench_test_%j.out
#SBATCH --error=logs/geobench_test_%j.err
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

# Base directory of the extracted GEOBench-VLM dataset
# (must contain Single.parquet, Temporal/, Captioning/, Ref-Det/)
export GEOBENCH_DIR=/path/to/GEOBench-VLM   # update

mkdir -p logs
cd "$(dirname "$(realpath "$0")")"

python -m lmms_eval \
    --model qwen2_5_vl \
    --model_args pretrained=Qwen/Qwen2.5-VL-3B-Instruct \
    --tasks geobench \
    --batch_size 1 \
    --output_path ./results/geobench_test \
    --log_samples \
    --verbosity INFO
