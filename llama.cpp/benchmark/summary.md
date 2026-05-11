# llama.cpp benchmark summary

- Timestamp (UTC): `2026-05-11T14:08:00Z`
- Host: `x86_64`
- CPU threads: `32`
- GPU: `NVIDIA GeForce RTX 4070 Ti SUPER, 16376 MiB, 595.71.05`
- Model: `/models/hf-home/hub/models--unsloth--Qwen3.6-35B-A3B-GGUF/snapshots/a483e9e6cbd595906af30beda3187c2663a1118c/Qwen3.6-35B-A3B-UD-Q4_K_M.gguf`
- Baseline image: `ghcr.io/ggml-org/llama.cpp@sha256:ef5cb3a6ac1eb14c0bd9cdbfbcfb1454b32e5b9275b151692c9c05254ded806d`
- Baseline image revision: `not labeled`
- Candidate image: `llama-server:latest`
- Candidate image revision: `dd9280a6643d2c4931df7c9246b2f344c0a0513a`

## Benchmark setup

- Tool: `mtp-bench.py` (HTTP /completion)
- Number of prompts: `9`
- Predict tokens per request: `192`
- Temperature: `0.0`
- GPU layers: `999`
- Parallel slots: `1`
- Flash attention: `on`
- Context size: `131072`
- KV cache types: `q8_0 / q8_0`
- CPU MoE threads: `22`
- mmap: `off`

## Aggregate

| Metric | Baseline | Candidate | Delta |
| --- | ---: | ---: | ---: |
| Total predicted tokens | 1,419 | 1,419 | +0 |
| Total wall time (s) | 17.49 | 17.42 | -0.40% |
| Aggregate throughput | 81.13 tok/s | 81.46 tok/s | +0.40% |

## Per-prompt results

| Prompt | Baseline tok/s | Candidate tok/s | Delta |
| --- | ---: | ---: | ---: |
| `code_python` | 88.40 tok/s | 89.49 tok/s | +1.23% |
| `code_cpp` | 89.27 tok/s | 90.19 tok/s | +1.03% |
| `explain_concept` | 89.99 tok/s | 89.98 tok/s | -0.01% |
| `summarize` | 89.11 tok/s | 90.50 tok/s | +1.56% |
| `qa_factual` | 91.17 tok/s | 90.45 tok/s | -0.79% |
| `translation` | 92.58 tok/s | 92.96 tok/s | +0.41% |
| `creative_short` | 90.41 tok/s | 90.10 tok/s | -0.34% |
| `stepwise_math` | 90.12 tok/s | 90.32 tok/s | +0.22% |
| `long_code_review` | 88.95 tok/s | 89.08 tok/s | +0.15% |

## Notes

- This benchmark measures real HTTP `/completion` latency including network round-trip within the host.
- The benchmark reuses the repo env file as the single source of truth for `LLAMA_ARG_*` runtime settings.
- The candidate image is compared against the official llama.cpp image as the baseline.
- `n_predict=192`, `temperature=0.0`, `seed=42`, `cache_prompt=false` across all requests.
- Raw artifacts: `results/baseline.json`, `results/candidate.json`, and both `docker inspect` outputs.
