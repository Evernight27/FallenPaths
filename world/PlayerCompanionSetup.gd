class_name PlayerCompanionSetup
extends RefCounted

## Assigns species, party boost, random equipment, and optional **`stance_preference`** to player and companions.
## Call before PartySetup so party UI snapshot has correct stats.

const COMPANION_STANCE_PREFS: Array[String] = [
    "plow",
    "wall",
    "balanced",
    "ox",
    "tempest",
    "wrath",
]

## Gladiator name pool. Index 0 = companion slot 1 ("Companion"), index 1 = "Companion2", etc.
## The player leader (node "Character") gets a fixed hero name.
const FIGHTER_NAMES: Array[String] = [
    "Brann",
    "Sola",
    "Kael",
    "Maren",
    "Dux",
    "Thessa",
    "Rook",
    "Vale",
    "Cyn",
    "Ora",
    "Bast",
    "Lira",
    "Dorn",
    "Sable",
]
const PLAYER_FIGHTER_NAME: String = "Ash"

## XCamp-4: per-stat proficiency bonus cap (bounds the profile-scaled rookie bonus in
## _profile_scaled_rookie_bonus).
const ROOKIE_PROFICIENCY_CAP: float = 10.0
## XCamp-4b: green-recruit baseline for a fresh hire (new to the company, not a literal zero).
## Kept below EntityProficiency.UNSKILLED_BONUS_THRESHOLD (5.0) so a hire still reads as "green".
const ROOKIE_HIRE_BASE_PROFICIENCY: float = 2.0
## How strongly a fighter's base-stat offset (vs the 100 baseline) skews their rookie proficiency
## profile. A stat 15 points above baseline gets +60% of the base rookie bonus in that stat.
const ROOKIE_PROFILE_OFFSET_PER_POINT: float = 0.4
## XCamp-4c: reputation payoff -- a famous company attracts better recruits. Renown raises the
## quality of a fresh hire: their base-stat roll gets a higher floor + ceiling + small mean lift,
## and their green-recruit proficiency baseline is lifted. Inert at renown 0 (a nameless company's
## hires roll exactly as before), so boot-time setup and the renown-0 harness path are unaffected.
## Stat-roll band: floor rises 85 -> 95, ceiling 115 -> 120, plus a mean lift up to +5.
const ROOKIE_HIRE_STAT_FLOOR_PER_RENOWN: float = 0.5
const ROOKIE_HIRE_STAT_FLOOR_CAP: int = 10
const ROOKIE_HIRE_STAT_CEIL_PER_RENOWN: float = 0.25
const ROOKIE_HIRE_STAT_CEIL_CAP: int = 5
const ROOKIE_HIRE_STAT_MEAN_LIFT_PER_RENOWN: float = 0.25
const ROOKIE_HIRE_STAT_MEAN_LIFT_CAP: int = 5
## Hire proficiency: renown lifts the green-recruit baseline so top-renown hires arrive with real
## skill instead of all reading "green". Capped below a full veteran (PROFICIENCY_VETERAN_MAX=20) so
## even the best fresh recruit still needs training. The 12.0 cap is above the untrained-holdback
## threshold (5.0) and above the proficient mark (10.0), so a peak-renown hire fights un-holdbacked
## and reads at least "Seasoned".
const ROOKIE_HIRE_PROFICIENCY_PER_RENOWN: float = 0.4
const ROOKIE_HIRE_PROFICIENCY_CAP: float = 12.0
## XCamp-4c: hire-cost multipliers by recruit quality tier (applied on top of HIRE_GOLD_COST).
## Green is 1.0x (== HIRE_GOLD_COST, unchanged for a nameless company). Trained/Seasoned recruits
## cost more because a famous company attracts experienced fighters, and they demand more pay.
const RECRUIT_COST_TRAINED_MULT: float = 1.375
const RECRUIT_COST_SEASONED_MULT: float = 1.75
## XCamp-4d: quality recruits bring their own kit. A Trained hire (renown>=8) arrives with a
## standard weapon; a Seasoned hire (renown>=20) arrives with that weapon plus a plate-grade
## head piece. A Green hire (renown 0) keeps the random starter gear from _setup_character, so the
## boot-time / renown-0 harness path is byte-for-byte unchanged.
const RECRUIT_KIT_WEAPON: String = "SWORD"
const RECRUIT_KIT_ARMOR_PART: String = "head"
const RECRUIT_KIT_ARMOR_ID: String = "KETTLE_HELM"
# Runtime preload ' circular dependency (CompanyState preloads PlayerCompanionSetup).
static var _company_state_cache: Variant = null


