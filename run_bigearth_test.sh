#!/bin/bash -l
#SBATCH --job-name=bigearth-test
#SBATCH --ntasks=1
#SBATCH --mem-per-cpu=16g
#SBATCH --time=23:59:59
#SBATCH --gpus=rtx_4090:1
#SBATCH --output=logs/bigearth_test_%j.out
#SBATCH --error=logs/bigearth_test_%j.err
#SBATCH --account=your-slurm-account   # update

module load eth_proxy
module load stack/2024-06
module load cuda/12.4.1
source "${CONDA_HOME:-$HOME/miniconda3}/etc/profile.d/conda.sh"
conda activate lmms-eval-env            # update to your env name

export HF_HUB_CACHE="${HF_HUB_CACHE}"
export HF_HUB_OFFLINE=1

# Image backend — choose one:
#   LMDB (preferred, faster): built with rico-hdl from the full S2 download
export BIGEARTH_LMDB_DIR=/cluster/scratch/hshang/BigEarthNet_txt/Encoded-BigEarthNet
#   Raw TIF fallback (partial S2 download): set BIGEARTH_S2_DIR instead
# export BIGEARTH_S2_DIR=/cluster/scratch/hshang/BigEarthNet/BigEarthNet-S2

cd "$(dirname "$(realpath "$0")")"

python -m lmms_eval \
    --model qwen2_5_vl \
    --model_args pretrained=Qwen/Qwen2.5-VL-3B-Instruct \
    --tasks bigearth_txt \
    --batch_size 1 \
    --output_path ./results/bigearth_test \
    --log_samples \
    --verbosity INFO
