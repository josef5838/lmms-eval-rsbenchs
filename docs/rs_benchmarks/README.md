# Remote Sensing Benchmarks

Five remote sensing benchmarks have been added to this lmms-eval fork. Each follows the standard lmms-eval task structure: a YAML config plus a `utils.py` with `doc_to_visual`, `doc_to_text`, `doc_to_target`, `process_results`, and aggregation functions.

## Benchmarks at a glance

| Benchmark | Task name | Sub-tasks | Key metrics |
|---|---|---|---|
| [RSRCC](https://huggingface.co/datasets/BigData-KSU/RSRCC) | `rsrcc` | VQA (MCQ + yes/no) on bi-temporal images | `accuracy`, `mcq_accuracy`, `yesno_accuracy` |
| [VRSBench](https://arxiv.org/abs/2406.12384) | `vrsbench` | VQA, captioning, referring expression | `vqa_accuracy` (+ 12 type breakdowns), `cap_BLEU/METEOR/ROUGE_L/CIDEr`, `ref_acc50` |
| [BigEarthNet.txt](https://arxiv.org/abs/2603.29630) | `bigearth_txt` | Binary, MCQ, bounding-box, captioning on Sentinel-2 patches | `binary_accuracy` / `mcq_accuracy` (+ 9 category breakdowns each), `bbox_acc50`, `cap_BLEU/METEOR/ROUGE_L/CIDEr` |
| [GEOBench-VLM](https://arxiv.org/pdf/2411.19325) | `geobench` | Single-image MCQ, temporal change MCQ, captioning, referring detection | `single_accuracy` / `temporal_accuracy` (+ per-task macro), `cap_BLEU/METEOR/ROUGE_L/CIDEr`, `ref_acc50` |
| [FRIEDA](https://arxiv.org/pdf/2512.08016) | `frieda` | Open-ended VQA on multi-map documents | `exact_match`, `f1`, `per_domain` (macro-avg EM), `per_type` (macro-avg EM) |

## Task files

```
lmms_eval/tasks/
├── rsrcc/
│   ├── rsrcc.yaml              # group: rsrcc_test + rsrcc_val (HF Hub)
│   ├── rsrcc_test_local.yaml   # local CSV/image variant (offline)
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

## Prerequisites

```bash
# Java is required for METEOR scoring (pycocoevalcap)
conda install -y -c conda-forge openjdk --no-deps
```

## Data setup

Each benchmark requires downloading the dataset and pointing to it via an environment variable. The `data_files` entries in the YAML configs must also be updated to absolute paths on your system.

### RSRCC

```bash
export RSRCC_LOCAL_DIR=/path/to/RSRCC_test/test   # dir containing before/after images + metadata.csv
```

Update `rsrcc_test_local.yaml` → `data_files.test` to your `metadata.csv` path.

### VRSBench

```bash
export VRSBENCH_IMG_DIR=/path/to/VRSBench/Images_val
```

Update `vrsbench_*.yaml` → `data_files.test` to your JSON eval file paths (`VRSBench_EVAL_vqa.json`, `VRSBench_EVAL_Cap.json`, `VRSBench_EVAL_referring.json`).

### BigEarthNet.txt

Images are loaded from one of two backends (checked in priority order):

**Option A — LMDB** (preferred, fast random access, required for full evaluation):
```bash
# Build the LMDB from the full S2 download using rico-hdl:
# rico-hdl bigearthnet --bigearthnet-s2-dir <S2_DIR> --target-dir <LMDB_DIR>
export BIGEARTH_LMDB_DIR=/path/to/Encoded-BigEarthNet
```

**Option B — Raw TIF fallback** (partial S2 download / testing):
```bash
# Expected layout: <S2_DIR>/<acquisition>/<patch_id>/<patch_id>_B0{2,3,4}.tif
export BIGEARTH_S2_DIR=/path/to/BigEarthNet-S2
```

Update `bigearth_*.yaml` → `data_files.test` to your local parquet paths (`bench_binary.parquet`, `bench_mcq.parquet`, `bench_bbox.parquet`, `bench_cap.parquet`).

### GEOBench-VLM

```bash
export GEOBENCH_DIR=/path/to/GEOBench-VLM
```

Expected directory layout after extracting all zips:
```
GEOBench-VLM/
├── Single.parquet          # images embedded as bytes
├── Temporal/qa.json        # image_path fields are relative to GEOBENCH_DIR
├── Captioning/qa.json
└── Ref-Det/qa.json
```

Update `geobench_*.yaml` → `data_files.test` to the absolute paths above.

> **Note:** `Single.parquet` is ~1 GB with embedded images. The first run builds an Arrow cache (5–10 min); subsequent runs are fast. Set `HF_DATASETS_CACHE` to a fast local filesystem to avoid NFS overhead.

### FRIEDA

Pre-filter questions to those whose images are present on disk (availability depends on what was downloaded):

```bash
python - <<'EOF'
import json, os
base = "/path/to/FRIEDA/images"
with open("/path/to/FRIEDA/frieda_q_bank.json") as f:
    qs = json.load(f)
available = [q for q in qs if all(os.path.exists(os.path.join(base, u)) for u in q["image_urls"])]
with open("FRIEDA/frieda_available.json", "w") as f:
    json.dump(available, f)
print(f"{len(available)}/{len(qs)} questions available")
EOF

export FRIEDA_IMG_DIR=/path/to/FRIEDA/images
```

Update `frieda.yaml` → `data_files.test` to your `frieda_available.json` path.

## Running evaluations

Set the following in your environment before submitting:

```bash
export CONDA_HOME=/path/to/miniconda3
export HF_HUB_CACHE=/path/to/hf_cache
```

Then submit from the repo root:

```bash
sbatch run_rsrcc_test.sh
sbatch run_vrsbench_test.sh
sbatch run_bigearth_test.sh
sbatch run_geobench_test.sh
sbatch run_frieda_test.sh
```

Each script also requires updating the `#SBATCH --account` line and the `conda activate` env name at the top.

For interactive runs (no Slurm):

```bash
export HF_HUB_CACHE=/path/to/hf_cache
export HF_HUB_OFFLINE=1
export RSRCC_LOCAL_DIR=/path/to/RSRCC_test/test  # set the relevant env var for your task

python -m lmms_eval \
    --model qwen2_5_vl \
    --model_args pretrained=Qwen/Qwen2.5-VL-3B-Instruct \
    --tasks rsrcc_test_local \
    --batch_size 1 \
    --output_path ./results/my_run \
    --log_samples --verbosity INFO
```

Replace `--tasks rsrcc_test_local` with any of: `vrsbench`, `bigearth_txt`, `geobench`, `frieda`.

## Implementation notes

- **Multi-image tasks**: RSRCC and GEOBench Temporal pass two PIL images per sample; FRIEDA passes a variable-length list. The model must support multi-image input (e.g. `qwen2_5_vl`).
- **Captioning metrics**: `pycocoevalcap` (BLEU, METEOR, ROUGE-L, CIDEr) requires Java for METEOR. Scorers are instantiated lazily per metric to avoid unnecessary Java process spawning.
- **Referring expression grounding**: VRSBench and GEOBench Ref-Det report `ref_acc50` (IoU ≥ 0.5). GEOBench ground-truth polygons are converted to axis-aligned bounding boxes before comparison.
- **Per-category breakdowns**: BigEarthNet binary/MCQ, GEOBench single/temporal, VRSBench VQA, and FRIEDA log macro-averaged per-category accuracy via `eval_logger.info` during aggregation.
- **Offline inference**: All run scripts set `HF_HUB_OFFLINE=1`. Models and datasets must be pre-downloaded to `HF_HUB_CACHE`.

---

## Deviations from original evaluation protocols

The sections below document known discrepancies between this implementation and each paper's original evaluation setup. Results should be interpreted accordingly and are not directly comparable to numbers reported in the papers unless noted otherwise.

### RSRCC

The RSRCC dataset contains roughly equal numbers of MCQ (A–D, ~49%) and binary yes/no (~51%) questions (21,999 questions in the test split). This implementation correctly handles both types and reports them as separate sub-metrics (`mcq_accuracy`, `yesno_accuracy`), which is an addition not present in the original paper.

**Offline local variant.** The `rsrcc_test_local` task (used in `run_rsrcc_test.sh`) loads images from a local directory rather than the HF Hub. This requires manually extracting the test images. The canonical task is `rsrcc` (HF Hub), which embeds PIL images directly. Results between the two should be identical given the same images; they are evaluated identically once loaded.

**Answer extraction.** MCQ answers are extracted with `\b[A-D]\b` (first matching letter); yes/no answers are extracted by prefix match. The paper does not specify its extraction rule, so minor differences are possible for ambiguous model outputs.

---

### VRSBench

**VQA exact match normalization.** Our normalization removes all non-alphanumeric characters and lowercases the response before comparing. The original paper (arXiv:2406.12384) does not fully specify its normalization pipeline; differences in punctuation handling or stemming could shift overall `vqa_accuracy` by a few points.

**Referring expression coordinate scale mismatch.** Ground-truth bounding boxes in `VRSBench_EVAL_referring.json` use the format `{<x1><y1><x2><y2>}` with integer coordinates in the range 0–100 (percentage of image dimensions). Our prompt instructs the model to output in the same format. However, many VLMs (including Qwen2.5-VL) are pre-trained to output grounding coordinates in a different representation (e.g., absolute pixel coordinates or a 0–1000 normalized scale). If a model does not follow the prompted format, the IoU computation will be incorrect — coordinates in different scales produce near-zero IoU even for a correct localization. This makes `ref_acc50` unreliable for models not explicitly fine-tuned on this coordinate convention.

**Captioning verbosity.** Models that generate much longer captions than the reference will incur a heavy BLEU brevity penalty (observed ratio ~3.6× in smoke tests). This is a model behavior issue rather than a metric bug, but it means absolute BLEU/CIDEr numbers are not comparable across models of different verbosity.

---

### BigEarthNet.txt

**Sentinel-1 images not used.** BigEarthNet is a multi-modal dataset pairing Sentinel-2 (optical, 10 bands) with Sentinel-1 (SAR, 2 polarization channels). The `BigEarthNet.txt.parquet` includes an `s1_name` field for every sample alongside `patch_id` (S2). This implementation loads only the S2 optical bands (B04/B03/B02 → RGB). If the paper's evaluation protocol presents both modalities (or SAR alone for robustness), our S2-only approach is not aligned with it.

**Rationale for S2-only.** Standard VLMs are trained on optical imagery and have no learned representation of SAR backscatter. Feeding S1 images typically produces near-random results. S2-only evaluation is therefore the practical baseline for off-the-shelf VLMs, but it may not match the MM (multi-modal) protocol the paper describes.

**Bounding box coordinate convention.** The `bench_bounding_box.parquet` output format has not been independently verified against the paper's specified coordinate system. Results for `bbox_acc50` should be treated as indicative until confirmed.

---

### GEOBench-VLM

**Ref-Seg task not implemented.** GEOBench-VLM (arXiv:2411.19325) includes a fifth sub-task — Referring Segmentation — which requires predicting a pixel-level segmentation mask and is scored with mIoU. This task is omitted here because standard text-output VLMs cannot directly produce segmentation masks.

**Ref-Det polygon IoU approximation.** Ground-truth annotations in `Ref-Det/qa.json` are polygons (lists of `[x, y]` vertices in absolute pixel coordinates, e.g., `[[[420, 556], [891, 556], [891, 1021], [420, 1021]]]`). This implementation converts each polygon to its axis-aligned bounding box and normalizes to [0, 1] using the `image_size` field. The IoU is then computed on these approximate boxes rather than the original polygons. For rectangular objects the approximation is exact; for rotated or irregular shapes, the axis-aligned box overestimates the GT area, which reduces apparent IoU and therefore `ref_acc50`. The paper likely uses polygon-level IoU.

**Multiple prompt variants.** Each question in the Single and Temporal splits has 5 prompt rephrasings in the `prompts` list. This implementation always uses `prompts[0]`. The paper may average results across all variants, or select a specific one for a standardized comparison.

---

### FRIEDA

**Contextual maps not provided to the model.** Every question in the FRIEDA dataset has two image fields: `image_urls` (1–2 maps directly relevant to the question) and `contextual_urls` (6–10 maps from the same source document, all available on disk). This implementation only loads `image_urls`. The paper's protocol likely provides all maps from the source document to the model — the questions require understanding the document's full spatial context, not just the highlighted maps. Omitting `contextual_urls` means the model sees less context than intended, which will underestimate performance for questions that require cross-map reasoning.

**Partial dataset coverage.** 384 of 500 questions (76.8%) are evaluated because only those questions have all required images available locally. The 116 excluded questions may have a different difficulty distribution, introducing selection bias in the reported metrics.

**Token-level F1 is an addition.** The original paper evaluates with exact match (EM) only, which is standard for short factoid answers. The `f1` metric reported here is an addition for diagnostic purposes and should not be compared with any published baseline.