static func _get_company_state() -> GDScript:
    if _company_state_cache == null:
        _company_state_cache = load("res://world/CompanyState.gd")
    return _company_state_cache


## Fighter identity: a stable, human display name derived from the fighter's slot node name.
## Deterministic (same node -> same name) so it is stable across save/load with no persisted state:
## the player leader is a fixed hero name; companions map by slot index onto FIGHTER_NAMES.
## Returns the node name unchanged when no gladiator name applies (so unknown/legacy nodes still display).
static func fighter_display_name(node_name: String) -> String:
    if node_name == "Character":
        return PLAYER_FIGHTER_NAME
    if node_name.begins_with("Companion"):
        var suffix: String = node_name.substr("Companion".length())
        var slot: int = 0
        if not suffix.is_empty() and suffix.is_valid_int():
            slot = int(suffix) - 1
        slot = clampi(slot, 0, FIGHTER_NAMES.size() - 1)
        return FIGHTER_NAMES[slot]
    return node_name


## XCamp-4b: resolve a fighter's display name. Prefer their persisted gladiator name
## (entity.fighter_name); fall back to the deterministic slot-derived name for nodes without an
## assigned name (legacy saves, harness stubs, freshly re-instantiated slots).
static func resolve_fighter_display_name(node: Node) -> String:
    if node == null:
        return ""
    var entity: Node = node
    if node.has_method("_get_medical_entity"):
        var e: Variant = node._get_medical_entity()
        entity = e if e is Node else node
    if entity != null and "fighter_name" in entity:
        var fn: String = str(entity.get("fighter_name")).strip_edges()
        if not fn.is_empty():
            return fn
    return fighter_display_name(str(node.name))


## XCamp-4c: the per-stat proficiency base a fresh hire starts at, scaled by company renown and capped.
## Shared by the hire simulation (so the recruit actually arrives with this much skill) and the
## recruit-quality label / hire cost (so the player-facing label always matches the simulation).
static func recruit_proficiency_base(renown: int) -> float:
    return minf(
        ROOKIE_HIRE_BASE_PROFICIENCY + float(renown) * ROOKIE_HIRE_PROFICIENCY_PER_RENOWN,
        ROOKIE_HIRE_PROFICIENCY_CAP,
    )


## XCamp-4c: player-legible recruit quality, derived from the recruit's *actual* starting skill so the
## label is honest (never claims a tier the simulation does not grant). A famous company attracts better
## fighters (the stat/proficiency payoff in _roll_stat_variance / _setup_rookie_proficiency_hire); this
## makes that payoff visible to the player. Pure / read-only - no simulation or persistence.
## Tiers key off the per-stat proficiency base against the game's own rank thresholds:
##   Green    < 5.0  (below the untrained-holdback threshold: the recruit literally fights "green")
##   Trained  < 10.0 (proficient: no holdback, solid but not yet a campaign vet)
##   Seasoned  >= 10.0 (above the proficient mark; still below a full Veteran, who is earned through
##   service, not arrival - see ROOKIE_HIRE_PROFICIENCY_CAP)
static func recruit_quality_label(renown: int) -> String:
    var base: float = recruit_proficiency_base(renown)
    if base < float(EntityProficiency.PROFICIENCY_NOVICE_MAX):
        return "Green"
    if base < float(EntityProficiency.PROFICIENCY_PROFICIENT_MAX):
        return "Trained"
    return "Seasoned"


## XCamp-4c: gold cost of a fresh hire at a given company renown. Better recruits (higher quality
## tier) cost more - a famous company attracts experienced fighters, and experienced fighters demand
## more pay. Green is exactly HIRE_GOLD_COST, so a nameless company (renown 0) is unchanged and the
## XCamp-3.1 flat-cost harness path stays green. Multipliers are the only knobs a balancer tunes.
static func recruit_cost_for_renown(renown: int) -> int:
    var base_cost: int = int(_get_company_state().HIRE_GOLD_COST)
    var base: float = recruit_proficiency_base(renown)
    if base >= float(EntityProficiency.PROFICIENCY_PROFICIENT_MAX):
        return int(round(float(base_cost) * RECRUIT_COST_SEASONED_MULT))
    if base >= float(EntityProficiency.PROFICIENCY_NOVICE_MAX):
        return int(round(float(base_cost) * RECRUIT_COST_TRAINED_MULT))
    return base_cost


## Set a fighter's persisted gladiator name on the entity. No-op when the name is empty or the
## entity lacks the field (e.g. a bare harness stub).
static func _assign_fighter_name(character: Node, name: String) -> void:
    if character == null or name.is_empty():
        return
    var entity: Node = CampaignEncounterBridge.health_entity_from_character(character)
    if entity != null and "fighter_name" in entity:
        entity.fighter_name = name


