extends Node

# Signals for UI and 3D scenes to listen to
signal state_changed

# Game State Variables
var day_count: int = 1
var cash: float = 1200.0
var feed_lbs: float = 300.0
var weather: String = "Sunny"
var current_pasture: int = 1
var grass_level_1: float = 80.0
var grass_level_2: float = 100.0
var ledger: Array[String] = []
var herd: Array[Goat] = []
var has_guard_donkey: bool = false

# Upgrades
var barn_level: int = 1
var has_medical_station: bool = false
var has_automated_waterers: bool = false
var has_quarantine_pen: bool = false

func _ready():
	_initialize_starter_herd()

func _initialize_starter_herd():
	var starter_buck = Goat.new("sire_starter", "Titan", "buck", 18, 165.0, "Kiko", 0.85, 1.2)
	var starter_doe1 = Goat.new("dam_starter_1", "Bella", "doe", 16, 110.0, "Kiko", 0.75, 1.0)
	var starter_doe2 = Goat.new("dam_starter_2", "Luna", "doe", 14, 95.0, "Boer", 0.60, 1.1)

	herd = [starter_buck, starter_doe1, starter_doe2]
	ledger.append("Day 1: Welcome to HerdSim! You started your ranch with Buck Titan, Does Bella and Luna, and $1,200 cash.")
	state_changed.emit()

func get_herd_capacity() -> int:
	match barn_level:
		1: return 6
		2: return 12
		3: return 25
		4: return 50
		5, _: return 100

