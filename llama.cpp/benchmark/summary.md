# llama.cpp benchmark summary

- Timestamp (UTC): `2026-05-11T15:23:53Z`
- Host: `x86_64`
- CPU threads: `32`
- GPU: `NVIDIA GeForce RTX 4070 Ti SUPER, 16376 MiB, 595.71.05`
- Baseline VRAM (used/peak): `13429` / `13414` MiB
- Candidate VRAM (used/peak): `13416` / `13414` MiB
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
| Total wall time (s) | 17.67 | 17.36 | -1.75% |
| Aggregate throughput | 80.31 tok/s | 81.74 tok/s | +1.79% |

## Per-prompt results

| Prompt | Baseline tok/s | Candidate tok/s | Delta |
| --- | ---: | ---: | ---: |
| `code_python` | 85.73 tok/s | 88.60 tok/s | +3.35% |
| `code_cpp` | 88.75 tok/s | 90.92 tok/s | +2.45% |
| `explain_concept` | 89.20 tok/s | 90.50 tok/s | +1.46% |
| `summarize` | 89.26 tok/s | 91.14 tok/s | +2.11% |
| `qa_factual` | 89.49 tok/s | 91.01 tok/s | +1.69% |
| `translation` | 91.14 tok/s | 90.91 tok/s | -0.26% |
| `creative_short` | 88.92 tok/s | 90.88 tok/s | +2.19% |
| `stepwise_math` | 89.53 tok/s | 91.14 tok/s | +1.80% |
| `long_code_review` | 89.36 tok/s | 89.28 tok/s | -0.09% |

## Notes

- This benchmark measures real HTTP `/completion` latency including network round-trip within the host.
- The benchmark reuses the repo env file as the single source of truth for `LLAMA_ARG_*` runtime settings.
- The candidate image is compared against the official llama.cpp image as the baseline.
- `n_predict=192`, `temperature=0.0`, `seed=42`, `cache_prompt=false` across all requests.
- Raw artifacts: `results/baseline.json`, `results/candidate.json`, and both `docker inspect` outputs.
