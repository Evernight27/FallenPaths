class_name CombatantRegister
extends RefCounted

## Builds the initial combatant dictionary for `CombatManager.register`.
## New keys: add here + `CombatantFieldRegistry` + document writers.


static func build_initial(
    id: int,
    node: Node,
    side: String,
    stats: Dictionary,
    campaign_stamina_mult: float,
    morale_cohesion: float,
    stance_preference: String,
    leader_flags: Dictionary,
) -> Dictionary:
    return {
        "id": id,
        "node": node,
        "side": side,
        "stats": stats,
        "gauge": 0.0,
        "alive": true,
        "state": CombatConstants.STATE_WAITING,
        "state_timer": 0.0,
        "state_duration": 0.0,
        "pending_attack": {},
        "receiving_medical_count": 0,
        "guard": 1.0,
        "guard_line": CombatConstants.GUARD_DEFAULT,
        "guard_zone": BodyPartConstants.PART_HEAD,
        "stamina": CombatConstants.STAMINA_MAX,
        CombatConstants.COMBATANT_KEY_EXHAUSTION: 0.0,
        CombatConstants.COMBATANT_KEY_EXHAUSTION_FP_BAND_LOGGED: -1,
        # FF4 formation fields (Phase 0). Phase 3 assigns rank/file.
        "rank": 0,
        "file": 0,
        "formation_id": "",
        "distance_to": {},
        "engaged_with_id": -1,
        "engagement_angle": "front",
        "zone_id": "",
        "occupied_zone_id": "",
        "stance": CombatConstants.STANCE_BALANCED,
        "stance_preference": stance_preference,
        "engagement_role": CombatConstants.ENGAGEMENT_ROLE_LINE,
        "lane_offset": CombatConstants.LANE_OFFSET_DEFAULT,
        "doctrine_target_commit_id": -1,
        "doctrine_commit_until": 0.0,
        "close_block_until_by_target_id": {},
        "is_party_leader": leader_flags.get("is_party_leader", false),
        "is_enemy_leader": leader_flags.get("is_enemy_leader", false),
        "morale_cohesion": morale_cohesion,
        "campaign_stamina_mult": campaign_stamina_mult,
        "ruthlessness": 50.0,
        "damage_dealt_by_id": {},
        "prisoner": false,
    }
