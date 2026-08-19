extends SceneTree


func _init() -> void:
	var _WDH = preload("res://resources/weapons/WeaponDamageHelper.gd")
	var _WC = preload("res://resources/weapons/WeaponConstants.gd")
	var _SRP = preload("res://resources/weapons/StrikeRealismProfile.gd")
	var _H = preload("res://harness/HarnessFixtures.gd")
	
	# --- kin_thrust_int via integration sample ---
	print("\n========== KIN_THRUST_INT INTEGRATION TRACE ==========")
	var _KDPPT = preload("res://harness/regression/kinematic/KinematicDeliveryPartialParryTests.gd")
	
	var arch := {"kinematic_delivery": "thrust"}
	var lo = _KDPPT._kin_dmg_integration_sample(9.0, 1.0, 1.0, {}, "SPEAR", "spear_thrust", 1.0, arch)
	var hi = _KDPPT._kin_dmg_integration_sample(14.0, 1.0, 1.0, {}, "SPEAR", "spear_thrust", 1.0, arch)
	
	var ke_lo = float(lo["strike_ke_j"])
	var ke_hi = float(hi["strike_ke_j"])
	var cut_lo = float(lo["pre_cut"])
	var cut_hi = float(hi["pre_cut"])
	
	print("lo: ke=%.4f pre_cut=%.4f" % [ke_lo, cut_lo])
	print("hi: ke=%.4f pre_cut=%.4f" % [ke_hi, cut_hi])
	
	var sqrt_ke_ratio = sqrt(ke_hi / maxf(ke_lo, 0.001))
	var cut_ratio = cut_hi / maxf(cut_lo, 0.001)
	print("sqrt_ke_ratio=%.4f cut_ratio=%.4f diff=%.4f" % [sqrt_ke_ratio, cut_ratio, absf(cut_ratio - sqrt_ke_ratio)])
	
	# --- spear direct trace ---
	print("\n========== SPEAR DIRECT TRACE ==========")
	var spear = _H.get_cached_weapon("SPEAR")
	if spear != null:
		var ai_9 := AttackInstance.new("spear_thrust", 0.5)
		ai_9.archetype = {"kinematic_delivery": "thrust"}
		ai_9.velocity_m_s = 9.0
		
		var ai_14 := AttackInstance.new("spear_thrust", 0.5)
		ai_14.archetype = {"kinematic_delivery": "thrust"}
		ai_14.velocity_m_s = 14.0
		
		var ke_9 = _WDH.compute_kinetic_energy_j(spear, ai_9)
		var ke_14 = _WDH.compute_kinetic_energy_j(spear, ai_14)
		var cut_9 = _WDH.compute_pre_armor_cut(spear, ai_9, 100.0, 1.0)
		var cut_14 = _WDH.compute_pre_armor_cut(spear, ai_14, 100.0, 1.0)
		
		print("direct ke_9=%.4f ke_14=%.4f sqrt_ratio=%.4f" % [ke_9, ke_14, sqrt(ke_14/maxf(ke_9, 0.001))])
		print("direct cut_9=%.4f cut_14=%.4f ratio=%.4f" % [cut_9, cut_14, cut_14/maxf(cut_9, 0.001)])
		
		var v9 = _WDH.get_effective_velocity_m_s(spear, ai_9, false)
		var v14 = _WDH.get_effective_velocity_m_s(spear, ai_14, false)
		var m9 = _WDH.strike_mass_kg(spear, ai_9)
		var m14 = _WDH.strike_mass_kg(spear, ai_14)
		print("v9=%.4f v14=%.4f m9=%.4f m14=%.4f" % [v9, v14, m9, m14])
	
	# --- sim_joule_floor trace ---
	print("\n========== SIM_JOULE_FLOOR TRACE ==========")
	var armor = _H.get_cached_armor("CUIRASS")
	if armor != null:
		var strike_ke = 90.0
		var cut_pre = 14.0
		
		var _AJB = preload("res://core/ArmorJouleBudget.gd")
		var joule_ke = _AJB.account_ke_through_armor(armor, strike_ke, 2.0, true)
		var frac = float(joule_ke.get("transmitted_ke_fraction", 1.0))
		
		print("strike_ke=%.1f cut_pre=%.1f frac=%.4f" % [strike_ke, cut_pre, frac])
		print("absorbed=%.2f remaining=%.2f" % [
			float(joule_ke.get("armor_ke_absorbed_j", 0)),
			float(joule_ke.get("armor_ke_remaining_j", 0))
		])
		
		var floor_92 = cut_pre * frac * 0.92
		var floor_80 = cut_pre * frac * 0.80
		print("floor(0.92)=%.4f floor(0.80)=%.4f" % [floor_92, floor_80])
		
		var ent = _H.new_entity_unarmed()
		if ent != null:
			ent.species = preload("res://resources/species/human.tres")
			ent.apply_species()
			ent.equip_armor("chest", armor)
			
			var _ED = preload("res://core/EntityDamage.gd")
			var res = _ED.apply_damage_split(
				ent, cut_pre, 0.0, "chest", 2.0, -1.0, -1.0,
				{"strike_ke_j": strike_ke, "force_joule_armor_budget": true}
			)
			var mech = float(res.get("mechanical_post_armor", 0.0))
			print("mech=%.4f actual_floor_92=%.4f below_by=%.4f" % [mech, floor_92, floor_92 - mech])
	
	# --- sim_audit_ke velocity path detail ---
	print("\n========== SIM_AUDIT_KE VELOCITY PATH ==========")
	var sword = _H.get_cached_weapon("SWORD")
	if sword != null:
		var ai_bare := AttackInstance.new("oberhau", 1.0)
		ai_bare.archetype = {"kinematic_delivery": "swing"}
		
		var ai_committed := AttackInstance.new("oberhau", 1.0)
		ai_committed.archetype = {"kinematic_delivery": "swing"}
		ai_committed.delivery_commit_fraction = 0.78
		
		print("--- bare (commit=-1, i=1.0) ---")
		var v_bare_final = _WDH.get_effective_velocity_m_s(sword, ai_bare, true)
		var ke_bare = _WDH.compute_kinetic_energy_j(sword, ai_bare)
		print("final_vel=%.4f ke=%.4f" % [v_bare_final, ke_bare])
		
		# Step through velocity derivation for bare
		var eff_i = _WDH.effective_intensity_for_delivery(1.0, -1)
		var band_max_sword = 16.0  # from ImpactVelocityModel.SWORD.cut -> (7.5, 16.0)
		var vel_curve = _WDH.velocity_m_s_from_intensity(eff_i, ai_bare.archetype, sword, "oberhau")
		print("eff_i=%.4f vel_from_curve=%.4f band_max=16.0" % [eff_i, vel_curve])
		
		print("--- committed (commit=0.78, i=1.0) ---")
		var v_c_final = _WDH.get_effective_velocity_m_s(sword, ai_committed, true)
		var ke_c = _WDH.compute_kinetic_energy_j(sword, ai_committed)
		print("final_vel=%.4f ke=%.4f" % [v_c_final, ke_c])
		
		var eff_i_c = _WDH.effective_intensity_for_delivery(1.0, 0.78)
		var vel_curve_c = _WDH.velocity_m_s_from_intensity(eff_i_c, ai_committed.archetype, sword, "oberhau")
		var dampen = 1.0 - (1.0 - 0.78) * 0.04
		print("eff_i=%.4f vel_from_curve=%.4f dampen=%.4f after_dampen=%.4f" % [eff_i_c, vel_curve_c, dampen, vel_curve_c * dampen])
	
	# --- research_hema_ke full trace ---
	print("\n========== RESEARCH_HEMA_KE FULL TRACE ==========")
	var sword_def = Weapon.create_from_definition("SWORD")
	if sword_def != null:
		var ai := AttackInstance.new("oberhau", 1.0)
		ai.archetype = {"kinematic_delivery": "swing"}
		ai.delivery_commit_fraction = 0.78
		
		var phys: Dictionary = {}
		if sword_def.strike_physics is Dictionary:
			phys = sword_def.strike_physics
		
		var station_mean = float(phys.get("station_mean", 0.54))
		var coup = _SRP._coupling("cut", phys)
		var vel_m_station = _SRP._station_velocity_mult("cut", station_mean, phys)
		var t_measure = clampf((1.0 - 0.78) / 0.34, 0.0, 1.0)
		var vel_m_meas = lerpf(0.97, 1.02, t_measure)
		var vel_m = vel_m_station * vel_m_meas
		
		print("station=%.4f coup=%.4f vel_m_st=%.4f vel_m_meas=%.4f vel_m=%.6f" % [station_mean, coup, vel_m_station, vel_m_meas, vel_m])
		
		var ke_r = _WDH.compute_kinetic_energy_j(sword_def, ai)
		print("research_KE=%.4f (want 65-145)" % ke_r)
	
	print("\n========== DONE ==========")
	quit()
