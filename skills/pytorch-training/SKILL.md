---
name: pytorch-training
description: PyTorch model-building conventions and a neural-net training debug checklist. Use this skill whenever writing or reviewing PyTorch code that defines a model (nn.Linear, nn.Conv2d, BatchNorm) or trains one (training loop, optimizer, LR schedule), and ESPECIALLY when debugging training problems — loss not converging, loss stuck or flat, suspiciously slow learning, "hockey stick" loss curves, or a model that seems to ignore its inputs. Also consult it before starting any from-scratch training run, even if the user doesn't mention debugging.
---

# PyTorch Training

## Model-building conventions

- Set `bias=False` on any `nn.Linear`/`nn.Conv2d` immediately followed by `BatchNorm` — BN's mean-subtraction + learnable `beta` cancels the bias, making it dead params. Keep `bias=True` (default) on the output/classifier head, which has no BN after it.

## Neural net training checklist (common mistakes if skipped)

Run through these before and during any training run — each one catches a class of silent bug that wastes full training runs:

1. **Overfit a single batch first.** Before full training, verify the model can drive loss to ~0 on one small batch — if it can't, there's a bug in the model/loss/data pipeline; no point training on the full set.
2. **Verify loss @ init.** Check the starting loss equals the theoretical value — softmax over `n` classes should give `-log(1/n)` (e.g. ~2.30 for 10 classes). A mismatch means a bad head init or mislabeled targets.
3. **Input-independent baseline.** Train once with inputs zeroed out; the model must do *worse* than with real inputs. If they match, the data pipeline isn't actually feeding the model (it's only learning the prior).
4. **Init the output-layer bias to data statistics.** Regression with mean 50 → init bias 50; class imbalance 1:10 → set logit bias so p≈0.1 at init. Kills the "hockey stick" loss curve where early steps just learn the bias.
5. **Visualize the exact tensor right before `y_hat = model(x)`.** Decode what actually enters the net — the only source of truth for catching preprocessing/augmentation bugs (e.g. forgetting to flip labels when flipping images).
6. **Don't trust LR-decay defaults; use a constant LR and tune it last.** Borrowed code often decays by epoch number (e.g. ImageNet decays at epoch 30) — on a smaller dataset this silently drives the LR to ~0 before the model converges.
