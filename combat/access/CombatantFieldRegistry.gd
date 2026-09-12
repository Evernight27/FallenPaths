class_name CombatantFieldRegistry
extends RefCounted

## Combatant dict key → owning package (and primary writers).
## Add a row when introducing a new register/runtime field.
## Canonical reads/writes: `CombatantEntityAccess` unless a specialist is listed.

const OWNER_ACCESS := "access"
const OWNER_FORMATION := "formation"
const OWNER_STRIKE := "strike"
const OWNER_FLOW := "flow"
const OWNER_WEAPON_FORM := "weapon_form"
const OWNER_MEDICAL := "medical"
const OWNER_ENGAGEMENT := "engagement"
const OWNER_AI := "ai"

## key -> { "owner": package, "writers": brief }
const FIELDS: Dictionary = {
    "id": {"owner": OWNER_ACCESS, "writers": "CombatantRegister"},
    "node": {"owner": OWNER_ACCESS, "writers": "CombatantRegister"},
    "side": {"owner": OWNER_ACCESS, "writers": "CombatantRegister"},
    "stats": {"owner": OWNER_ACCESS, "writers": "CombatantStatsSync"},
    "gauge": {"owner": OWNER_FLOW, "writers": "CombatStateHandlers · AttackWindUpStarter"},
    "alive": {"owner": OWNER_ACCESS, "writers": "CombatManager / death path"},
    "state": {"owner": OWNER_FLOW, "writers": "CombatStateHandlers · event dispatch"},
    "state_timer": {"owner": OWNER_FLOW, "writers": "CombatStateHandlers"},
    "state_duration": {"owner": OWNER_FLOW, "writers": "CombatStateHandlers"},
    "pending_attack": {"owner": OWNER_STRIKE, "writers": "AttackWindUpStarter · AttackResolver"},
    "receiving_medical_count": {"owner": OWNER_MEDICAL, "writers": "MedicalPhase / coordination"},
    "guard": {"owner": OWNER_STRIKE, "writers": "defense / post-strike"},
    "guard_line": {"owner": OWNER_WEAPON_FORM, "writers": "GuardLineUpdater"},
    "guard_zone": {"owner": OWNER_WEAPON_FORM, "writers": "focus / guard helpers"},
    "stamina": {"owner": OWNER_FLOW, "writers": "CombatExhaustion · CombatStateHandlers"},
    "breath": {"owner": OWNER_FLOW, "writers": "alias of stamina (legacy readers)"},
    "rank": {"owner": OWNER_FORMATION, "writers": "CombatFormationSetup · vacancy plugs"},
    "file": {"owner": OWNER_FORMATION, "writers": "CombatFormationSetup · vacancy plugs"},
    "formation_id": {"owner": OWNER_FORMATION, "writers": "CombatFormationSetup"},
    "distance_to": {"owner": OWNER_FORMATION, "writers": "ZoneOfControl"},
    "engaged_with_id": {"owner": OWNER_ENGAGEMENT, "writers": "CombatEngagementResolver"},
    "engagement_angle": {"owner": OWNER_ENGAGEMENT, "writers": "CombatEngagementResolver"},
    "zone_id": {"owner": OWNER_FORMATION, "writers": "ZoneOfControl"},
    "occupied_zone_id": {"owner": OWNER_FORMATION, "writers": "ZoneOfControl"},
    "stance": {"owner": OWNER_WEAPON_FORM, "writers": "legacy stance; prefer WF"},
    "stance_preference": {"owner": OWNER_AI, "writers": "campaign mood seed / Bridge"},
    "engagement_role": {"owner": OWNER_ENGAGEMENT, "writers": "CombatFormationEngagement"},
    "lane_offset": {"owner": OWNER_ENGAGEMENT, "writers": "CombatFormationEngagement"},
    "doctrine_target_commit_id": {"owner": OWNER_FORMATION, "writers": "CombatDoctrine"},
    "doctrine_commit_until": {"owner": OWNER_FORMATION, "writers": "CombatDoctrine"},
    "close_block_until_by_target_id": {"owner": OWNER_FORMATION, "writers": "close / ZoC"},
    "is_party_leader": {"owner": OWNER_ACCESS, "writers": "CombatantRegister from node"},
    "is_enemy_leader": {"owner": OWNER_ACCESS, "writers": "CombatantRegister from node"},
    "morale_cohesion": {"owner": OWNER_FLOW, "writers": "CombatMoraleCohesion"},
    "campaign_stamina_mult": {"owner": OWNER_ACCESS, "writers": "CombatantRegister from entity"},
    "ruthlessness": {"owner": OWNER_AI, "writers": "CombatantRegister (species seed) · CombatExecute"},
    "damage_dealt_by_id": {"owner": OWNER_STRIKE, "writers": "AttackResultApplier (ledger) · CombatExecute (reads)"},
    "prisoner": {"owner": OWNER_MEDICAL, "writers": "MedicalPhase / victory mop-up"},
}



