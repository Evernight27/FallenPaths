# Wound Packing: Medieval Implementation Research

## Historical Background

### Ancient and Medieval Practice

- **Hippocrates (5th c. BCE)**: Clean dry linen applied to wounds; wine/vinegar as medicaments. Bandaging to bring wound edges together.
- **Celsus (1st c. CE)**: To stop bleeding—apply dry lint, then a sponge wrung in cold water firmly. If bleeding continues, soak sponge in vinegar. Vessel ligation or cautery as last resort.
- **Albucasis (11th c.)**: Packed wounds with powders (incense, dragon's blood, lime). Also recommended dressings with washed lime and oil of roses.
- **Crusades (12th–13th c.)**: Medieval surgeons used clean linen cloth, wound suturing, arrow removal. Military orders (St. John, Temple) had hospitals with treatment protocols.

### Principle

Packing = filling the wound cavity with material to apply pressure from within. Surface bandages compress from outside; packing reaches deep bleeding sources. When tourniquets cannot be used (neck, groin, axilla, chest), packing is the alternative.

### Medieval Materials

- Linen cloth, lint, wool
- Clean dry cloth (when hemostatic agents unavailable)
- Herbal preparations (honey, vinegar, wine)

---

## Modern TCCC Guidelines (for comparison)

- **Indication**: Junctional hemorrhage (neck, groin, axilla) or compressible wounds where tourniquet doesn't apply
- **Technique**: Pack tightly with hemostatic gauze or clean cloth; fill cavity completely; hold direct pressure 3+ minutes
- **Materials**: Combat Gauze (hemostatic) preferred; if unavailable, gauze or clean dry cloth

---

## Implementation Proposal for Medieval System

### When to Use Wound Packing

| Body Part | Tourniquet | Bandage | Packing |
|-----------|------------|---------|---------|
| Limbs     | ✓ (severe) | ✓       | —       |
| Head      | ✗          | ✓       | ✓ (deep) |
| Chest     | ✗          | ✓       | ✓ (deep) |

**Packing indicated when:**
- Head or chest wound
- Wound is severe or critical (deep cavity)
- Optionally: when bandage has failed or bleeding rate remains high

### Mechanic Design

1. **New action**: `pack_wound` (or `pack_with_linen`)
2. **Target parts**: head, chest only (junctional/non-compressible areas)
3. **Effect**: Stronger than bandage for deep wounds—e.g. 85% reduction, faster clotting, or higher success rate
4. **Time**: Longer than bandage (packing cavity takes time)—e.g. 8–12 seconds base
5. **Materials**: Abstract "linen" or consumable; or unlimited (like bandage) for simplicity
6. **Success/failure**: Same pattern as bandage—medical skill affects outcome; failure allows retry

### Medieval Flavor

- **Name**: "Pack wound with linen" / "Stuff wound"
- **Description**: Fill the wound cavity with linen strips to apply pressure from within. Used for deep chest or neck wounds where surface bandages cannot reach.
- **Era-appropriate**: No hemostatic agents (chitosan, kaolin); plain linen/cloth. Effectiveness comes from technique and pressure, not modern chemistry.

### Integration with Existing System

- **Mutually exclusive with bandage** on same part? Or **stackable**—pack first, then bandage over? Research suggests pack + pressure + bandage wrap. Could allow: pack (fills cavity) + bandage (secures). Or treat pack as "upgraded bandage" for head/chest.
- **Simpler approach**: Packing is an alternative to bandage for head/chest when wound is severe/critical. Same success/failure logic as bandage; better effectiveness constants.

### Suggested Constants (BleedingConstants.gd)

```gdscript
# Wound packing (head/chest; deep cavity; linen/cloth stuffed into wound)
const PACKING_PARTS: Array = ["head", "chest"]
const PACKING_IMMEDIATE_REDUCTION: float = 0.85  # stronger than bandage for deep wounds
const PACKING_SUCCESS_BASE_CHANCE: float = 0.65  # harder than bandage (technique)
const PACKING_APPLICATION_TIME_SECONDS: float = 10.0
```

---

## Summary

Wound packing fits the medieval setting: linen/cloth packed into deep wounds is historically attested. It adds a head/chest–specific option for severe hemorrhage where tourniquets cannot be used (neck, thoracic, abdominal). Implementation would mirror bandage (success roll, medical skill, failure = retry) with different effectiveness and timing.
