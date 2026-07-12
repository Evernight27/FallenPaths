Stream: **Audit**. Find errors / duplication / anti-patterns. Fix **clear bugs only**; defer structural work.

Bundle chat 2: [`README#project-health-bundle`](README.md#project-health-bundle) (after Hygiene).

**Gate:** `./scripts/run_all_combat_checks.sh` + company checks → **`PHASE0: PASS`** + company OK.

**Own:** greps, harness fails, calibration, minimal fixes (typos, dead imports, wrong API sites).

**Do not:** `.f5_soak_in.txt` · closed gates · pick-pipeline refactor · new `FEATURE_*`.

**Read first:** [`AGENTS_API#anti-patterns`](../../docs/AGENTS_API.md#anti-patterns) · [`LIVE_PATHS#harness-prefixes`](../../docs/LIVE_PATHS.md#harness-prefixes).

**Contract:** [`README#session-contract`](README.md#session-contract).

---

## Session start

> Phase 0 + company. Grep anti-patterns. ≤1 trivial fix or deliver FINDING report.

| P | Audit |
|:-:|-------|
| 1 | Phase 0 / harness |
| 2 | Calibration mode |
| 3 | `entity_has_untreated_wounds` / raw `pack_wound` |
| 4 | `manager._get_by_id` |
| 5 | Bridge `_tile_coords` / wound helper dups |
| 6 | `print("[Combat]")` outside `CombatDebug` |
| 7 | `get_stance_modifier` production → `CombatWeaponForm.mod` |
| 8 | `check_doc_links.py` |
| 9 | Medical harness mode |
| 10 | Move-id string literals in production `combat/*.gd` |

```
FINDING: …
SITES: …
CANONICAL: …
FIX: fixed | defer → <stream>
```

PR prefix: `audit:` or `chore:`.
