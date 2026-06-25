#!/bin/bash -l
#SBATCH --job-name=geobench-test
#SBATCH --ntasks=1
#SBATCH --mem-per-cpu=16g
#SBATCH --time=23:59:59
#SBATCH --gpus=rtx_4090:1
#SBATCH --output=/cluster/work/igp_psr/hshang/lmms-eval/logs/geobench_test_%j.out
#SBATCH --error=/cluster/work/igp_psr/hshang/lmms-eval/logs/geobench_test_%j.err
#SBATCH --account=ls_polle

module load eth_proxy
module load stack/2024-06
module load cuda/12.4.1
source /cluster/home/hshang/miniconda3/etc/profile.d/conda.sh
conda activate /cluster/work/igp_psr/hshang/llms-eval-env

export HF_TOKEN=REDACTED
export HF_HUB_CACHE=/cluster/scratch/hshang/hf_cache
export HF_DATASETS_CACHE=/cluster/scratch/hshang/hf_cache/datasets
export HF_HUB_OFFLINE=1

cd /cluster/work/igp_psr/hshang/lmms-eval

python -m lmms_eval \
    --model qwen2_5_vl \
    --model_args pretrained=Qwen/Qwen2.5-VL-3B-Instruct \
    --tasks geobench \
    --batch_size 1 \
    --limit 10 \
    --output_path ./results/geobench_smoke_test \
    --log_samples \
    --verbosity INFO