## XCamp-4b: collect the gladiator names currently held by *living* party members, to avoid handing a
## fresh hire a name a living fighter already has. A fallen member (blood_volume <= 0) frees their name
## for reuse — the pool is small and the company grows, so recycling dead fighters' names is realistic.
static func gather_living_fighter_names(world: Node2D) -> PackedStringArray:
    var used: PackedStringArray = PackedStringArray()
    if world == null:
        return used
    var chars: Array = []
    var player: Node2D = CampaignEncounterBridge.get_player(world)
    if player != null:
        chars.append(player)
    for i in range(1, CombatConstants.FORMATION_UNIT_COUNT_HARD_CAP):
        var path: String = "Character/%s" % PartySetup._companion_node_name(i)
        if world.has_node(path):
            var c: Node = world.get_node_or_null(path)
            if is_instance_valid(c):
                chars.append(c)
    for c in chars:
        var entity: Node = CampaignEncounterBridge.health_entity_from_character(c)
        if entity == null or not "fighter_name" in entity:
            continue
        var nm: String = str(entity.get("fighter_name")).strip_edges()
        if nm.is_empty():
            continue
        var alive: bool = true
        if entity.has_method("is_dead"):
            alive = not entity.is_dead()
        if alive:
            used.append(nm)
    return used


## Pick a random gladiator name not in `used`. Returns "" when the whole pool is taken (the caller
## then falls back to the slot-derived name rather than forcing a duplicate among living members).
static func _roll_name(used: PackedStringArray, rng: RandomNumberGenerator) -> String:
    if rng == null:
        return ""
    var free: PackedStringArray = PackedStringArray()
    for n in FIGHTER_NAMES:
        if not used.has(n):
            free.append(n)
    if free.is_empty():
        return ""
    return free[rng.randi_range(0, free.size() - 1)]


## XCamp-4b: scale a flat per-stat rookie bonus by the fighter's individual base-stat profile so two
## rookies with the same company renown do not end up with identical skill spreads. A stat sitting
## above the 100 baseline skews that stat's rookie bonus up; below skews it down. Clamped to [0, cap].
static func _profile_scaled_rookie_bonus(entity: Node, stat: String, base: float) -> float:
    if base <= 0.0:
        return 0.0
    var s: int = 100
    if stat in entity:
        s = int(entity.get(stat))
    var offset: float = (float(s) - 100.0) / 15.0
    var factor: float = clampf(1.0 + offset * ROOKIE_PROFILE_OFFSET_PER_POINT, 0.6, 1.4)
    return clampf(base * factor, 0.0, ROOKIE_PROFICIENCY_CAP)


## XCamp-4b: green-recruit baseline for a fresh hire. A new-to-the-company recruit is not a literal
## zero but has little campaign experience yet; seed a small profile-shaped per-stat baseline so the
## hire shows a distinct (if low) skill spread. Stays below the untrained holdback threshold so the
## fighter still reads as green in combat.
## XCamp-4c: at higher company renown the recruit's baseline is lifted (see ROOKIE_HIRE_PROFICIENCY_*).
static func _setup_rookie_proficiency_hire(character: Node, renown: int = 0) -> void:
    if character == null:
        return
    if not _get_company_state().read_stub_proficiency_enabled():
        return
    var entity: Node = CampaignEncounterBridge.health_entity_from_character(character)
    if entity == null or not "_proficiency_bonus" in entity:
        return
    var base: float = recruit_proficiency_base(renown)
    for stat in EntityStatsUtil.PROFICIENCY_STATS:
        entity._proficiency_bonus[stat] = _profile_scaled_rookie_bonus(entity, stat, base)


## XCamp-4d: a quality recruit brings their own kit. The random starter gear from _setup_character is
## a proxy for "whatever they had on arrival"; a Trained recruit (renown>=8) is upgraded to a standard
## weapon, and a Seasoned recruit (renown>=20) additionally wears a plate-grade head piece. This makes
## the reputation payoff (XCamp-4c) tangible on the equipment axis too: pay more for a better recruit,
## and they arrive battle-ready with kit you would otherwise have to buy. Green recruits (renown<8) keep
## the random starter gear, so the boot-time / renown-0 harness path is unchanged. Gated on the same
## proficiency stub as the rest of the reputation payoff.
static func apply_recruit_kit(companion: Node, renown: int) -> void:
    if companion == null:
        return
    if not _get_company_state().read_stub_proficiency_enabled():
        return
    var quality: String = recruit_quality_label(renown)
    if quality == "Green":
        return
    if quality == "Trained" or quality == "Seasoned":
        var w: Weapon = Weapon.create_from_definition(RECRUIT_KIT_WEAPON)
        if w != null and companion.has_method("equip_weapon"):
            companion.equip_weapon(w)
    if quality == "Seasoned":
        var piece: ArmorPiece = ArmorPiece.create_from_definition(RECRUIT_KIT_ARMOR_ID)
        if piece != null and companion.has_method("equip_armor"):
            companion.equip_armor(RECRUIT_KIT_ARMOR_PART, piece)


