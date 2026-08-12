extends SceneTree


func _init() -> void:
	var _WDH = preload("res://resources/weapons/WeaponDamageHelper.gd")
	var _WC = preload("res://resources/weapons/WeaponConstants.gd")
	var _SRP = preload("res://resources/weapons/StrikeRealismProfile.gd")
	var _H = preload("res://harness/HarnessFixtures.gd")
	
	# --- Test 1: kin_p_mult trace ---
	print("\n========== KIN_P_MULT TRACE ==========")
	var mace = _H.get_cached_weapon("MACE")
	if mace != null:
		var b1 := AttackInstance.new("direct_blow", 0.5)
		b1.velocity_m_s = 10.0
		b1.strike_momentum_mult = 1.0
		var b2 := AttackInstance.new("direct_blow", 0.5)
		b2.velocity_m_s = 10.0
		b2.strike_momentum_mult = 1.65
		
		var blunt1 = _WDH.compute_pre_armor_blunt(mace, b1, 100.0, 1.0)
		var blunt2 = _WDH.compute_pre_armor_blunt(mace, b2, 100.0, 1.0)
		var ratio = blunt2 / maxf(blunt1, 0.001)
		
		print("MACE blunt_1=%.4f blunt_2=%.4f ratio=%.4f want=1.6500" % [blunt1, blunt2, ratio])
		
		var raw1 = _WDH.compute_pre_armor_blunt_momentum_raw(mace, b1, 100.0, 1.0)
		var raw2 = _WDH.compute_pre_armor_blunt_momentum_raw(mace, b2, 100.0, 1.0)
		print("  raw_1=%.4f raw_2=%.4f raw_ratio=%.4f" % [raw1, raw2, raw2/maxf(raw1, 0.001)])
		
		var mass1 = _WDH.strike_mass_kg(mace, b1)
		var mass2 = _WDH.strike_mass_kg(mace, b2)
		print("  mass_1=%.4f mass_2=%.4f" % [mass1, mass2])
		
		var v1 = _WDH.get_effective_velocity_m_s(mace, b1, false)
		var v2 = _WDH.get_effective_velocity_m_s(mace, b2, false)
		print("  vel_1=%.4f vel_2=%.4f" % [v1, v2])
		
		var ke1 = _WDH.compute_kinetic_energy_j(mace, b1)
		var ke2 = _WDH.compute_kinetic_energy_j(mace, b2)
		print("  ke_1=%.4f ke_2=%.4f" % [ke1, ke2])
		
		var pen1 = _WDH.compute_penetration(mace, b1, "blunt", {})
		var pen2 = _WDH.compute_penetration(mace, b2, "blunt", {})
		var mpa1 = float(pen1.get("penetration_blunt_momentum_per_area", -1.0))
		var mpa2 = float(pen2.get("penetration_blunt_momentum_per_area", -1.0))
		print("  mpa_1=%.4f mpa_2=%.4f mpa_ratio=%.4f" % [mpa1, mpa2, mpa2/maxf(mpa1, 0.001)])
	else:
		print("MACE not found!")
	
	# --- Test 2: kin_pre_armor_cut trace ---
	print("\n========== KIN_PRE_ARMOR_CUT TRACE ==========")
	var sword = _H.get_cached_weapon("SWORD")
	if sword != null:
		var ai_lo := AttackInstance.new("oberhau", 0.5)
		ai_lo.archetype = {"kinematic_delivery": "swing"}
		ai_lo.velocity_m_s = 8.0
		
		var ai_hi := AttackInstance.new("oberhau", 0.5)
		ai_hi.archetype = {"kinematic_delivery": "swing"}
		ai_hi.velocity_m_s = 15.0
		
		var ke_lo = _WDH.compute_kinetic_energy_j(sword, ai_lo)
		var ke_hi = _WDH.compute_kinetic_energy_j(sword, ai_hi)
		var cut_lo = _WDH.compute_pre_armor_cut(sword, ai_lo, 100.0, 1.0)
		var cut_hi = _WDH.compute_pre_armor_cut(sword, ai_hi, 100.0, 1.0)
		
		var ke_ratio = ke_hi / maxf(ke_lo, 0.001)
		var sqrt_ke_ratio = sqrt(ke_ratio)
		var cut_ratio = cut_hi / maxf(cut_lo, 0.001)
		
		print("sword ke_lo=%.4f ke_hi=%.4f sqrt_ke_ratio=%.4f cut_ratio=%.4f" % [ke_lo, ke_hi, sqrt_ke_ratio, cut_ratio])
	else:
		print("SWORD not found!")
	
	# --- Test 3: sim_audit_ke trace ---
	print("\n========== SIM_AUDIT_KE TRACE ==========")
	if sword != null:
		var oberhau_commit = 0.78
		
		var ai_bare := AttackInstance.new("oberhau", 1.0)
		ai_bare.archetype = {"kinematic_delivery": "swing"}
		
		var ai_committed := AttackInstance.new("oberhau", 1.0)
		ai_committed.archetype = {"kinematic_delivery": "swing"}
		ai_committed.delivery_commit_fraction = oberhau_commit
		
		var ke_bare = _WDH.compute_kinetic_energy_j(sword, ai_bare)
		var ke_commit = _WDH.compute_kinetic_energy_j(sword, ai_committed)
		
		print("bare_ke=%.4f committed_ke=%.4f" % [ke_bare, ke_commit])
		print("|bare-100|=%.4f |commit-100|=%.4f" % [absf(ke_bare - 100.0), absf(ke_commit - 100.0)])
		
		var v_bare = _WDH.get_effective_velocity_m_s(sword, ai_bare, true)
		var v_committed = _WDH.get_effective_velocity_m_s(sword, ai_committed, true)
		print("bare_vel=%.4f committed_vel=%.4f" % [v_bare, v_committed])
		
	# --- Test 4: research_hema_ke trace ---
	print("\n========== RESEARCH_HEMA_KE TRACE ==========")
	var sword_def = Weapon.create_from_definition("SWORD")
	if sword_def != null:
		var ai := AttackInstance.new("oberhau", 1.0)
		ai.archetype = {"kinematic_delivery": "swing"}
		ai.delivery_commit_fraction = 0.78
		
		var phys: Dictionary = {}
		if sword_def.has("strike_physics"):
			var sp = sword_def.strike_physics
			if sp is Dictionary:
				phys = sp
		
		var station_mean = float(phys.get("station_mean", 0.54))
		var coup = _SRP._coupling("cut", phys)
		var vel_m_station = _SRP._station_velocity_mult("cut", station_mean, phys)
		var t_measure = clampf((1.0 - 0.78) / 0.34, 0.0, 1.0)
		var vel_m_meas = lerpf(0.97, 1.02, t_measure)
		var vel_m = vel_m_station * vel_m_meas
		
		print("station_mean=%.4f coup=%.4f vel_m_station=%.4f vel_m_meas=%.4f vel_m=%.4f" % [station_mean, coup, vel_m_station, vel_m_meas, vel_m])
		
		var e_mult_val = vel_m * vel_m * coup * clampf(0.78, 0.3, 1.0)
		print("strike_energy_mult=%.6f" % e_mult_val)
		
		ai.strike_energy_mult = e_mult_val
		var ke_research = _WDH.compute_kinetic_energy_j(sword_def, ai)
		print("research_KE=%.4f (want 65-145)" % ke_research)
	
	print("\n========== DONE ==========")
	quit()
