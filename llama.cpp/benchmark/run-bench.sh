#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
BENCH_DIR="${ROOT_DIR}/benchmark"
RESULTS_DIR="${BENCH_DIR}/results"
MODEL_ROOT="${ROOT_DIR}/models"
COMPOSE_FILE="${ROOT_DIR}/docker-compose.yml"
COMPOSE_SERVICE="llama-server"
DEFAULT_BASELINE_IMAGE="ghcr.io/ggml-org/llama.cpp:full-cuda13"
DEFAULT_CANDIDATE_IMAGE="llama-server"
TIMESTAMP="$(date -u +%Y-%m-%dT%H:%M:%SZ)"
THREADS="$(nproc)"

resolve_env_file() {
  local env_ref="${LLAMA_ENV_FILE:-.env}"
  if [[ "${env_ref}" = /* ]]; then
    printf '%s\n' "${env_ref}"
  else
    printf '%s\n' "${ROOT_DIR}/${env_ref}"
  fi
}

ENV_FILE="$(resolve_env_file)"
if [[ ! -f "${ENV_FILE}" ]]; then
  echo "env file not found: ${ENV_FILE}" >&2
  exit 1
fi

set -a
source "${ENV_FILE}"
set +a

BASELINE_IMAGE="${BENCHMARK_BASELINE_IMAGE:-${DEFAULT_BASELINE_IMAGE}}"
CANDIDATE_IMAGE="${BENCHMARK_CANDIDATE_IMAGE:-${DEFAULT_CANDIDATE_IMAGE}}"
BENCH_PORT="${LLAMA_ARG_PORT:-8080}"

if [[ -z "${LLAMA_ARG_HF_REPO:-}" ]]; then
  echo "LLAMA_ARG_HF_REPO must be set in ${ENV_FILE}" >&2
  exit 1
fi

if [[ "${LLAMA_ARG_HOST:-0.0.0.0}" != "0.0.0.0" ]]; then
  echo "benchmark requires LLAMA_ARG_HOST=0.0.0.0 in ${ENV_FILE}" >&2
  exit 1
fi

hf_repo_spec="${LLAMA_ARG_HF_REPO%%:*}"
hf_variant=""
if [[ "${LLAMA_ARG_HF_REPO}" == *:* ]]; then
  hf_variant="${LLAMA_ARG_HF_REPO#*:}"
fi

hf_org="${hf_repo_spec%%/*}"
hf_repo="${hf_repo_spec#*/}"
model_snapshot_dir="${MODEL_ROOT}/hf-home/hub/models--${hf_org}--${hf_repo}/snapshots"

if [[ ! -d "${model_snapshot_dir}" ]]; then
  echo "model snapshot dir not found: ${model_snapshot_dir}" >&2
  echo "download the model first so the benchmark can reuse the same LLAMA_ARG_HF_REPO config" >&2
  exit 1
fi

model_pattern='*.gguf'
if [[ -n "${hf_variant}" ]]; then
  model_pattern="*${hf_variant}*.gguf"
fi

mapfile -t model_candidates < <(find -L "${model_snapshot_dir}" -type f -name "${model_pattern}" | sort)
if [[ ${#model_candidates[@]} -eq 0 && -n "${hf_variant}" ]]; then
  mapfile -t model_candidates < <(find -L "${model_snapshot_dir}" -type f -name '*.gguf' | sort)
fi

if [[ ${#model_candidates[@]} -eq 0 ]]; then
  echo "no GGUF model found under ${model_snapshot_dir}" >&2
  exit 1
fi

MODEL_PATH_ABS="${model_candidates[0]}"
MODEL_PATH_REL="${MODEL_PATH_ABS#${ROOT_DIR}/}"
if [[ "${MODEL_PATH_REL}" == "${MODEL_PATH_ABS}" ]]; then
  echo "model path is outside root dir: ${MODEL_PATH_ABS}" >&2
  exit 1
fi
MODEL_PATH_IN_CONTAINER="/${MODEL_PATH_REL}"

mkdir -p "${RESULTS_DIR}"

# ---- build images ----
docker compose -f "${COMPOSE_FILE}" --env-file "${ENV_FILE}" build "${COMPOSE_SERVICE}"
docker pull "${BASELINE_IMAGE}"

# ---- inspect ----
docker inspect "${BASELINE_IMAGE}" > "${RESULTS_DIR}/baseline-image.inspect.json"
docker inspect "${CANDIDATE_IMAGE}" > "${RESULTS_DIR}/candidate-image.inspect.json"

# ---- server + bench helpers ----
SERVER_ARGS=(
  -m "${MODEL_PATH_IN_CONTAINER}"
)

COMMON_DOCKER_ARGS=(
  --rm
  --gpus all
  --ipc host
  -p "${BENCH_PORT}:${BENCH_PORT}"
  -v "${MODEL_ROOT}:/models"
   -e "LD_LIBRARY_PATH=/usr/local/lib:/usr/local/cuda/lib64:/usr/local/nvidia/lib:/usr/local/nvidia/lib64"
)

while IFS= read -r var_name; do
  if [[ "${var_name}" == "LLAMA_ARG_HF_REPO" ]]; then
    continue
  fi
  COMMON_DOCKER_ARGS+=( -e "${var_name}=${!var_name}" )
done < <(compgen -A variable LLAMA_ARG_ | sort)

wait_for_server() {
  local url="$1"
  for _ in $(seq 1 90); do
    if curl -sf "${url}/health" > /dev/null 2>&1; then
      return 0
    fi
    sleep 2
  done
  echo "server did not start within 180s" >&2
  return 1
}

bench_image() {
  local tag="$1"
  local image="$2"
  local entrypoint="$3"
  local extra_args=()

  if [[ -n "${entrypoint}" ]]; then
    extra_args+=(--entrypoint "${entrypoint}")
  fi

  local cid
  cid="$(docker run -d "${COMMON_DOCKER_ARGS[@]}" "${extra_args[@]}" "${image}" "${SERVER_ARGS[@]}")"
  trap "docker stop '${cid}' >/dev/null 2>&1 || true" EXIT

  wait_for_server "http://127.0.0.1:${BENCH_PORT}"

  "${BENCH_DIR}/mtp-bench.py" \
    --url "http://127.0.0.1:${BENCH_PORT}" \
    --out "${RESULTS_DIR}/${tag}.json"

  docker stop "${cid}" >/dev/null 2>&1
  trap - EXIT
}

bench_image baseline "${BASELINE_IMAGE}" /app/llama-server
bench_image candidate "${CANDIDATE_IMAGE}" ""

# ---- system info ----
nvidia-smi --query-gpu=name,memory.total,driver_version --format=csv,noheader > "${RESULTS_DIR}/gpu.txt"
uname -m > "${RESULTS_DIR}/arch.txt"
printf '%s\n' "${THREADS}" > "${RESULTS_DIR}/threads.txt"

# ---- generate summary ----
python3 - "${BENCH_DIR}" "${RESULTS_DIR}" "${TIMESTAMP}" "${MODEL_PATH_IN_CONTAINER}" <<'PY'
import json, os, pathlib, sys

bench_dir = pathlib.Path(sys.argv[1])
results_dir = pathlib.Path(sys.argv[2])
timestamp = sys.argv[3]
model_path = sys.argv[4]

def load_json(p): return json.loads(p.read_text())
def load_text(p): return p.read_text().strip()

def inspect_obj(data):
    if isinstance(data, list):
        if not data:
            raise ValueError("docker inspect returned an empty list")
        return data[0]
    if isinstance(data, dict):
        return data
    raise TypeError(f"unexpected inspect payload type: {type(data).__name__}")

baseline_inspect = inspect_obj(load_json(results_dir / "baseline-image.inspect.json"))
candidate_inspect = inspect_obj(load_json(results_dir / "candidate-image.inspect.json"))
baseline_results = load_json(results_dir / "baseline.json")
candidate_results = load_json(results_dir / "candidate.json")
gpu_line = load_text(results_dir / "gpu.txt")
arch = load_text(results_dir / "arch.txt")
threads = load_text(results_dir / "threads.txt")

def get_label(insp, key):
    return (insp.get("Config", {}).get("Labels") or {}).get(key, "")

def image_ref(insp):
    repo_digests = insp.get("RepoDigests") or []
    if repo_digests:
        return repo_digests[0]
    repo_tags = insp.get("RepoTags") or []
    if repo_tags:
        return repo_tags[0]
    return insp.get("Id", "")

def results_map(data):
    return {r["name"]: r for r in data.get("results", [])}

baseline_map = results_map(baseline_results)
candidate_map = results_map(candidate_results)
baseline_agg = baseline_results.get("aggregate", {})
candidate_agg = candidate_results.get("aggregate", {})

prompt_names = [r["name"] for r in baseline_results.get("results", [])]

def fmt_tok(v): return f"{v:,.2f} tok/s"
def fmt_rate(v): return f"{v:.3f}" if v is not None else "n/a"
def fmt_pct(v):
    sign = "+" if v >= 0 else ""
    return f"{sign}{v:.2f}%"

def cfg(name, default="n/a"):
    return os.environ.get(name, default)

lines = [
    "# llama.cpp benchmark summary",
    "",
    f"- Timestamp (UTC): `{timestamp}`",
    f"- Host: `{arch}`",
    f"- CPU threads: `{threads}`",
    f"- GPU: `{gpu_line}`",
    f"- Model: `{model_path}`",
    f"- Baseline image: `{image_ref(baseline_inspect)}`",
    f"- Baseline image revision: `{get_label(baseline_inspect, 'org.opencontainers.image.revision') or 'not labeled'}`",
    f"- Candidate image: `{image_ref(candidate_inspect)}`",
    f"- Candidate image revision: `{get_label(candidate_inspect, 'org.opencontainers.image.revision') or 'not labeled'}`",
    "",
    "## Benchmark setup",
    "",
    "- Tool: `mtp-bench.py` (HTTP /completion)",
    f"- Number of prompts: `{len(prompt_names)}`",
    "- Predict tokens per request: `192`",
    "- Temperature: `0.0`",
    f"- GPU layers: `{cfg('LLAMA_ARG_N_GPU_LAYERS')}`",
    f"- Parallel slots: `{cfg('LLAMA_ARG_N_PARALLEL')}`",
    f"- Flash attention: `{cfg('LLAMA_ARG_FLASH_ATTN')}`",
    f"- Context size: `{cfg('LLAMA_ARG_CTX_SIZE')}`",
    f"- KV cache types: `{cfg('LLAMA_ARG_CACHE_TYPE_K')} / {cfg('LLAMA_ARG_CACHE_TYPE_V')}`",
    f"- CPU MoE threads: `{cfg('LLAMA_ARG_N_CPU_MOE')}`",
    f"- mmap: `{cfg('LLAMA_ARG_MMAP')}`",
    "",
    "## Aggregate",
    "",
    "| Metric | Baseline | Candidate | Delta |",
    "| --- | ---: | ---: | ---: |",
]

def agg_metric(key, label, baseline, candidate):
    bv = baseline.get(key)
    cv = candidate.get(key)
    if bv is None or cv is None:
        return
    if isinstance(bv, float):
        delta = ((cv - bv) / bv) * 100.0 if bv else 0.0
        lines.append(f"| {label} | {bv:,.2f} | {cv:,.2f} | {fmt_pct(delta)} |")
    else:
        delta = cv - bv
        d_fmt = f"{delta:+d}"
        lines.append(f"| {label} | {bv:,d} | {cv:,d} | {d_fmt} |")

agg_metric("total_predicted", "Total predicted tokens", baseline_agg, candidate_agg)
agg_metric("wall_s_total", "Total wall time (s)", baseline_agg, candidate_agg)

btp = baseline_agg.get("total_predicted", 0)
bwt = baseline_agg.get("wall_s_total", 1)
ctp = candidate_agg.get("total_predicted", 0)
cwt = candidate_agg.get("wall_s_total", 1)
baseline_throughput = btp / bwt if bwt else 0.0
candidate_throughput = ctp / cwt if cwt else 0.0
tp_delta = ((candidate_throughput - baseline_throughput) / baseline_throughput) * 100.0 if baseline_throughput else 0.0
lines.append(f"| Aggregate throughput | {fmt_tok(baseline_throughput)} | {fmt_tok(candidate_throughput)} | {fmt_pct(tp_delta)} |")

bar = baseline_agg.get("aggregate_accept_rate")
car = candidate_agg.get("aggregate_accept_rate")
if bar is not None and car is not None:
    ar_delta = car - bar
    lines.append(f"| Aggregate accept rate | {bar:.4f} | {car:.4f} | {ar_delta:+.4f} |")

lines.extend([
    "",
    "## Per-prompt results",
    "",
])

show_accept_rate = any(
    row.get("accept_rate") is not None
    for row in list(baseline_map.values()) + list(candidate_map.values())
)

if show_accept_rate:
    lines.extend([
        "| Prompt | Baseline tok/s | Candidate tok/s | Delta | Baseline accept rate | Candidate accept rate |",
        "| --- | ---: | ---: | ---: | ---: | ---: |",
    ])
else:
    lines.extend([
        "| Prompt | Baseline tok/s | Candidate tok/s | Delta |",
        "| --- | ---: | ---: | ---: |",
    ])

for name in prompt_names:
    br = baseline_map.get(name, {})
    cr = candidate_map.get(name, {})
    bt = br.get("predicted_per_second", 0)
    ct = cr.get("predicted_per_second", 0)
    if bt == 0:
        d = 0.0
    else:
        d = ((ct - bt) / bt) * 100.0
    ba = br.get("accept_rate")
    ca = cr.get("accept_rate")
    row = f"| `{name}` | {fmt_tok(bt)} | {fmt_tok(ct)} | {fmt_pct(d)} |"
    if show_accept_rate:
        row = f"{row} {fmt_rate(ba)} | {fmt_rate(ca)} |"
    lines.append(row)

lines.extend([
    "",
    "## Notes",
    "",
    "- This benchmark measures real HTTP `/completion` latency including network round-trip within the host.",
    "- The benchmark reuses the repo env file as the single source of truth for `LLAMA_ARG_*` runtime settings.",
    "- The candidate image is compared against the official llama.cpp image as the baseline.",
    "- `n_predict=192`, `temperature=0.0`, `seed=42`, `cache_prompt=false` across all requests.",
    "- Raw artifacts: `results/baseline.json`, `results/candidate.json`, and both `docker inspect` outputs.",
])

(bench_dir / "summary.md").write_text("\n".join(lines) + "\n")
PY

echo "done - see ${BENCH_DIR}/summary.md"
