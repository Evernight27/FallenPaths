# Combat packages

Purpose-named subdirs under `combat/`. Root holds orchestration hubs only:

| Hub | Role |
|-----|------|
| `CombatManager.gd` | Signals, register, start/stop, tick entry |
| `TacticalCombat.gd` | Encounter/tactical helpers used across packs |
| `CombatConstants.gd` | Public constants facade (`CombatConstants.X`) |
| `CombatDebug.gd` | Session / flow / medical log tiers |
| `CombatUiHints.gd` / `CombatPlayerTurnHints.gd` | Battle UI copy + turn hints |

| Package | Owns |
|---------|------|
| [`access/`](access/) | Combatant dict / entity / manager bridges; register + typed view |
| [`ai/`](ai/) | Action listing, mental stack, weighted pick, targeting |
| [`constants/`](constants/) | Literal / flag modules re-exported by facade |
| [`engagement/`](engagement/) | Engagement mode, pair geometry, opposition |
| [`flow/`](flow/) | Event queue, process tick, resolve, state handlers, stamina/fatigue |
| [`formation/`](formation/) | Slots, vacancy plugs, doctrine, ZoC, retreat/rout |
| [`medical/`](medical/) | Medical phase, coordination, wind-up / listing |
| [`soak/`](soak/) | F5 soak tracer (production tracer; harness validates logs) |
| [`strike/`](strike/) | Wind-up → attack resolve → defense → post-strike |
| [`weapon_form/`](weapon_form/) | WF, footing PA, guard line writers |

Architecture: [`../docs/ARCHITECTURE.md`](../docs/ARCHITECTURE.md) · Bridge: [`../docs/BRIDGE_CONTRACT.md`](../docs/BRIDGE_CONTRACT.md)
