class_name CampaignTypes
extends RefCounted

## Shared types/constants between CompanyState and CampaignEncounterBridge to break their circular preload dependency.
## Both modules can preload this file without creating a cycle.
## Other modules that need these constants should also preload CampaignTypes instead of the original files.

# Default camp tile position on overworld grid (single source of truth  -  both CompanyState and CampaignEncounterBridge
# reference this).
const DEFAULT_CAMP_TILE: Vector2i = Vector2i(0, 0)

## Default company mood value used when a member has no explicit mood entry (fallback for averages).
const MOOD_DEFAULT: float = 50.0

# World meta keys (aligned with CompanyState.WORLD_META_*  -  single source of truth)
const WORLD_META_COMPANY_STATE: String = "company_state"
const WORLD_META_ACTIVE_CONTRACT: String = "active_contract"
const WORLD_META_LAST_BATTLE_SUMMARY: String = "last_battle_summary"
const WORLD_META_BATTLE_KILL_LOG: String = "campaign_battle_kill_log"
const WORLD_META_COMPANY_HUD: String = "company_hud"
## XCamp-5f: strongest opponent's effective strength, captured at combat start. Enemy nodes are
## freed at settlement, so this is the only reliable source for per-fighter fame (desirable difficulty).
const WORLD_META_FOE_STRENGTH: String = "last_battle_foe_strength"
## XCamp-5f: "Name: OldTier → NewTier" notes for fighters who climbed a career tier on the last
## paid win. Re-set by each fame award; the settlement panel shows it (empty = no promotions).
const WORLD_META_LAST_FAME_PROMOTIONS: String = "last_fame_promotions"