## XCamp-3.1: fresh rookie on a vacant companion slot (species + tutorial-tier gear).
## `used_names` lets the caller avoid handing a new hire a name a living member already has.
## `world` enables the XCamp-4c reputation payoff: a higher-renown company's hires get a better
## stat roll and a higher proficiency baseline. Without it, hires roll as they always did.
static func setup_hired_companion(
    companion: Node,
    rng: RandomNumberGenerator,
    slot_index: int = 0,
    used_names: PackedStringArray = PackedStringArray(),
    world: Node2D = null
) -> void:
    if companion == null or rng == null:
        return
    companion.is_party_leader = false
    if companion.has_method("set_process_input"):
        companion.set_process_input(false)
    var renown: int = _get_company_state().get_renown(world) if world != null else 0
    _setup_character(companion, rng, true, slot_index, renown)
    # XCamp-4d: quality recruits bring tier-appropriate kit (standard weapon / + plate head).
    apply_recruit_kit(companion, renown)
    # XCamp-4: rookies are tracked so the combat skill curve / untrained holdback apply.
    _mark_combat_skill_trained(companion)
    # XCamp-4b: green-recruit baseline + a name that does not collide with a living member's name.
    _setup_rookie_proficiency_hire(companion, renown)
    var nm: String = _roll_name(used_names, rng)
    if nm.is_empty():
        nm = fighter_display_name(str(companion.name))
    _assign_fighter_name(companion, nm)


static func setup_player_and_companion(
    world: Node2D, rng: RandomNumberGenerator, randomize_equipment: bool = true
) -> void:
    var player: Node2D = CampaignEncounterBridge.get_player(world)
    if player == null:
        return
    player.is_party_leader = true
    _setup_character(player, rng, randomize_equipment)
    _mark_combat_skill_trained(player)
    _setup_rookie_proficiency_for_world(world, player)
    _assign_fighter_name(player, PLAYER_FIGHTER_NAME)

    var used: PackedStringArray = PackedStringArray([PLAYER_FIGHTER_NAME])
    for i in range(1, CombatConstants.FORMATION_UNIT_COUNT_HARD_CAP):
        var path: String = "Character/%s" % PartySetup._companion_node_name(i)
        if world.has_node(path):
            var companion: Node = world.get_node_or_null(path)
            if not is_instance_valid(companion):
                continue
            companion.is_party_leader = false
            companion.set_process_input(false)
            _setup_character(companion, rng, randomize_equipment, i - 1)
            _mark_combat_skill_trained(companion)
            _setup_rookie_proficiency_for_world(world, companion)
            var nm: String = _roll_name(used, rng)
            if nm.is_empty():
                nm = fighter_display_name(str(companion.name))
            _assign_fighter_name(companion, nm)
            used.append(nm)


static func _setup_character(
    character: Node, rng: RandomNumberGenerator, randomize_equipment: bool, companion_index: int = -1, renown: int = 0
) -> void:
    if ResourceLoader.exists(ResourcePaths.HUMAN_SPECIES):
        var human_res = load(ResourcePaths.HUMAN_SPECIES)
        if human_res != null and "species" in character:
            character.species = human_res
            if character.has_method("apply_species"):
                character.apply_species()
            if character.has_method("_apply_party_boost"):
                character._apply_party_boost()
            # XCamp-4: give each individual a slightly different stat profile so party
            # members are not identical clones of the species baseline.
            # XCamp-4c: hires at a higher-renom company roll from a better band.
            _roll_stat_variance(character, rng, renown)
    if randomize_equipment and character.has_method("equip_armor") and character.has_method("equip_weapon"):
        EncounterSpawner.equip_random_equipment(character, rng)
    if companion_index >= 0 and "stance_preference" in character:
        var pref: String = str(character.get("stance_preference")).strip_edges()
        if pref.is_empty():
            character.stance_preference = COMPANION_STANCE_PREFS[companion_index % COMPANION_STANCE_PREFS.size()]


