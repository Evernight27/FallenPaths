# Combat Parry / Miss Rates: Research vs Fallen Paths

Short summary of available research on how often melee attacks were parried or missed (healthy vs injured), and how that compares to the current system.

---

## 1. What the research actually measures

- **Historical medieval sources** do not give quantitative “parry rate” or “miss rate” statistics. Fencing manuals describe technique; casualty records give wound locations (e.g. Visby), not “how many blows were parried.”
- **HEMA** gives the only numeric data, but it measures **contact type** and **exchange outcome**, not “attack attempt → miss/parry/hit” per swing.

So we have to map **research metrics** (blade-blade vs blade-armor, clean/double/afterblow) onto your **game outcomes** (miss, parry, deflected, hit).

---

## 2. HEMA: Blade contact (parry vs hit on target)

Source: [Swords in modern fencing: hits ratio](https://artofswordmaking.com/gallery/swords-in-modern-fencing-hits-ratio) (Maciej Kopciuch, analysis of HEMA finals and tournaments).

**When a blow makes contact**, what does it hit?

| Setup | Blade–blade (parry/block) | Blade–armor / target |
|-------|---------------------------|------------------------|
| Longsword, protective suit (HEMA) | **80%** | 20% |
| Longsword, full armor | **57%** | 43% |
| Sword & buckler, protective suit | **23%** | 77% (buckler/armor) |
| Sword & buckler, full armor | **26%** | 74% |
| Sword & large shield, full armor | **22%** | 78% |

Interpretation:

- **Longsword, no shield:** most *contacts* are blade-on-blade (parry/block). Only **20–43%** of contacts are “blade on body/armor.”
- So in longsword-style fights, **parries dominate** among contacts; “clean hit on target” is the minority of contacts.
- With shield/buckler, the shield soaks most defensive contact, so blade–blade is lower.

Your game (longsword-like, no shield): research suggests that **of all contacts**, something in the **~57–80%** range being “defended” (parry or armor soak) and **~20–43%** being “meaningful hit on target” is in the right ballpark. Your **deflected** (armor absorbed most) + **parry** together are the “defended” side; **hit** is the “meaningful hit” side.

---

## 3. HEMA: Exchange outcomes (doubles, afterblows, clean)

Source: [HEMA Myth: Double Outs](https://swordstem.com/2021/11/11/hema-myth-double-outs-increase-the-rate-of-doubles/) (Sword STEM, 71 longsword events, 42,026 exchanges).

Each **exchange** is classified as:

- **Clean:** one fighter lands a scoring hit without double/afterblow.
- **Afterblow:** one lands, the other hits back within the afterblow window.
- **Double:** both hit “simultaneously” (no single winner).

Typical **double hit %** in longsword:

- Many events: **~7–12%** doubles.
- Some rule sets / cultures: **~20–40%** doubles.

So **~70–90%** of exchanges (depending on event) end with *some* kind of hit (clean or afterblow or both). That does **not** tell us “what % of individual attacks miss” — an exchange can include several attacks; we only see the final outcome. So research does **not** give a direct “miss rate per attack” for healthy fighters.

---

## 4. Injury / fatigue and performance

- **Mental fatigue (soldiers):** marksmanship *decision* errors increased **~48%** vs **~32%** in controls ([Prior Mental Fatigue Impairs Marksmanship Decision Performance](https://www.frontiersin.org/articles/10.3389/fphys.2017.00680/pdf)). So judgment/decision degrades more than raw shot accuracy in that study.
- **Acute fatigue (MMA):** reaction time and **reaction consistency** get worse ([PMC6994193](https://pmc.ncbi.nlm.nih.gov/articles/PMC6994193)).
- **Combined motor + cognitive fatigue:** worse than either alone; anticipatory reaction and military marksmanship suffer.

There is **no** direct study of “melee miss rate when wounded.” The consistent finding is: **fatigue and injury impair reaction time, consistency, and decision-making.** So it is plausible that **wounded fighters miss more and parry less effectively**; your use of a **performance modifier** (pain/consciousness) to reduce hit chance and parry effectiveness is in line with that.

---

## 5. Mapping research to your system

| Your outcome | Meaning in game | Research analogue |
|--------------|-----------------|-------------------|
| **Miss** | Attacker whiffs (no contact). | Not measured in HEMA (they count contacts and exchange winners). Plausible that it’s a small fraction when in measure; your **6% base** is reasonable for “healthy.” |
| **Dodge** | Defender avoids (no contact). | Could be part of “no clean hit” in an exchange. Your **≤8%** (DODGE_CHANCE_AT_FULL_SPEED) is modest. |
| **Parry** | Defender chooses parry; wind-up vs attack; capacity vs momentum; full deflect or partial. | **Blade–blade contact** in HEMA: **57–80%** of *contacts* for longsword. So when the defender *can* parry, parries should be common among contacts. |
| **Deflected** | Contact, but tissue damage &lt; 25% of pre-armor (armor absorbed most). | Part of **blade–armor** contacts where armor does its job (glancing / absorbed). Fits the **20–43%** “blade–armor” that aren’t full parries. |
| **Hit** | Contact, meaningful tissue damage. | The remainder of blade–armor contacts that get through. |

So in research terms:

- **Among contacts:** something like **~57–80%** “defended” (parry or armor-heavy deflected) and **~20–43%** “meaningful hit” is supported for longsword-style.
- **Before contact:** a small **miss** rate (your 6% base) and small **dodge** (≤8%) are plausible; research doesn’t give a precise number.

---

## 6. Healthy vs injured (research vs your system)

| Aspect | Research | Your system |
|--------|----------|-------------|
| **Healthy:** miss rate | No direct melee stat; HEMA suggests most exchanges end in *some* contact. | **6%** base miss, **≤8%** dodge → most attacks “reach” the target in some form. **Reasonable.** |
| **Healthy:** parry share of contacts | Longsword: **57–80%** of contacts are blade–blade. | Depends on **how often defenders choose parry** and **parry success**. If parry is only attempted sometimes, your *resolved* parries can be fewer than 57–80% of attacks; if you want to match research, parry attempts and/or success might need to be high when the defender is able. |
| **Injured:** miss / inaccuracy | Fatigue/injury impairs reaction and consistency; no melee miss %. | **get_hit_chance_performance_modifier()** (head pain) reduces effective hit chance; wounded fighters miss more. **Consistent with research.** |
| **Injured:** parry effectiveness | No direct parry data; reaction/consistency drop. | Parry capacity scaled by **performance modifier** (pain/consciousness). **Consistent.** |

So: **healthy** numbers (low miss, modest dodge) and **injured** handling (performance modifier on hit chance and parry) both align with the limited research. The main lever to “match” HEMA is **how often parries are attempted and succeed** relative to total attacks.

---

## 7. Summary comparison

- **Miss (healthy):** Research doesn’t give a number; your **6%** base is a plausible, low “whiff” rate.
- **Dodge:** Your **≤8%** is modest and plausible.
- **Parry vs hit (among contacts):** Research suggests **~57–80%** of longsword contacts are blade–blade (parry). Your **parry** + **deflected** together represent “defended”; **hit** is “meaningful hit.” Tuning parry **choice weight** and **success** (capacity vs momentum, wind-up timing) will determine whether your “defended” fraction is in that band.
- **Injured:** Research supports **worse accuracy and reaction** when fatigued/injured; your **performance modifier** on hit chance and parry is in line with that.

If you want to push closer to the HEMA band: ensure parry is attempted often when an attack is incoming (e.g. high parry choice weight when available) and that successful parries (full deflect) are a large share of those attempts when the defender is healthy and in time.

---

## 8. Dodge / void in HEMA and historical fencing (realism tuning)

### What the research says

**Historical sources:** Void (body displacement to avoid an attack) is a valid technique in Meyer, Capo Ferro, and other manuals. Terminology: retreat, girata (turn), inquartata, passes beneath. No manual gives numeric success rates.

**ARMA (parrying essay):** "Voiding, deflecting and flat-of-the-blade parries are always preferable to direct blocking" and "movement and counter-action to void or displace or deflect attacks is superior to direct opposition parrying." They *demonstrate* evasion first to teach that defense is achieved more by effective movement than by meeting blows—but this is pedagogy, not a claim about frequency.

**A Fencer's Ramblings:** Voids require *perfect* timing. Move too early → opponent adjusts and still hits. Move too late → you get hit. "The fencer must wait for the attack to come and only move at the last minute." Evasion is technically demanding and easy to mis-time.

**HEMA contact data (Kopciuch):** Longsword: 57–80% of *contacts* are blade-blade (parry); 20–43% blade–armor/body. This counts *contacts only*. A complete void (no contact) does *not* appear in those stats—we don't know what fraction of attacks never make contact because of evasion.

**Conclusion:** No source gives a quantitative "dodge/void success rate." Parry/blade contact dominates among contacts (57–80%). Void is attested as valid but hard (timing-sensitive). Realism supports a *modest* dodge base—less than parry—rather than making evasion competitive with or superior to parry.

### Tuning for realism

| Constant | Current | Realism range | Notes |
|----------|---------|---------------|-------|
| DODGE_CHANCE_AT_FULL_SPEED | **0.10** | Implemented | Modest void base per HEMA research. |
| PARRY_PREFER_DODGE_FULL_THRESHOLD | **0.12** | Implemented | "Clean dodge likely" for high-agility defenders. |

**Implemented:** DODGE_CHANCE_AT_FULL_SPEED 0.10, PARRY_PREFER_DODGE_FULL_THRESHOLD 0.12. Partial dodge tiers and expected-damage logic retained.

**Partial parry follow-through:** Defender twisted with the parry attempt; body movement can slip the remainder. `PARRY_FOLLOW_THROUGH_DODGE_EFFICIENCY` (0.5) gives a reduced dodge roll on follow-through. Success = full dodge; failure = damage with parry-reduced velocity. See COMBAT_SYSTEM_ISSUES §3.

---

## 9. Flat-of-blade vs edge parry: is it modeled?

**HEMA / ARMA principle:** Parries with cutting swords are made with the **flat** ("mit der flech"), not the edge. Edge-on-edge contact damages the blade (nicks, gouges) and risks fracture. Receiving on the flat deflects and dissipates force; the attacker's edge doesn't bite.

### What the game models

| Effect | Implementation | Location |
|--------|-----------------|----------|
| **Cut→blunt shift** | When a cut is partially parried (`parry_remaining_ratio < 1`), `redirect_shift = PARRY_CUT_TO_BLUNT_SHIFT * (1 - remaining_ratio)` reduces `cut_ratio` before damage. Deflected edge presents flat/slap; less sharp bite. | AttackResolver.gd:48–52, PARRY_CUT_TO_BLUNT_SHIFT 0.45 |
| **Oblique penetration** | `pen_sharp` and `pen_blunt` scaled by angle factor `lerp(1, PARRY_PENETRATION_ANGLE_MIN, 1 - remaining_ratio)`. Oblique impact penetrates less. | AttackResolver.gd:65–71 |
| **Velocity reduction** | `parry_remaining_ratio` drives impact velocity (and KE) on follow-through. Partial parry = less energy delivered. | Parry resolution → damage path |

### What is not modeled

- **Defender blade orientation:** The game does not explicitly track "defender used flat" vs "defender used edge." The *outcome* (reduced cut, more blunt, worse angle) is modeled without that state.
- **Defender weapon durability:** Edge-on-edge parries would damage the defender's blade. No weapon wear/edge damage system exists.

### Verdict

**The flat-of-blade effect is replicated through outcome, not mechanism.** Deflected cuts already deal more blunt and less cut, with reduced penetration—matching "receive on flat → attacker's edge doesn't bite." Adding explicit flat-vs-edge state would add complexity for little gain: the damage pipeline already encodes the correct result. Modeling defender blade wear from edge parries would require a durability system; impact on defender body damage is negligible (the body-damage outcome is already correct).
