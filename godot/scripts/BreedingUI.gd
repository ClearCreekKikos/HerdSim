extends Control

@onready var buck_dropdown = $BuckSelector
@onready var doe_dropdown = $DoeSelector
@onready var comparison_stats = $ComparisonStats
@onready var breed_button = $BreedButton

var bucks: Array = []
var does: Array = []

func _ready():
	GameManager.state_changed.connect(_on_state_changed)
	buck_dropdown.item_selected.connect(_on_buck_selected)
	doe_dropdown.item_selected.connect(_on_doe_selected)
	_on_state_changed()

func _on_state_changed():
	_rebuild_dropdowns()
	_update_comparison()

func _rebuild_dropdowns():
	bucks.clear()
	does.clear()
	buck_dropdown.clear()
	doe_dropdown.clear()

	for g in GameManager.herd:
		if g.is_adult():
			if g.gender == "buck":
				bucks.append(g)
				buck_dropdown.add_item("%s (PR: %0.0f%%)" % [g.name, g.parasite_resistance * 100])
			elif g.gender == "doe" and not g.is_pregnant and not g.is_sick:
				does.append(g)
				doe_dropdown.add_item("%s (PR: %0.0f%%)" % [g.name, g.parasite_resistance * 100])

	if bucks.size() == 0:
		buck_dropdown.add_item("No active bucks!")
	if does.size() == 0:
		doe_dropdown.add_item("No open does!")

func _on_buck_selected(_index):
	_update_comparison()

func _on_doe_selected(_index):
	_update_comparison()

func _update_comparison():
	if bucks.size() == 0 or does.size() == 0:
		comparison_stats.text = "Select a Buck and Doe to review pedigree genetics."
		breed_button.disabled = true
		return

	var b_idx = buck_dropdown.selected
	var d_idx = doe_dropdown.selected
	if b_idx < 0 or d_idx < 0:
		comparison_stats.text = "Select a Buck and Doe to review pedigree genetics."
		breed_button.disabled = true
		return

	var buck = bucks[b_idx]
	var doe = does[d_idx]

	var expected_pr = (buck.parasite_resistance + doe.parasite_resistance) / 2.0
	var expected_gr = (buck.growth_rate + doe.growth_rate) / 2.0

	comparison_stats.text = (
		"MATCHUP ATTRIBUTES:\n" +
		"Buck PR: %0.0f%% | Doe PR: %0.0f%%\n" +
		"Buck GR: %0.2fx | Doe GR: %0.2fx\n\n" +
		"PREDICTED OFFSPRING TRAITS:\n" +
		"Average Parasite Resistance: %0.0f%%\n" +
		"Average Growth Rate: %0.2fx\n" +
		"Expected Birth Weight: 6 - 9 lbs\n" +
		"Gestation Period: 150 days"
	) % [
		buck.parasite_resistance * 100, doe.parasite_resistance * 100,
		buck.growth_rate, doe.growth_rate,
		expected_pr * 100, expected_gr
	]

	# Check capacity
	var capacity_reached = GameManager.herd.size() >= GameManager.get_herd_capacity()
	breed_button.disabled = capacity_reached
	if capacity_reached:
		comparison_stats.text += "\n\n⚠️ Herd capacity reached! Cannot breed new offspring."

func _on_breed_button_pressed():
	if bucks.size() == 0 or does.size() == 0: return
	var b_idx = buck_dropdown.selected
	var d_idx = doe_dropdown.selected
	if b_idx >= 0 and d_idx >= 0:
		var buck = bucks[b_idx]
		var doe = does[d_idx]
		GameManager.breed_goats(buck.id, doe.id)