## Dev soak: equip every party **`Character`** / **`Companion*`** with one weapon id (e.g. **`SWORD`** for II-2b).
static func equip_party_weapons(world: Node2D, weapon_id: String) -> void:
    if world == null or weapon_id.is_empty():
        return
    var player: Node2D = CampaignEncounterBridge.get_player(world)
    if player != null:
        EncounterSpawner.equip_weapon_id(player, weapon_id)
    for i in range(1, CombatConstants.FORMATION_UNIT_COUNT_HARD_CAP):
        var path: String = "Character/%s" % PartySetup._companion_node_name(i)
        if world.has_node(path):
            var companion_node: Node = world.get_node_or_null(path)
            if is_instance_valid(companion_node):
                EncounterSpawner.equip_weapon_id(companion_node, weapon_id)


## XCamp-4: assign rookie proficiency bonuses scaled by company renown.
static func _setup_rookie_proficiency_for_world(world: Node2D, character: Node) -> void:
    if character == null or world == null:
        return
    if not _get_company_state().read_stub_proficiency_enabled():
        return
    var entity: Node = CampaignEncounterBridge.health_entity_from_character(character)
    if entity == null or not "_proficiency_bonus" in entity:
        return
    var renown: int = _get_company_state().get_renown(world)
    # XCamp-4c: use the same base as the hire path so initial party and hires scale identically with renown.
    var base: float = recruit_proficiency_base(renown)
    for stat in EntityStatsUtil.PROFICIENCY_STATS:
        entity._proficiency_bonus[stat] = _profile_scaled_rookie_bonus(entity, stat, base)


## Marks a party fighter as proficiency-tracked so the combat skill curve (melee_skill from weapon/form
## experience) and the untrained holdback apply. Enemy / non-party entities stay untracked (baseline 100).
static func _mark_combat_skill_trained(character: Node) -> void:
    if character == null:
        return
    var entity: Node = CampaignEncounterBridge.health_entity_from_character(character)
    if entity != null and "_combat_skill_trained" in entity:
        entity._combat_skill_trained = true


## XCamp-4: roll a per-individual offset on each of the five base stats around the species/party
## baseline so no two party members are identical clones of the species template.
## Uses a bounded triangular distribution (sum of two uniforms, spans -10..+10, peak at 0) so most
## members land near average and extremes are rare. Applied straight to the base stat fields so the
## varied value flows through CombatantStatsSync like any other base value; persisted by
## CampaignPersistence so it is stable across save/load (does not re-roll on reload).
## Magnitude anchor: +/-10 ~= +/-10% around the ~100 baseline. Within-population CV for
## similar-adult physical/cognitive traits is ~5-15% (grip strength ~10-13%, VO2max ~12-15%,
## choice RT ~5-8%), so a 10-point spread is mid-range for real individual variation, not an
## invented extreme. The clamps (85-115) just keep the roll inside that biological band.
## XCamp-4c: at company renown > 0 a fresh hire rolls from a better band (higher floor, higher
## ceiling, small mean lift) -- a famous company attracts stronger recruits. Inert at renown 0.
static func _roll_stat_variance(character: Node, rng: RandomNumberGenerator, renown: int = 0) -> void:
    if not _get_company_state().read_stub_proficiency_enabled():
        return
    if character == null or rng == null:
        return
    var entity: Node = CampaignEncounterBridge.health_entity_from_character(character)
    if entity == null:
        return
    var floor_bonus: int = 0
    var ceil_bonus: int = 0
    var mean_lift: int = 0
    if renown > 0:
        floor_bonus = clampi(int(renown * ROOKIE_HIRE_STAT_FLOOR_PER_RENOWN), 0, ROOKIE_HIRE_STAT_FLOOR_CAP)
        ceil_bonus = clampi(int(renown * ROOKIE_HIRE_STAT_CEIL_PER_RENOWN), 0, ROOKIE_HIRE_STAT_CEIL_CAP)
        mean_lift = clampi(int(renown * ROOKIE_HIRE_STAT_MEAN_LIFT_PER_RENOWN), 0, ROOKIE_HIRE_STAT_MEAN_LIFT_CAP)
    var lo: int = 85 + floor_bonus
    var hi: int = 115 + ceil_bonus
    for stat in EntityStatsUtil.PROFICIENCY_STATS:
        if not (stat in entity):
            continue
        var base: int = int(entity.get(stat))
        var offset: int = int(roundf(rng.randf_range(-1.0, 1.0) * 5.0 + rng.randf_range(-1.0, 1.0) * 5.0))
        offset = clampi(offset, -10, 10)
        entity.set(stat, clampi(base + offset + mean_lift, lo, hi))
