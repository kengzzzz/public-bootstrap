# llama.cpp benchmark summary

- Timestamp (UTC): `2026-05-16T01:48:16Z`
- Host: `x86_64`
- CPU threads: `32`
- GPU: `NVIDIA GeForce RTX 4070 Ti SUPER, 16376 MiB, 595.71.05`
- Baseline VRAM (used/peak): `13386` / `13419` MiB
- Candidate VRAM (used/peak): `13431` / `13397` MiB
- Model: `/models/hf-home/hub/models--unsloth--Qwen3.6-35B-A3B-GGUF/snapshots/a483e9e6cbd595906af30beda3187c2663a1118c/Qwen3.6-35B-A3B-UD-Q4_K_XL.gguf`
- Baseline image: `ghcr.io/ggml-org/llama.cpp@sha256:119e5a57abe7d5bf13133b7d190dd73e3e2eca8821217dd05b6077e92621d1d6`
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
| Total predicted tokens | 1,285 | 1,285 | +0 |
| Total wall time (s) | 16.53 | 16.32 | -1.27% |
| Aggregate throughput | 77.74 tok/s | 78.74 tok/s | +1.29% |

## Per-prompt results

| Prompt | Baseline tok/s | Candidate tok/s | Delta |
| --- | ---: | ---: | ---: |
| `code_python` | 85.13 tok/s | 87.69 tok/s | +3.00% |
| `code_cpp` | 88.14 tok/s | 89.34 tok/s | +1.37% |
| `explain_concept` | 86.43 tok/s | 87.31 tok/s | +1.02% |
| `summarize` | 87.49 tok/s | 88.91 tok/s | +1.62% |
| `qa_factual` | 87.60 tok/s | 88.80 tok/s | +1.37% |
| `translation` | 89.91 tok/s | 91.12 tok/s | +1.35% |
| `creative_short` | 85.75 tok/s | 87.12 tok/s | +1.60% |
| `stepwise_math` | 88.33 tok/s | 88.55 tok/s | +0.24% |
| `long_code_review` | 86.19 tok/s | 86.34 tok/s | +0.18% |

## Notes

- This benchmark measures real HTTP `/completion` latency including network round-trip within the host.
- The benchmark reuses the repo env file as the single source of truth for `LLAMA_ARG_*` runtime settings.
- The candidate image is compared against the official llama.cpp image as the baseline.
- `n_predict=192`, `temperature=0.0`, `seed=42`, `cache_prompt=false` across all requests.
- Raw artifacts: `results/baseline.json`, `results/candidate.json`, and both `docker inspect` outputs.
