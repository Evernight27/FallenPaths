# ai/

Turn menu build, mental stack, weighted pick, melee listing / targeting.

Pipeline: `AvailableActionsBuilder.build` → `MentalStackDecider.try_pick` → `CombatAIActionPicker.pick_weighted` → `CombatResolveAction.resolve` (in `flow/`).
