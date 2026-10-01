class_name ScarSeveranceTests

extends ScarTestBase

## Scar deepening + severance: deepen is scar-only, scar increases severance
## ease, and severance mint releases prior medical state.

## Deepen is scar-only (plan §9.6): the post-victory tier-RNG bone afflictions share campaign_afflictions
## and carry a `part`, but a repeated roll must keep plain id+part dedup — never silently stacking
## damage_mult the way a wound-derived scar deepens. Gates on the `is_wound_scar` source marker.


static func _run_scar_deepen_is_scar_only(failures: PackedStringArray) -> void:
    var ent: Node = _new_entity("SWORD")
    var rng_def: Dictionary = {
        "id": CampaignAfflictions.AFFLICTION_LIMPING_LIMB,
        "label": "Limping left_leg",
        "part": "left_leg",
        "stamina_mult": 0.92,
        "pain_mult": 1.0,
        "damage_mult": 1.0,
        "heal_mult": 1.0,
    }
    if not ent._add_campaign_affliction(rng_def):
        _fail(failures, "scar_only: RNG bone affliction should add first time")
    if ent._add_campaign_affliction(rng_def):
        _fail(failures, "scar_only: repeated RNG bone affliction should id+part dedup, not deepen")
    if ent.campaign_afflictions.size() != 1:
        _fail(failures, "scar_only: RNG re-roll should leave 1 entry (got %d)" % ent.campaign_afflictions.size())
    var d_first: float = float(ent.campaign_afflictions[0].get("damage_mult", 1.0))
    var h_first: float = float(ent.campaign_afflictions[0].get("heal_mult", 1.0))
    if absf(d_first - 1.0) > 1e-9:
        _fail(failures, "scar_only: RNG re-roll must not deepen damage_mult (got %.3f)" % d_first)
    if absf(h_first - 1.0) > 1e-9:
        _fail(failures, "scar_only: RNG re-roll must not deepen heal_mult (got %.3f)" % h_first)
    # A wound-derived scar on the same part still deepens (the flag path is alive).
    var scar: Dictionary = CampaignAfflictions.scar_def(CampaignAfflictions.SCAR_MALUNITED_BONE, "left_leg")
    ent._add_campaign_affliction(scar)
    var d_once: float = ent._get_scar_damage_mult("left_leg")
    ent._add_campaign_affliction(CampaignAfflictions.scar_def(CampaignAfflictions.SCAR_MALUNITED_BONE, "left_leg"))
    var d_twice: float = ent._get_scar_damage_mult("left_leg")
    if not (d_twice > d_once):
        _fail(failures, "scar_only: wound-derived scar deepen should still fire (%.3f vs %.3f)" % [d_twice, d_once])
    _free_entity_fixture(ent)


## A scarred part severs more easily than healthy tissue (scar tissue shears at ~70-80% of normal
## tensile strength — same anchor as the re-injury bump). The severance ease factor is higher for an
## otherwise-identical part carrying a wound-derived scar.


static func _run_scar_increases_severance_ease(failures: PackedStringArray) -> void:
    var clean: Node = _new_entity("SWORD")
    var scarred: Node = _new_entity("SWORD")
    _seed_scar(scarred, CampaignAfflictions.SCAR_SCARRED_TISSUE, "left_leg")
    var ease_clean: float = EntityDamage.get_severance_ease_factor(clean, "left_leg")
    var ease_scar: float = EntityDamage.get_severance_ease_factor(scarred, "left_leg")
    if not (ease_scar > ease_clean):
        _fail(
            failures,
            "scar_sever: scarred part should sever more easily (scar %.3f vs clean %.3f)" % [ease_scar, ease_clean]
        )
    _free_entity_fixture(clean)
    _free_entity_fixture(scarred)


## A combat severance mints a stump the same way surgery does, so it must also release the limb's
## prior medical state: the clamp/dressings described the OLD wound channel the stump replaces.
## Left on, an already-stale clamp (past ITS max duration) "expires" the very next healing tick and
## latches had_ischemia onto the STUMP -- a phantom Volkmann grip on a limb the strike just removed
## -- and the old bandage/packing reads as definitive hemostasis for a brand-new bleeding stump,
## starving it of care. The release invariant lives at the mint (ensure_stump_wound); this is the
## dismemberment twin of the surgical-amputation practice.


static func _run_severance_mint_releases_prior_medical_state(failures: PackedStringArray) -> void:
    var ent: Node = _new_entity("SWORD")
    var part: String = "right_arm"
    ent.wounds[part] = [
        {
            "severity": BleedingConstants.SEVERITY_SEVERE,
            "current_bleeding_rate": 0.5,
            "base_bleeding_rate": 0.5,
            "is_arterial": false,
            "is_stabilized": false,
            "created_at_game_time": 0.0,
            "healing_duration_seconds": 7200.0,
        }
    ]
    # Clamp applied long ago (already past its max-duration window the moment it runs), plus dressings.
    ent.tourniquet_applied[part] = {
        "applied_at": -(BleedingConstants.TOURNIQUET_MAX_DURATION_SECONDS + 60.0), "effectiveness": 1.0
    }
    ent.bandaged_parts[part] = true
    ent.packed_parts[part] = true
    # The strike destroys the limb exactly like apply_damage_split's severance: pools zeroed, stump mint.
    ent.body_cutting[part] = 0.0
    ent.body_blunt[part] = 0.0
    ent.bone_health[part] = 0.0
    EntityWounds.ensure_stump_wound(ent, part)
    var stump: Dictionary = ent.wounds.get(part, [{}])[0]
    if not bool(stump.get("is_stump", false)):
        _fail(failures, "sever_release: the destroyed limb should hold an amputation stump")
    if ent.tourniquet_applied.has(part):
        _fail(failures, "sever_release: a combat severance must release the prior clamp (stale TQ on a fresh stump)")
    if ent.bandaged_parts.get(part, false):
        _fail(
            failures, "sever_release: a combat severance must release the prior bandage (old dressing on a fresh stump)"
        )
    if ent.packed_parts.has(part):
        _fail(
            failures, "sever_release: a combat severance must release the prior packing (old packing on a fresh stump)"
        )
    # One tick: with the clamp gone there is nothing to "expire" -- the fresh stump must NOT latch
    # had_ischemia from the pre-severance clamp (phantom ischemic limb).
    ent._process_healing(1.0)
    stump = ent.wounds.get(part, [{}])[0]
    if bool(stump.get("had_ischemia", false)):
        _fail(
            failures,
            "sever_release: a released clamp must NOT latch ischemia onto the fresh stump (phantom ischemic limb)"
        )
    _free_entity_fixture(ent)
