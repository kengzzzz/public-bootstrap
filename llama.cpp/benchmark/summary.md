# llama.cpp benchmark summary

- Timestamp (UTC): `2026-05-16T15:21:48Z`
- Host: `x86_64`
- CPU threads: `32`
- GPU: `NVIDIA GeForce RTX 4070 Ti SUPER, 16376 MiB, 595.71.05`
- Baseline VRAM (used/peak): `13079` / `13089` MiB
- Candidate VRAM (used/peak): `13079` / `13089` MiB
- Model: `/models/hf-home/hub/models--unsloth--Qwen3.6-35B-A3B-GGUF/snapshots/a483e9e6cbd595906af30beda3187c2663a1118c/Qwen3.6-35B-A3B-UD-Q6_K.gguf`
- Baseline image: `ghcr.io/ggml-org/llama.cpp@sha256:111681c55c83007572032ba96134f81b809b71a0a652cd70595298c6976d0276`
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
- CPU MoE threads: `27`
- mmap: `off`

## Aggregate

| Metric | Baseline | Candidate | Delta |
| --- | ---: | ---: | ---: |
| Total predicted tokens | 1,419 | 1,419 | +0 |
| Total wall time (s) | 23.03 | 22.65 | -1.65% |
| Aggregate throughput | 61.62 tok/s | 62.65 tok/s | +1.68% |

## Per-prompt results

| Prompt | Baseline tok/s | Candidate tok/s | Delta |
| --- | ---: | ---: | ---: |
| `code_python` | 68.59 tok/s | 70.17 tok/s | +2.30% |
| `code_cpp` | 68.69 tok/s | 70.39 tok/s | +2.47% |
| `explain_concept` | 68.76 tok/s | 70.49 tok/s | +2.52% |
| `summarize` | 69.16 tok/s | 69.99 tok/s | +1.20% |
| `qa_factual` | 69.15 tok/s | 69.87 tok/s | +1.04% |
| `translation` | 70.83 tok/s | 71.90 tok/s | +1.51% |
| `creative_short` | 68.93 tok/s | 69.71 tok/s | +1.13% |
| `stepwise_math` | 68.91 tok/s | 69.68 tok/s | +1.11% |
| `long_code_review` | 68.57 tok/s | 70.03 tok/s | +2.12% |

## Notes

- This benchmark measures real HTTP `/completion` latency including network round-trip within the host.
- The benchmark reuses the repo env file as the single source of truth for `LLAMA_ARG_*` runtime settings.
- The candidate image is compared against the official llama.cpp image as the baseline.
- `n_predict=192`, `temperature=0.0`, `seed=42`, `cache_prompt=false` across all requests.
- Raw artifacts: `results/baseline.json`, `results/candidate.json`, and both `docker inspect` outputs.
