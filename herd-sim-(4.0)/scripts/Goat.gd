class_name Goat
extends RefCounted

var id: String
var name: String
var gender: String # 'buck' or 'doe'
var age_months: int
var weight_lbs: float
var breed: String
var parasite_resistance: float # 0.0 to 1.0
var growth_rate: float # 0.5 to 1.5
var is_sick: bool = false
var is_pregnant: bool = false
var pregnancy_days: int = 0
var sire_name: String = "Unknown"
var dam_name: String = "Unknown"
var sire_sire_name: String = "Unknown"
var sire_dam_name: String = "Unknown"
var dam_sire_name: String = "Unknown"
var dam_dam_name: String = "Unknown"
var sire_pr: float = 0.5
var dam_pr: float = 0.5

func _init(p_id: String, p_name: String, p_gender: String, p_age: int, p_weight: float, p_breed: String, p_pr: float, p_gr: float, p_sire_name: String = "Unknown", p_dam_name: String = "Unknown"):
	id = p_id
	name = p_name
	gender = p_gender
	age_months = p_age
	weight_lbs = p_weight
	breed = p_breed
	parasite_resistance = p_pr
	growth_rate = p_gr
	sire_name = p_sire_name
	dam_name = p_dam_name

func get_gender_display() -> String:
	return "Buck" if gender == "buck" else "Doe"

func get_status_display() -> String:
	if is_sick:
		return "Sick 🤒"
	if is_pregnant:
		return "Pregnant 🤰 (%0.1fm)" % (pregnancy_days / 30.0)
	return "Healthy 🟢"

func is_adult() -> bool:
	return age_months >= 12

# Duplicate function analogous to copyWith
func duplicate_goat() -> Goat:
	var copy = Goat.new(id, name, gender, age_months, weight_lbs, breed, parasite_resistance, growth_rate, sire_name, dam_name)
	copy.is_sick = is_sick
	copy.is_pregnant = is_pregnant
	copy.pregnancy_days = pregnancy_days
	copy.sire_sire_name = sire_sire_name
	copy.sire_dam_name = sire_dam_name
	copy.dam_sire_name = dam_sire_name
	copy.dam_dam_name = dam_dam_name
	copy.sire_pr = sire_pr
	copy.dam_pr = dam_pr
	return copy

static func newborn(p_id: String, p_name: String, p_gender: String, sire: Goat, dam: Goat) -> Goat:
	# Average genetics with +/- 10% mutation
	var base_pr = (sire.parasite_resistance + dam.parasite_resistance) / 2.0
	var mutation_pr = (randf() * 0.2) - 0.1
	var parasite_resistance = clampf(base_pr + mutation_pr, 0.1, 1.0)

	var base_gr = (sire.growth_rate + dam.growth_rate) / 2.0
	var mutation_gr = (randf() * 0.2) - 0.1
	var growth_rate = clampf(base_gr + mutation_gr, 0.5, 2.0)

	var breed = sire.breed if randf() < 0.5 else dam.breed
	var weight_lbs = 6.0 + (randf() * 3.0) # 6 to 9 lbs

	var kid = Goat.new(p_id, p_name, p_gender, 0, weight_lbs, breed, parasite_resistance, growth_rate, sire.name, dam.name)
	kid.sire_sire_name = sire.sire_name
	kid.sire_dam_name = sire.dam_name
	kid.dam_sire_name = dam.sire_name
	kid.dam_dam_name = dam.dam_name
	kid.sire_pr = sire.parasite_resistance
	kid.dam_pr = dam.parasite_resistance
	return kid
