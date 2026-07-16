# harness/

Regression / D001 / F5 validators / calibration. Not production resolvers.

Phase 0: `./scripts/run_all_combat_checks.sh` · Windows: `.\scripts\run_all_combat_checks.ps1`

Production tracer: `../combat/CombatF5SoakTrace.gd`

## Root files

| File | Purpose |
|------|---------|
| `CombatF5SoakLogValidator.gd` | F5 soak log parser/validator for D-001/II-2 grep sign-offs |
| `CombatQTrackAudits.gd` | Headless quality-track audit runner (Q1–Q4) |
| `HarnessFixtures.gd` | Shared combat harness fixtures, setup helpers, cleanup, assertions |

## Subdirs

| Dir | Contents |
|-----|----------|
| `regression/` | Core regression harness + subsystem tails (formation, kinematic, mental_stack, soak_fp) |
| `tier1/` | Tier-1 tactical tests (depth-polearm, encounter, envelop, flee, sparse-line, surround, swap-rank) |
| `d001/` | D-001 soak runner, sanity, track specs, needle profiles |
| `calibration/` | Calibration audits (bleeding-parry, impact-KE) |
| `attention_footwork/` | Attention/footwork/AI weapon-form/UI snapshot tests |
| `feint_tempo/` | Feint/counter-tempo/guard-zone tests |
| `medical_phase/` | Medical coordination/treatment/mobility/phase-gate tests |
| `proficiency/` | Proficiency award persistence/decay/merge tests |
| `weapon_form/` | Weapon-form assignment/gauge tests |
| `simulation/` | Simulation combat/material/research tests |
