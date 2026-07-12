# Feature preservation

Do not remove default-on gameplay or Expand-gated (`FEATURE_*` default false) systems.

| Safe to delete | Rule |
|----------------|------|
| Dead data / orphans | Zero readers in production **and** `harness/` (`rg` proof) |
| Always-on flag scaffolding | Only after harness no longer needs off-path + `PHASE0: PASS` |

`harness/` is regression/soak only — suites stay on disk; do not delete for “simplicity.”
