Stream: **Hygiene**. Repo cleanup — deletes, ignore rules, path mirrors. **No gameplay `.gd`** unless proven byte-identical dupe (else escalate).

Bundle chat 1: [`README#project-health-bundle`](README.md#project-health-bundle).

**Gate:** Phase 0 + company if any `.gd` touched; docs/scripts-only → `git status` clean of accidental production deletes.

**Own:** `.gitignore`, untracked dupes, artifacts, prompt/doc mirrors, `tools/ci/README.md` inventory.

**Read first:** [`AGENTS.md`](../../../AGENTS.md) · [`FEATURE_PRESERVATION`](../../../docs/FEATURE_PRESERVATION.md) · [`PLANNING#file-ownership`](../../../docs/PLANNING.md#file-ownership).

**Do not:** commit soak/phase0/d001 artifacts · `git clean -fd` · delete without `rg` · edit production logic.

**Contract:** [`README#session-contract`](README.md#session-contract).

---

## Session start

> List deletions before removing. Fix `.gitignore`. Resolve Windows path mirrors. Hand differing copies to Audit.

| P | Task |
|:-:|------|
| 1 | Windows `Foo.gd` vs `Foo.gd` mirrors — keep tracked `/` path |
| 2 | Godot/IDE artifacts gitignored |
| 3 | Playtest artifacts ignored per `tools/ci/README.md` |
| 4 | Single `.vscode/` config |
| 5 | `tools/ci/README.md` matches on-disk |
| 6 | Orphan prompts — one `agent_*.md` home |
| 7 | Doc links: `python3 tools/ci/check_doc_links.py` · tombstones [`LIVE_PATHS#redirects-tombstones`](../../../docs/LIVE_PATHS.md#redirects-tombstones) |
| 8 | New `?? tools/ci/*` → add + inventory row |

**Deletion safety:** list paths · if copies differ → Audit · `rg` before delete.

PR prefix: `hygiene:` or `chore:`.
