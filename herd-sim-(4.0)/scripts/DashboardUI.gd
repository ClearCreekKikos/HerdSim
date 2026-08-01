extends Control

@export var goat_item_scene: PackedScene # Reference to a GoatListItemUI.tscn (optional)
@export var auction_dialog_scene: PackedScene

# UI Node Outlines
@onready var cash_label = $StatsBar/CashLabel
@onready var feed_label = $StatsBar/FeedLabel
@onready var weather_label = $StatsBar/WeatherLabel
@onready var day_label = $StatsBar/DayLabel

@onready var p1_label = $PasturePanel/P1Label
@onready var p2_label = $PasturePanel/P2Label
@onready var p1_active = $PasturePanel/P1Active
@onready var p2_active = $PasturePanel/P2Active

@onready var upgrades_container = $UpgradesPanel/UpgradesWrap
@onready var herd_title_label = $HerdPanel/HerdTitle
@onready var herd_container = $HerdPanel/HerdScroll/HerdList
@onready var ledger_log = $LedgerPanel/LedgerScroll/LedgerLog

# Details Modal Nodes
@onready var details_modal = $DetailsModal
@onready var details_name = $DetailsModal/VBox/NameLabel
@onready var details_stats = $DetailsModal/VBox/StatsLabel
@onready var details_sire = $DetailsModal/VBox/Pedigree/Sire
@onready var details_dam = $DetailsModal/VBox/Pedigree/Dam
@onready var details_sire_sire = $DetailsModal/VBox/Pedigree/SireSire
@onready var details_sire_dam = $DetailsModal/VBox/Pedigree/SireDam
@onready var details_dam_sire = $DetailsModal/VBox/Pedigree/DamSire
@onready var details_dam_dam = $DetailsModal/VBox/Pedigree/DamDam
@onready var details_treat_btn = $DetailsModal/VBox/DetailsActions/TreatBtn

var selected_goat: Goat = null

func _ready():
	GameManager.state_changed.connect(_on_state_changed)
	_on_state_changed()

func _on_state_changed():
	_update_stats()
	_update_pastures()
	_update_upgrades()
	_update_herd_list()
	_update_ledger()

func _update_stats():
	cash_label.text = "Ranch Cash: $%0.2f" % GameManager.cash
	feed_label.text = "Feed: %0.0f lbs" % GameManager.feed_lbs
	weather_label.text = "Weather: " + GameManager.weather
	day_label.text = "Day: %d" % GameManager.day_count

func _update_pastures():
	p1_label.text = "Pasture 1: %0.0f%% Grass" % GameManager.grass_level_1
	p2_label.text = "Pasture 2: %0.0f%% Grass" % GameManager.grass_level_2
	
	p1_active.visible = (GameManager.current_pasture == 1)
	p2_active.visible = (GameManager.current_pasture == 2)

func _update_upgrades():
	# Clear previous upgrades
	for child in upgrades_container.get_children():
		child.queue_free()

	# Spawn chips dynamically
	if GameManager.has_guard_donkey:
		_add_upgrade_label("Guard Donkey 🫏", Color.AMBER)
	if GameManager.has_medical_station:
		_add_upgrade_label("Medical Clinic 💊", Color.TOMATO)
	if GameManager.has_automated_waterers:
		_add_upgrade_label("Auto Irrigation 💧", Color.DODGER_BLUE)
	if GameManager.has_quarantine_pen:
		_add_upgrade_label("Quarantine Pen 🚧", Color.ORANGE)

func _add_upgrade_label(text: String, color: Color):
	var lbl = Label.new()
	lbl.text = " " + text + " "
	# Basic stylebox coloring
	var style = StyleBoxFlat.new()
	style.bg_color = color.darkened(0.5)
	style.corner_radius_top_left = 6
	style.corner_radius_top_right = 6
	style.corner_radius_bottom_left = 6
	style.corner_radius_bottom_right = 6
	lbl.add_theme_stylebox_override("normal", style)
	upgrades_container.add_child(lbl)

func _update_herd_list():
	# Clear list
	for child in herd_container.get_children():
		child.queue_free()

	herd_title_label.text = "Active Herd (%d / %d Goats - Barn Lvl %d)" % [GameManager.herd.size(), GameManager.get_herd_capacity(), GameManager.barn_level]

	for goat in GameManager.herd:
		var item = HBoxContainer.new()
		var name_lbl = Label.new()
		name_lbl.text = " %s [%s] - %s " % [goat.name, goat.breed, goat.get_gender_display()]
		name_lbl.size_flags_horizontal = SIZE_EXPAND_FILL
		item.add_child(name_lbl)
		
		# Tap detector on listing row
		var btn = Button.new()
		btn.text = "Details / Pedigree"
		btn.pressed.connect(func(): _show_goat_details(goat))
		item.add_child(btn)

		var action_btn = Button.new()
		if goat.is_sick:
			var cost = 10.0 if GameManager.has_medical_station else 25.0
			action_btn.text = "Treat ($%0.0f)" % cost
			action_btn.pressed.connect(func(): GameManager.treat_goat(goat.id))
			action_btn.add_theme_color_override("font_color", Color.RED)
		else:
			action_btn.text = "Auction"
			action_btn.pressed.connect(func(): _start_auction_process(goat))
			action_btn.add_theme_color_override("font_color", Color.GREEN)
		item.add_child(action_btn)

		herd_container.add_child(item)

func _update_ledger():
	ledger_log.text = "\n".join(GameManager.ledger)

func _on_rotate_pastures_pressed():
	GameManager.rotate_pastures()

func _on_advance_day_pressed():
	GameManager.next_day()

func _show_goat_details(goat: Goat):
	selected_goat = goat
	details_name.text = goat.name + " Pedigree Details"
	details_stats.text = (
		"Breed: %s\nAge: %d months\nWeight: %0.1f lbs\n" +
		"Worm Resistance: %0.0f%%\nGrowth Rate: %0.2fx\nStatus: %s"
	) % [
		goat.breed, goat.age_months, goat.weight_lbs,
		goat.parasite_resistance * 100, goat.growth_rate,
		goat.get_status_display()
	]

	# Set pedigree nodes
	details_sire.text = "Sire:\n%s\n(PR: %0.0f%%)" % [goat.sire_name, goat.sire_pr * 100]
	details_dam.text = "Dam:\n%s\n(PR: %0.0f%%)" % [goat.dam_name, goat.dam_pr * 100]
	
	details_sire_sire.text = "G-Sire:\n" + goat.sire_sire_name
	details_sire_dam.text = "G-Dam:\n" + goat.sire_dam_name
	
	details_dam_sire.text = "G-Sire:\n" + goat.dam_sire_name
	details_dam_dam.text = "G-Dam:\n" + goat.dam_dam_name

	# Show treatment option if sick
	details_treat_btn.visible = goat.is_sick
	var cost = 10.0 if GameManager.has_medical_station else 25.0
	details_treat_btn.text = "Deworm ($%0.0f)" % cost

	details_modal.visible = true

func _on_details_close_pressed():
	details_modal.visible = false

func _on_details_treat_pressed():
	if selected_goat:
		GameManager.treat_goat(selected_goat.id)
		details_modal.visible = false

func _start_auction_process(goat: Goat):
	var dialog = auction_dialog_scene.instantiate()
	add_child(dialog)
	dialog.setup(goat)
