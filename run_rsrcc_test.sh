#!/bin/bash -l
#SBATCH --job-name=rsrcc-test
#SBATCH --ntasks=1
#SBATCH --mem-per-cpu=16g
#SBATCH --time=04:00:00
#SBATCH --gpus=rtx_4090:1
#SBATCH --output=logs/rsrcc_test_%j.out
#SBATCH --error=logs/rsrcc_test_%j.err
#SBATCH --account=your-slurm-account   # update

module load eth_proxy
module load stack/2024-06
module load cuda/12.4.1
source "${CONDA_HOME:-$HOME/miniconda3}/etc/profile.d/conda.sh"
conda activate lmms-eval-env            # update to your env name

export HF_HUB_CACHE="${HF_HUB_CACHE}"
export HF_HUB_OFFLINE=1

# Path to the RSRCC test split image directory (contains before/after images + metadata.csv)
export RSRCC_LOCAL_DIR=/cluster/scratch/hshang/RSRCC_test/test

cd "$(dirname "$(realpath "$0")")"

python -m lmms_eval \
    --model qwen2_5_vl \
    --model_args pretrained=Qwen/Qwen2.5-VL-3B-Instruct \
    --tasks rsrcc_test_local \
    --batch_size 1 \
    --output_path ./results/rsrcc_test \
    --log_samples \
    --verbosity INFO
