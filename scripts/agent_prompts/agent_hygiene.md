Stream: **Hygiene**. Repo cleanup — delete unnecessary files, fix ignore rules, resolve Windows path duplicates. **No gameplay logic changes** unless a duplicate file is the only copy of real code (escalate to Audit or Combat).

Bundle: [project health `#project-health-bundle`](README.md#project-health-bundle) chat 1. Run **before** Audit when both are scheduled.

**Gate before done:**

```powershell
.\scripts\run_all_combat_checks.ps1
.\scripts\run_company_state_checks.ps1
```

Target: **`PHASE0: PASS`** + `FP_HARNESS_OK`. If hygiene only touches docs/scripts/artifacts (no `.gd` deletions), skip harness re-runs after edits and confirm `git status` has no accidental removals of tracked production code.

**Own:** `.gitignore`, untracked duplicates, editor artifacts, stale prompt/doc mirrors, `scripts/README.md` inventory rows.

**Read first:** [`AGENTS.md`](../../AGENTS.md) code homes · [`docs/PLANNING.md#file-ownership`](../../docs/PLANNING.md#file-ownership) · [`scripts/README.md`](../README.md) on-disk script inventory.

**Do not touch:** `combat/*`, `world/*`, `core/*` production `.gd` (except proven byte-identical dupes after `git diff`).

**Do not:** commit `.f5_soak_in.txt` (Playtest exclusive) · commit `.phase0_combat_checks.txt`, `.d001_*`, or `.godot/` cache · run `git clean -fd` repo-wide · delete tracked files without grepping for callers · edit production logic in `.gd` files.

---

## Session start (copy-paste task line)

> Audit the repo for deletable cruft. List every deletion before removing. Fix `.gitignore` gaps. Resolve Windows `Foo.gd` vs `Foo.gd` path mirrors. Hand off to Audit if two copies differ. Gate: **`PHASE0: PASS`**.

---

## Priority table

| P | Task | How |
|:-:|------|-----|
| 1 | **Windows path duplicates** | `combat/Foo.gd` (tracked) + `combat\Foo.gd` (untracked) — keep forward-slash tracked path, remove backslash mirror; same for `scripts/` |
| 2 | **Godot / IDE artifacts** | Ensure `.godot/`, `*.import` sidecars (if policy), `*.tmp` in `.gitignore`; delete untracked `.godot/` only |
| 3 | **Playtest artifacts** | Confirm `.f5_soak_in.txt`, `.phase0_*`, `.d001_*`, `.harness_out.txt`, `.audit_*.txt` gitignored per `scripts/README.md` |
| 4 | **VS Code dupes** | Single `.vscode/settings.json` / `tasks.json` |
| 5 | **Stale script inventory** | `scripts/README.md` rows match on-disk `scripts/*`; remove doc refs to deleted runners (`run_d001_presets*`) |
| 6 | **Orphan prompt files** | One home per stream: `agent_*.md` in `scripts/agent_prompts/`; delete unlinked stubs; specialty sections live in `agent_combat.md` (not separate files) |
| 7 | **Doc tombstones** | `python3 scripts/check_doc_links.py --res-paths-only` (also in Phase 0); dead links → fix or tombstone row in [`LIVE_PATHS#redirects-tombstones`](../../docs/LIVE_PATHS.md#redirects-tombstones) |
| 8 | **Untracked scripts** | Legitimate new `?? scripts/*` → `git add` + row in `scripts/README.md`; never delete without `rg` for imports/callers |

---

## Deletion safety

- Never `git clean -fd` repo-wide.
- List every path in the PR / chat summary before deleting.
- If two copies **differ**, stop — report `PATH_A` / `PATH_B` / diff summary to **Audit**.
- Grep before delete: `rg -l '<filename>'` for scripts; `rg '<ClassName>'` for `.gd` orphans.
- After deletions: `git status` — no accidental removal of tracked `combat/`, `world/`, `core/`.

**Escalation:** if you find two copies that differ, stop and report `PATH_A` / `PATH_B` / diff summary to **Audit**. Do not guess which copy is canonical.

**If gate was green at start but fails after your change:** revert any `.gd` edits (you should have none), re-run gate to confirm, then report with FINDING/SITES/CANONICAL/FIX format if the failure is structural rather than a file you deleted.

**Success:** no spurious `?? combat\*.gd` or `?? scripts\*.ps1` mirrors · artifacts gitignored · Phase 0 PASS (or hand off to Audit).

PR prefix: `hygiene:` or `chore:`.
