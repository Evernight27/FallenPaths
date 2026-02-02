# Weapon Attack Patterns and Physics Numbers – Inspection

Review of each weapon’s definitions, attack patterns, and physics for consistency and realism (vs REAL_WORLD_COMPARISON.md and design intent).

---

## 1. Physics constants (global)

| Constant | Value | Verdict |
|----------|--------|---------|
| J_PER_MM_RHA | 130 | **OK** – scaled for 6–18 m/s; research ~47–55 J/mm base. |
| VELOCITY_MIN/MAX_M_S | 6 / 18 | **OK** – research 17–24 m/s; game band is conservative. |
| DAMAGE_KE_SCALE | 2.6 | **OK** – tuned with velocity. |
| CONTACT_AREA_EXPONENT | 0.5 | **OK** – penetration vs contact. |
| CONTACT_DAMAGE_EXPONENT | 0.3 | **OK** – damage vs contact. |
| CONTACT_DAMAGE_FACTOR_MAX | 2.0 | **OK** – caps stab overscale. |
| MIN_CONTACT_WIDTH_CM | 0.2 | **OK** – avoids div-by-zero; 0.2 cm = 2 mm. |
| BLUNT_PRESSURE_SCALE | 500 | **OK** – game-relative. |
| PENETRATION_KE_CAP_MM_RHA | 15 | **OK** – limits extreme penetration. |

No changes recommended for global physics.

---

## 2. Sword

| Field | Value | Notes |
|-------|--------|------|
| mass | 1.2 kg | **Accurate** – arming / light longsword. |
| blade_width | 2.0 cm | **Reasonable** – effective slash contact. |
| point_width | 0.5 cm | **Reasonable** – thrust contact. |
| head_diameter | 0.0 | **Issue** – blunt = pommel; 0 → clamped to 0.2 cm. Pommel is ~2–3 cm. |
| blade_cut_ratio | 0.75 | **OK** – 75% cut / 25% blunt. |
| stab | cooldown 2.2, ARCHETYPE_STAB | **OK** – full velocity, full commitment. |
| cut | cooldown 2.2, ARCHETYPE_SLASH | **OK** – 0.9 velocity, 2.2 s. |
| blunt | cooldown 1.8, ARCHETYPE_POMMEL | **OK** – quick, 0.7 velocity, 5% cut. |

**Fixes:** Use a sensible pommel contact when `head_diameter == 0` and attack is blunt (see code).

---

## 3. Axe

| Field | Value | Notes |
|-------|--------|------|
| mass | 1.5 kg | **Accurate** – one-handed battle axe. |
| blade_width | 3.0 cm | **Reasonable** – chop edge. |
| point_width | 0.8 cm | **Reasonable** – spike if present. |
| head_diameter | 0.0 | **Issue** – blunt = poll/back; 0 → 0.2 cm. Poll often ~3–5 cm. |
| blade_cut_ratio | 0.6 | **OK** – thicker blade, more blunt. |
| stab | cooldown 3.2, ARCHETYPE_STAB | **OK** – slower than sword. |
| cut | cooldown 3.5, ARCHETYPE_OVERHEAD | **OK** – big commitment, 1.2 recovery, 1.15 windup. |
| blunt | cooldown 3.0, ARCHETYPE_HEAVY_BLUNT | **OK** – poll strike. |

**Fixes:** Same as sword – blunt contact when `head_diameter == 0` (e.g. poll ~4 cm).

---

## 4. Mace

| Field | Value | Notes |
|-------|--------|------|
| mass | 1.7 kg | **Accurate** – typical war mace. |
| blade_width | 0.0 | N/A – no edge. |
| point_width | 0.0 | N/A – no point. |
| head_diameter | 8.0 cm | **Reasonable** – head size. |
| blade_cut_ratio | 0.0 | **OK** – all blunt. |
| stab | cooldown 3.0, ARCHETYPE_STAB | **Inaccurate** – maces are not used for stabbing. |
| cut | cooldown 3.2, ARCHETYPE_SLASH | **Inaccurate** – maces do not cut. |
| blunt | cooldown 3.5, ARCHETYPE_HEAVY_BLUNT | **OK** – correct primary attack. |

**Issue:** Stab and cut are in `attack_types`, so combat can pick “mace stab” or “mace cut”. That uses contact 0 → 0.2 cm and sharp damage type, which is physically wrong.

**Fix:** Restrict mace to blunt only: remove `stab` and `cut` from the mace weapon definition so `get_available_attack_types()` returns only `["blunt"]`.

---

## 5. Dagger