func next_day():
	var next_day_num = day_count + 1
	
	# 1. Weather roll
	var weather_roll = randf()
	var new_weather = "Sunny"
	if weather_roll < 0.15:
		new_weather = "Drought"
		ledger.insert(0, "Day %d: A severe drought has begun. Grass growth halted." % next_day_num)
	elif weather_roll < 0.40:
		new_weather = "Rainy"
		ledger.insert(0, "Day %d: Rain today is helping the pastures recover." % next_day_num)
	weather = new_weather

	# 2. Consume and grow grass
	var grass_grown_1 = 0.0
	var grass_grown_2 = 0.0
	
	if weather == "Rainy":
		grass_grown_1 = 6.0
		grass_grown_2 = 6.0
	elif weather == "Sunny":
		grass_grown_1 = 2.0;
		grass_grown_2 = 2.0;

	# Automated Waterer: Speeds up grass regrowth in the inactive pasture by 15%
	if has_automated_waterers:
		if current_pasture == 1:
			grass_grown_2 *= 1.15
		else:
			grass_grown_1 *= 1.15

	# Goats eat grass from current pasture (each eats 2.0% of pasture grass per day)
	var consumption_per_goat = 2.0
	var total_eating = herd.size() * consumption_per_goat

	if current_pasture == 1:
		grass_level_1 = clampf(grass_level_1 - total_eating + grass_grown_1, 0.0, 100.0)
		grass_level_2 = clampf(grass_level_2 + grass_grown_2, 0.0, 100.0)
	else:
		grass_level_2 = clampf(grass_level_2 - total_eating + grass_grown_2, 0.0, 100.0)
		grass_level_1 = clampf(grass_level_1 + grass_grown_1, 0.0, 100.0)

	# 3. Feed stock consumption
	var is_starving = false
	var active_grass = grass_level_1 if current_pasture == 1 else grass_level_2
	if active_grass <= 0.0:
		var feed_needed = herd.size() * 2.0 # 2 lbs per goat
		if feed_lbs >= feed_needed:
			feed_lbs -= feed_needed
			ledger.insert(0, "Day %d: Pasture depleted. Herd ate %0.1f lbs from feed supply." % [next_day_num, feed_needed])
		else:
			feed_lbs = 0.0
			is_starving = true
			ledger.insert(0, "Day %d: ⚠️ Pasture depleted AND feed stock empty! Your goats are starving!" % next_day_num)

	# 4. Parasite transmission setup
	var parasite_spread_event = false
	var has_sick_goat = false
	for g in herd:
		if g.is_sick:
			has_sick_goat = true
			break

	if not has_quarantine_pen and has_sick_goat:
		if randf() < 0.10:
			parasite_spread_event = true

	var infect_target_index = -1
	if parasite_spread_event:
		var healthy_indices = []
		for i in range(herd.size()):
			if not herd[i].is_sick:
				healthy_indices.append(i)
		if healthy_indices.size() > 0:
			infect_target_index = healthy_indices[randi() % healthy_indices.size()]

	# 5. Update Goats
	var updated_herd: Array[Goat] = []
	var newborn_kids: Array[Goat] = []

	for i in range(herd.size()):
		var goat = herd[i]
		
		# Age tick
		var new_age = goat.age_months
		if next_day_num % 30 == 0:
			new_age += 1

		# Weight tick
		var weight_change = 0.0
		if is_starving:
			weight_change = -1.5
		else:
			if goat.age_months < 24:
				weight_change = 0.4 * goat.growth_rate
			else:
				weight_change = 0.05
		var new_weight = clampf(goat.weight_lbs + weight_change, 5.0, 250.0)

		# Sickness updates
		var now_sick = goat.is_sick
		if i == infect_target_index:
			now_sick = true
			ledger.insert(0, "Day %d: ⚠️ Parasites spread! %s caught worms from another sick herd member." % [next_day_num, goat.name])
		elif is_starving:
			now_sick = true
		elif not goat.is_sick and randf() < (0.05 * (1.0 - goat.parasite_resistance)):
			now_sick = true
			ledger.insert(0, "Day %d: 🤒 %s has contracted worms/parasites." % [next_day_num, goat.name])

		# Medical station recovery
		if now_sick and has_medical_station and randf() < 0.15:
			now_sick = false
			ledger.insert(0, "Day %d: 💊 Medical Station care cured %s of their parasites." % [next_day_num, goat.name])

		# Death chance
		if now_sick:
			var death_chance = 0.035 if has_medical_station else 0.07
			if randf() < death_chance:
				ledger.insert(0, "Day %d: 💀 RIP %s passed away due to untreated illness." % [next_day_num, goat.name])
				continue # Skip adding back to herd (death)

		# Pregnancy updates
		var pregnant = goat.is_pregnant
		var preg_days = goat.pregnancy_days
		if pregnant:
			preg_days += 1
			if preg_days >= 150:
				pregnant = false
				preg_days = 0
				var num_kids = 2 if randf() < 0.4 else 1
				for k in range(num_kids):
					var kid_gender = "buck" if randf() < 0.5 else "doe"
					var kid_name = "%s_%d_%d" % ["Buck" if kid_gender == "buck" else "Doe", next_day_num, randi() % 100]
					
					# Find parents
					var sire = null
					for g in herd:
						if g.name == goat.sire_name:
							sire = g
							break
					if sire == null:
						for g in herd:
							if g.gender == "buck":
								sire = g
								break
					
					newborn_kids.append(Goat.newborn(
						"kid_%d_%d" % [next_day_num, randi() % 1000],
						kid_name,
						kid_gender,
						sire,
						goat
					))
				ledger.insert(0, "Day %d: 🎉 %s gave birth to %d kid(s)!" % [next_day_num, goat.name, num_kids])

		# Save updates
		var updated_goat = goat.duplicate_goat()
		updated_goat.age_months = new_age
		updated_goat.weight_lbs = new_weight
		updated_goat.is_sick = now_sick
		updated_goat.is_pregnant = pregnant
		updated_goat.pregnancy_days = preg_days
		updated_herd.append(updated_goat)

	# Add newborn kids
	updated_herd.append_array(newborn_kids)

	# Enforce Barn Limit check warning
	if updated_herd.size() > get_herd_capacity():
		ledger.insert(0, "Day %d: ⚠️ OVER CAPACITY! Your herd of %d goats exceeds your Barn limit of %d. Upgrade your Barn or sell goats!" % [next_day_num, updated_herd.size(), get_herd_capacity()])

	# Predator attack
	if randf() < 0.02:
		if has_guard_donkey:
			ledger.insert(0, "Day %d: 🫏 A coyote approached, but your Guard Donkey chased it away!" % next_day_num)
		elif updated_herd.size() > 0:
			var killed_goat = updated_herd.remove_at(randi() % updated_herd.size())
			ledger.insert(0, "Day %d: 🐺 A predator attacked last night and killed %s!" % [next_day_num, killed_goat.name])

	herd = updated_herd
	day_count = next_day_num
	state_changed.emit()

