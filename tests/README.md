# Test Battle Scene

Run the **Test Battle** scene to verify severance, mangled/destroyed parts, wounds, bleeding, and healing without playing the main game.

## How to run

1. **Temporary (this run only)**  
   In the Godot editor: **Project → Run → Run Current Scene** (or set the main scene to this one and run).

2. **Use as main scene**  
   In **Project → Project Settings → Application → Run**, set **Main Scene** to:
   ```
   res://tests/TestBattle.tscn
   ```
   Then run the project (F5). Change it back to `res://main.tscn` for normal play.

## What it does

1. **Scripted tests** (one entity, no UI):
   - **Mangled limb**: Damages `right_arm` until tissue is 0 but bone &gt; 0; checks targetable parts and mangled state.
   - **Severed limb**: Damages `left_leg` until severed; checks stump wound and total bleeding rate.
   - **Chest wounds**: Applies cut + blunt to chest; logs wounds and bleeding rate.
   - **Bleeding tick**: Runs `process_bleeding` and `process_blood_loss`; logs blood volume and clotting.
   - **Bandage**: Applies bandage to chest, ticks bleeding again; logs rate after bandage.
   - **Healing**: Advances game time with `process_healing`; logs tissue, bone, blood, and wound resolution.

2. **Live combat**: Starts the normal battle UI with two entities (TestPlayer vs TestEnemy). You can attack/parry; damage, armor, bone/tissue, wounds, and bleeding use the same systems as the main game.

3. **Post-combat**: When combat ends, logs the survivor’s state and runs one healing tick to show tissue/bone/blood recovery.

All steps print to the Godot **Output** panel so you can confirm numbers and behavior.