| Field | Value | Notes |
|-------|--------|------|
| mass | 0.3 kg | **Accurate** – medieval dagger range. |
| blade_width | 1.5 cm | **Reasonable** – narrow edge. |
| point_width | 0.3 cm | **Reasonable** – point. |
| head_diameter | 0.0 | **OK** – pommel uses fallback if added. |
| blade_cut_ratio | 0.9 | **OK** – slim blade, mostly cut. |
| stab | cooldown 0.7, ARCHETYPE_STAB | **OK** – fast, full velocity. |
| cut | cooldown 0.6, ARCHETYPE_QUICK_SLASH | **OK** – 0.65 velocity, very fast. |
| blunt | cooldown 0.5, ARCHETYPE_POMMEL | **OK** – very fast pommel. |

No inaccuracies; optional pommel contact fallback as for sword.

---

## 6. Spear

| Field | Value | Notes |
|-------|--------|------|
| mass | 1.8 kg | **Accurate** – one-/two-handed spear. |
| blade_width | 2.5 cm | **Reasonable** – head width for slash. |
| point_width | 0.6 cm | **Reasonable** – point. |
| head_diameter | 0.0 | **OK** – butt strike would use fallback. |
| blade_cut_ratio | 0.85 | **OK** – point-focused, some slash. |
| stab | cooldown 3.0, ARCHETYPE_STAB | **OK** – primary attack. |
| cut | cooldown 2.8, ARCHETYPE_SLASH | **OK** – secondary. |
| blunt | cooldown 2.5, ARCHETYPE_HEAVY_BLUNT | **OK** – butt/spike; contact fallback if desired. |

No inaccuracies.

---

## 7. Attack archetypes

| Archetype | velocity_factor | cut_ratio | recovery_mult | windup_mult | Verdict |
|-----------|------------------|-----------|---------------|-------------|---------|
| stab | 1.0 | -1 (weapon) | 1.0 | 1.0 | **OK** – full commitment thrust. |
| slash | 0.9 | -1 (weapon) | 1.0 | 1.0 | **OK** – slightly less than overhead. |
| overhead | 1.0 | -1 (weapon) | 1.2 | 1.15 | **OK** – big windup/recovery. |
| quick_slash | 0.65 | -1 (weapon) | 0.85 | 0.8 | **OK** – fast, less KE. |
| pommel_strike | 0.7 | 0.05 | 0.9 | 0.85 | **OK** – short lever, 5% cut. |
| heavy_blunt | 1.0 | 0.05 | 1.15 | 1.1 | **OK** – full swing, 5% “skin break”. |

Archetypes are consistent; no changes needed.

---

## 8. Summary of fixes

1. **Mace:** Remove `stab` and `cut` from the mace definition so only `blunt` is available. **Done** — mace uses only blunt moves (overhead_strike, side_strike, direct_blow, parry_strike).
2. **Pommel/poll contact:** When attack type is blunt and `head_diameter <= 0`, use a fallback contact in `Weapon.get_contact_width()` (BLUNT_FALLBACK_CONTACT_CM = 3.0 cm). **Done.**

---

## 9. Move-based movesets (per-weapon appropriateness)

Weapons now use explicit move IDs from a global move pool. Each weapon’s moves have been checked for historical/HEMA appropriateness:

| Weapon | Moves | Appropriateness |
|--------|--------|------------------|
| **SWORD** | thrust, oberhau, unterhau, slash, pommel_strike, parry_thrust, parry_cut | Thrust + cuts (Oberhau/Unterhau/Zwerchau-style) + pommel + parry-riposte — Liechtenauer/KDF. ✓ |
| **AXE** | spike_thrust, overhead_chop, diagonal_chop, poll_strike, parry_chop | Spike, chops, poll (back of head), parry-chop — battle axe / Le Jeu de la Hache. ✓ |
| **MACE** | overhead_strike, side_strike, direct_blow, parry_strike | Blunt only; no stab/cut. ✓ |
| **DAGGER** | quick_thrust, committed_thrust, quick_slash, dagger_pommel, parry_thrust_dagger | Thrusts (including armor-piercing), slash, pommel, parry-thrust — Fiore/Talhoffer. ✓ |
| **SPEAR** | spear_thrust, off_line_thrust, spear_slash, pole_swing, parry_thrust_spear | Thrusts, spearhead slash, pole swing (shaft), parry-thrust — Fiore. Beat-and-thrust removed. ✓ |

All move IDs in each weapon’s `moves` array exist in the move pool and match the weapon’s capabilities (e.g. mace has no stab/cut moves).
