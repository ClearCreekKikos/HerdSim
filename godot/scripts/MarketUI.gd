extends Control

# Buttons / UI references
@onready var feed_50_btn = $FeedStore/Feed50Btn
@onready var feed_200_btn = $FeedStore/Feed200Btn

@onready var buy_buck_btn = $Livestock/BuyBuckBtn
@onready var buy_doe_btn = $Livestock/BuyDoeBtn

@onready var barn_upgrade_btn = $Upgrades/BarnUpgradeBtn
@onready var medical_upgrade_btn = $Upgrades/MedicalUpgradeBtn
@onready var waterer_upgrade_btn = $Upgrades/WatererUpgradeBtn
@onready var quarantine_upgrade_btn = $Upgrades/QuarantineUpgradeBtn

func _ready():
	GameManager.state_changed.connect(_on_state_changed)
	_on_state_changed()

func _on_state_changed():
	_update_feed_buttons()
	_update_livestock_buttons()
	_update_upgrade_buttons()

func _update_feed_buttons():
	feed_50_btn.disabled = (GameManager.cash < 50.0)
	feed_200_btn.disabled = (GameManager.cash < 180.0)

func _update_livestock_buttons():
	var cap_reached = GameManager.herd.size() >= GameManager.get_herd_capacity()
	buy_buck_btn.disabled = (GameManager.cash < 300.0 or cap_reached)
	buy_doe_btn.disabled = (GameManager.cash < 250.0 or cap_reached)

func _update_upgrade_buttons():
	var cash = GameManager.cash

	# Barn upgrade cost scales: Lvl 1->2 ($300), 2->3 ($600), 3->4 ($1200), 4->5 ($2500)
	var barn_cost = _get_barn_upgrade_cost()
	if GameManager.barn_level >= 5:
		barn_upgrade_btn.text = "Barn Maxed (Lvl 5)"
		barn_upgrade_btn.disabled = true
	else:
		barn_upgrade_btn.text = "Expand Barn (Lvl %d -> %d) | $%0.0f" % [GameManager.barn_level, GameManager.barn_level + 1, barn_cost]
		barn_upgrade_btn.disabled = (cash < barn_cost)

	# Medical Station clinic
	if GameManager.has_medical_station:
		medical_upgrade_btn.text = "Medical Station constructed 🏥"
		medical_upgrade_btn.disabled = true
	else:
		medical_upgrade_btn.text = "Build Medical Station | $450"
		medical_upgrade_btn.disabled = (cash < 450.0)

	# Automated Waterer
	if GameManager.has_automated_waterers:
		waterer_upgrade_btn.text = "Automated Waterers installed 💧"
		waterer_upgrade_btn.disabled = true
	else:
		waterer_upgrade_btn.text = "Install Automated Waterers | $350"
		waterer_upgrade_btn.disabled = (cash < 350.0)

	# Quarantine Pen
	if GameManager.has_quarantine_pen:
		quarantine_upgrade_btn.text = "Quarantine Pen constructed 🚧"
		quarantine_upgrade_btn.disabled = true
	else:
		quarantine_upgrade_btn.text = "Build Quarantine Pen | $250"
		quarantine_upgrade_btn.disabled = (cash < 250.0)

func _get_barn_upgrade_cost() -> float:
	match GameManager.barn_level:
		1: return 300.0
		2: return 600.0
		3: return 1200.0
		4: return 2500.0
		_: return 9999.0

# --- Action Triggers ---

func _on_feed_50_pressed():
	GameManager.buy_feed(50.0, 50.0)

func _on_feed_200_pressed():
	GameManager.buy_feed(200.0, 180.0)

func _on_buy_buck_pressed():
	var new_buck = Goat.new(
		"buy_buck_%d" % (randi() % 10000),
		"Buck_" + str(randi() % 100),
		"buck",
		12,
		140.0 + (randf() * 40.0),
		"Kiko" if randf() < 0.5 else "Boer",
		0.65 + (randf() * 0.25),
		0.8 + (randf() * 0.6)
	)
	GameManager.buy_goat(new_buck, 300.0)

func _on_buy_doe_pressed():
	var new_doe = Goat.new(
		"buy_doe_%d" % (randi() % 10000),
		"Doe_" + str(randi() % 100),
		"doe",
		12,
		95.0 + (randf() * 25.0),
		"Kiko" if randf() < 0.5 else "Boer",
		0.60 + (randf() * 0.25),
		0.7 + (randf() * 0.5)
	)
	GameManager.buy_goat(new_doe, 250.0)

func _on_barn_upgrade_pressed():
	GameManager.buy_upgrade("barn", _get_barn_upgrade_cost())

func _on_medical_upgrade_pressed():
	GameManager.buy_upgrade("medical", 450.0)

func _on_waterer_upgrade_pressed():
	GameManager.buy_upgrade("waterer", 350.0)

func _on_quarantine_upgrade_pressed():
	GameManager.buy_upgrade("quarantine", 250.0)
