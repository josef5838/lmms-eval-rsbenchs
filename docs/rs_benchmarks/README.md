# Remote Sensing Benchmarks

Five remote sensing benchmarks integrated into this lmms-eval fork.

## Benchmarks at a glance

| Benchmark | Task name | Sub-tasks | Key metrics |
|---|---|---|---|
| [RSRCC](https://huggingface.co/datasets/google/RSRCC) | `rsrcc_test` / `rsrcc_val` | VQA (MCQ + yes/no) on bi-temporal satellite images | `accuracy`, `mcq_accuracy`, `yesno_accuracy` |
| [VRSBench](https://huggingface.co/datasets/xiang709/VRSBench) | `vrsbench` | VQA, captioning, referring expression | `vqa_accuracy` (+ 12 type breakdowns), `cap_BLEU/METEOR/ROUGE_L/CIDEr`, `ref_acc50` |
| [BigEarthNet.txt](https://huggingface.co/datasets/BIFOLD-BigEarthNetv2-0/BigEarthNet.txt) | `bigearth_txt` | Binary Q&A, MCQ, bounding-box, captioning on Sentinel-2 patches | `binary/mcq_accuracy` (+ 9 category breakdowns), `bbox_acc50`, `cap_BLEU/METEOR/ROUGE_L/CIDEr` |
| [GEOBench-VLM](https://huggingface.co/datasets/aialliance/GEOBench-VLM) | `geobench` | Single-image MCQ, temporal change MCQ, captioning, referring detection | `single/temporal_accuracy` (+ per-task macro), `cap_BLEU/METEOR/ROUGE_L/CIDEr`, `ref_acc50` |
| [FRIEDA](https://huggingface.co/datasets/knowledge-computing/FRIEDA) | `frieda` | Open-ended VQA on multi-map documents | `exact_match`, `f1`, `per_domain`, `per_type` |

## What loads from HF Hub vs. what you need locally

| Benchmark | QA data | Images |
|---|---|---|
| RSRCC | HF Hub — nothing to download | Embedded in the dataset — nothing to download |
| VRSBench | HF Hub — nothing to download | **Local** — download `Images_val.zip` |
| BigEarthNet.txt | HF Hub — nothing to download | **Local** — download BigEarthNet-S2 or build an LMDB |
| GEOBench Single | HF Hub — nothing to download | Embedded in `Single.parquet` — nothing to download |
| GEOBench Temporal / Captioning / Ref-Det | HF Hub — nothing to download | **Local** — inside the zip archives on HF Hub |
| FRIEDA | HF Hub — nothing to download | **Local** — download the `images/` folder |

---

## Setup

### Prerequisites

Java is required for METEOR scoring:

```bash
conda install -y -c conda-forge openjdk --no-deps
```

Run all commands from the **repo root** (`lmms-eval/`).

---

### 1. RSRCC

No setup needed. QA data and images both come from HF Hub (`google/RSRCC`). The dataset is gated — make sure your HF token is set:

```bash
huggingface-cli login   # one-time, stores token in ~/.cache/huggingface/token
```

```bash
python -m lmms_eval --tasks rsrcc_test ...
```

---

### 2. VRSBench

QA annotation files download from HF Hub automatically. You only need to provide the images.

**Download images:**

```bash
# Download Images_val.zip from https://huggingface.co/datasets/xiang709/VRSBench
# then extract it — you should have a folder structure like:
# VRSBench/
# └── Images_val/
#     ├── P0001.png
#     └── ...
```

**Set the environment variable:**

```bash
export VRSBENCH_DIR=/path/to/VRSBench   # must contain Images_val/
```

---

### 3. BigEarthNet.txt

QA data downloads from HF Hub automatically (it filters the benchmark subset from the full dataset on first run — this takes a few minutes but is cached afterward). You need to provide the Sentinel-2 images.

**Download images — choose one option:**

**Option A — LMDB** (recommended, fast random access):

```bash
# 1. Download BigEarthNet-S2:
#    https://huggingface.co/datasets/BIFOLD-BigEarthNetv2-0/BigEarthNet.txt
#    or from the official BigEarthNet website

# 2. Build an LMDB with rico-hdl:
pip install rico-hdl
rico-hdl bigearthnet --bigearthnet-s2-dir /path/to/BigEarthNet-S2 --target-dir /path/to/BigEarthNet-LMDB
```

```bash
export BIGEARTH_LMDB_DIR=/path/to/BigEarthNet-LMDB
```

**Option B — Raw TIF files** (simpler, slower):

```bash
# Download BigEarthNet-S2 and point directly at it.
# Expected layout: <S2_DIR>/<acquisition>/<patch_id>/<patch_id>_B0{2,3,4}.tif
export BIGEARTH_S2_DIR=/path/to/BigEarthNet-S2
```

---

### 4. GEOBench-VLM

QA data for all sub-tasks loads from HF Hub automatically:

- **Single** (`geobench_single`): images are embedded in the parquet file — nothing to download.
- **Temporal, Captioning, Ref-Det**: QA JSON files stream from inside zip archives on HF Hub. Images are inside those same zips and must be extracted locally.

**Download and extract images for Temporal / Captioning / Ref-Det:**

```bash
# Download from https://huggingface.co/datasets/aialliance/GEOBench-VLM
# You need: Temporal.zip, Captioning.zip, Ref-Det.zip
# Extract them into a single directory:

mkdir -p /path/to/GEOBench-VLM
cd /path/to/GEOBench-VLM
unzip Temporal.zip
unzip Captioning.zip
unzip Ref-Det.zip

# Result:
# GEOBench-VLM/
# ├── Temporal/
# │   └── images/
# ├── Captioning/
# │   └── images/
# └── Ref-Det/
#     └── images/
```

```bash
export GEOBENCH_DIR=/path/to/GEOBench-VLM   # parent directory containing Temporal/, Captioning/, Ref-Det/
```

> `GEOBENCH_DIR` is only required for the three image-local sub-tasks. `geobench_single` always loads from HF Hub and ignores this variable.

---

### 5. FRIEDA

The question bank downloads from HF Hub automatically. You need to provide the map images.

**Download images:**

```bash
# Download the images/ folder from https://huggingface.co/datasets/knowledge-computing/FRIEDA
# It contains subfolders like: seattle-planning/, abu-dhabi/, capetown/, ...
# Place them so the layout is:
# FRIEDA/
# └── images/
#     ├── seattle-planning/
#     ├── abu-dhabi/
#     └── ...
```

```bash
export FRIEDA_DIR=/path/to/FRIEDA   # must contain images/
```

---

## Running evaluations

### Quick start (interactive)

```bash
cd /path/to/lmms-eval

# Set your env vars first (see above), then:
python -m lmms_eval \
    --model qwen2_5_vl \
    --model_args pretrained=Qwen/Qwen2.5-VL-3B-Instruct \
    --tasks rsrcc_test \
    --batch_size 1 \
    --output_path ./results/my_run \
    --log_samples \
    --verbosity INFO
```

Replace `rsrcc_test` with any of: `rsrcc_val`, `vrsbench`, `bigearth_txt`, `geobench`, `frieda`.

### Slurm

Edit the run script for your cluster (update `--account` and `conda activate`), then:

```bash
sbatch run_rsrcc_test.sh
sbatch run_vrsbench_test.sh
sbatch run_bigearth_test.sh
sbatch run_geobench_test.sh
sbatch run_frieda_test.sh
```

### Offline clusters (no internet on compute nodes)

Pre-download all HF Hub data on a login node first:

```bash
# Run these once on the login node:
huggingface-cli download google/RSRCC   # gated — requires HF token with accepted terms
huggingface-cli download xiang709/VRSBench --include "VRSBench_EVAL_*.json"
huggingface-cli download knowledge-computing/FRIEDA --include "frieda_q_bank.json"
huggingface-cli download BIFOLD-BigEarthNetv2-0/BigEarthNet.txt
huggingface-cli download aialliance/GEOBench-VLM --include "Single.parquet" "Temporal.zip" "Captioning.zip" "Ref-Det.zip"
```

Then on the compute node, uncomment `HF_HUB_OFFLINE=1` in the run script (or export it before running):

```bash
export HF_HUB_OFFLINE=1
```

---

## Task file layout

```
lmms_eval/tasks/
├── rsrcc/
│   ├── rsrcc.yaml              # group: rsrcc_test + rsrcc_val
│   ├── rsrcc_test.yaml         # HF Hub (google/RSRCC), test split
│   ├── rsrcc_val.yaml          # HF Hub (google/RSRCC), validation split
│   └── utils.py
├── vrsbench/
│   ├── vrsbench.yaml           # group: vrsbench_vqa + vrsbench_cap + vrsbench_ref
│   ├── vrsbench_{vqa,cap,ref}.yaml
│   └── utils.py
├── bigearth_txt/
│   ├── bigearth_txt.yaml       # group: bigearth_{binary,mcq,bbox,cap}
│   ├── bigearth_{binary,mcq,bbox,cap}.yaml
│   └── utils.py
├── geobench/
│   ├── geobench.yaml           # group: geobench_{single,temporal,cap,ref}
│   ├── geobench_{single,temporal,cap,ref}.yaml
│   └── utils.py
└── frieda/
    ├── frieda.yaml
    └── utils.py
```

---

## Notes

- **Multi-image tasks**: RSRCC and GEOBench Temporal pass two images per sample (before/after). FRIEDA passes one or two maps. The model must support multi-image input (e.g. `qwen2_5_vl`).
- **METEOR requires Java**: install with `conda install -c conda-forge openjdk`.
- **BigEarthNet first run**: the full parquet (9.5M rows) downloads from HF Hub and is filtered to the benchmark subset (~7k rows). This takes several minutes on first run; subsequent runs use the cached Arrow files.
- - **GEOBench Single.parquet**: the file is ~1 GB (images embedded). Set `HF_DATASETS_CACHE` to a fast local filesystem to avoid NFS overhead on first load.

---

## Deviations from original evaluation protocols

Known differences between this implementation and each paper's original setup.

### RSRCC

The test split contains ~22k questions of two types: MCQ (A–D, ~49%) and binary yes/no (~51%). This implementation reports them as separate sub-metrics (`mcq_accuracy`, `yesno_accuracy`), which is an addition not present in the original paper.

### VRSBench

**VQA normalization.** Punctuation is stripped and text is lowercased before comparing. The paper does not fully specify its normalization pipeline.

**Referring expression coordinates.** Ground-truth boxes use integers in the range 0–100. Many VLMs output coordinates in different scales (absolute pixels or 0–1000 normalized). If a model does not follow the prompted format, `ref_acc50` will be near zero regardless of localization quality.

### BigEarthNet.txt

**Sentinel-2 only.** BigEarthNet pairs Sentinel-2 (optical) with Sentinel-1 (SAR). This implementation loads only the S2 RGB bands (B04/B03/B02). Standard VLMs have no trained representation for SAR backscatter, so S2-only evaluation is the practical baseline for off-the-shelf models.

### GEOBench-VLM

**Ref-Seg not implemented.** The referring segmentation sub-task (requires pixel-level mask output, scored with mIoU) is omitted because standard text-output VLMs cannot produce segmentation masks.

**Ref-Det uses bounding box IoU.** Ground-truth annotations are polygons. This implementation converts them to axis-aligned bounding boxes before computing IoU. For non-rectangular objects this overestimates the GT area and reduces apparent IoU.

**Single prompt variant.** Each question has 5 rephrasings; this implementation always uses `prompts[0]`.

### FRIEDA

**Contextual maps not provided.** Each question has `image_urls` (1–2 directly relevant maps) and `contextual_urls` (6–10 maps from the same source document). Only `image_urls` are passed to the model. The paper's protocol likely provides the full document context, so performance may be underestimated for cross-map reasoning questions.

**Token-level F1 is an addition.** The paper evaluates with exact match only. The `f1` metric here is for diagnostic purposes.