func rotate_pastures():
	current_pasture = 2 if current_pasture == 1 else 1
	ledger.insert(0, "Day %d: Rotated herd to Pasture %d." % [day_count, current_pasture])
	state_changed.emit()

func buy_feed(lbs: float, cost: float):
	if cash < cost: return
	cash -= cost
	feed_lbs += lbs
	ledger.insert(0, "Day %d: Purchased %0.0f lbs of feed for $%0.0f." % [day_count, lbs, cost])
	state_changed.emit()

func buy_guard_donkey():
	var cost = 300.0
	if cash < cost or has_guard_donkey: return
	cash -= cost
	has_guard_donkey = true
	ledger.insert(0, "Day %d: Purchased a Guard Donkey for $300 to protect the herd." % day_count)
	state_changed.emit()

func buy_upgrade(upgrade_id: String, cost: float):
	if cash < cost: return
	cash -= cost
	
	match upgrade_id:
		"barn":
			barn_level += 1
			ledger.insert(0, "Day %d: Upgraded Barn to Level %d (Capacity: %d) for $%0.0f." % [day_count, barn_level, get_herd_capacity(), cost])
		"medical":
			has_medical_station = true
			ledger.insert(0, "Day %d: Constructed a Medical Station for $%0.0f." % [day_count, cost])
		"waterer":
			has_automated_waterers = true
			ledger.insert(0, "Day %d: Installed Automated Waterers for $%0.0f." % [day_count, cost])
		"quarantine":
			has_quarantine_pen = true
			ledger.insert(0, "Day %d: Built a Quarantine Pen for $%0.0f." % [day_count, cost])
	
	state_changed.emit()

func treat_goat(id: String):
	var cost = 10.0 if has_medical_station else 25.0
	if cash < cost: return

	var idx = -1
	for i in range(herd.size()):
		if herd[i].id == id:
			idx = i
			break
	
	if idx == -1 or not herd[idx].is_sick: return

	cash -= cost
	var updated_goat = herd[idx].duplicate_goat()
	updated_goat.is_sick = false
	herd[idx] = updated_goat
	ledger.insert(0, "Day %d: Treated %s for $%0.0f. Parasites cleared." % [day_count, updated_goat.name, cost])
	state_changed.emit()

func sell_goat(id: String, final_bid: float):
	var idx = -1
	for i in range(herd.size()):
		if herd[i].id == id:
			idx = i
			break
	
	if idx == -1: return

	var sold_goat = herd.remove_at(idx)
	cash += final_bid
	ledger.insert(0, "Day %d: Sold %s at auction for $%0.2f." % [day_count, sold_goat.name, final_bid])
	state_changed.emit()

func buy_goat(new_goat: Goat, cost: float):
	if cash < cost or herd.size() >= get_herd_capacity(): return
	cash -= cost
	herd.append(new_goat)
	ledger.insert(0, "Day %d: Purchased %s for $%0.0f." % [day_count, new_goat.name, cost])
	state_changed.emit()

func breed_goats(sire_id: String, dam_id: String):
	if herd.size() >= get_herd_capacity(): return

	var sire_idx = -1
	var dam_idx = -1
	for i in range(herd.size()):
		if herd[i].id == sire_id:
			sire_idx = i
		if herd[i].id == dam_id:
			dam_idx = i

	if sire_idx == -1 or dam_idx == -1: return
	var sire = herd[sire_idx]
	var dam = herd[dam_idx]

	if sire.gender != "buck" or dam.gender != "doe" or dam.is_pregnant: return

	var updated_dam = dam.duplicate_goat()
	updated_dam.is_pregnant = true
	updated_dam.pregnancy_days = 0
	updated_dam.sire_name = sire.name
	updated_dam.dam_name = dam.name

	herd[dam_idx] = updated_dam
	ledger.insert(0, "Day %d: Bred buck %s to doe %s." % [day_count, sire.name, dam.name])
	state_changed.emit()
