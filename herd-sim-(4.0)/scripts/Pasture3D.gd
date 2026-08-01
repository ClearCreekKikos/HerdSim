extends Node3D

@export var goat_scene: PackedScene # Reference to Goat3D.tscn (2.5D billboard sprite or model)
@export var donkey_scene: PackedScene # Reference to Donkey3D.tscn

# Buildings in Node tree
@onready var ground_p1 = $GroundP1
@onready var ground_p2 = $GroundP2
@onready var barn_lvl1 = $BarnLvl1
@onready var barn_lvl2 = $BarnLvl2
@onready var barn_lvl3 = $BarnLvl3
@onready var barn_lvl4 = $BarnLvl4
@onready var barn_lvl5 = $BarnLvl5
@onready var medical_station = $MedicalStation
@onready var automated_waterer_p1 = $AutomatedWatererP1
@onready var automated_waterer_p2 = $AutomatedWatererP2
@onready var quarantine_pen = $QuarantinePen
@onready var donkey_container = $DonkeyContainer
@onready var goat_container = $GoatContainer

# Dictionaries to track active instances in 3D
var spawned_goats = {}

func _ready():
	GameManager.state_changed.connect(_on_state_changed)
	_on_state_changed()



func _on_state_changed():
	_update_buildings()
	_update_grass_colors()
	_sync_goats()
	_sync_donkey()

func _update_buildings():
	# Barn visibility
	var lvl = GameManager.barn_level
	barn_lvl1.visible = (lvl == 1)
	barn_lvl2.visible = (lvl == 2)
	barn_lvl3.visible = (lvl == 3)
	barn_lvl4.visible = (lvl == 4)
	barn_lvl5.visible = (lvl == 5)

	# Other facilities
	medical_station.visible = GameManager.has_medical_station
	automated_waterer_p1.visible = GameManager.has_automated_waterers
	automated_waterer_p2.visible = GameManager.has_automated_waterers
	quarantine_pen.visible = GameManager.has_quarantine_pen

func _update_grass_colors():
	# Determine grass color based on weather and level
	var get_color = func(level: float, weather: String) -> Color:
		if weather == "Drought":
			return Color.from_hsv(0.1, 0.4, lerpf(0.4, 0.8, level / 100.0)) # Brownish dry
		elif weather == "Rainy":
			return Color.from_hsv(0.6, 0.6, lerpf(0.3, 0.7, level / 100.0)) # Deep lush green
		else:
			return Color.from_hsv(0.33, 0.65, lerpf(0.35, 0.75, level / 100.0)) # Bright pasture green

	var color1 = get_color.call(GameManager.grass_level_1, GameManager.weather)
	var color2 = get_color.call(GameManager.grass_level_2, GameManager.weather)

	# Set albedo of materials
	_set_mesh_color(ground_p1, color1)
	_set_mesh_color(ground_p2, color2)

func _set_mesh_color(mesh_instance: MeshInstance3D, color: Color):
	if mesh_instance and mesh_instance.material_override:
		mesh_instance.material_override.albedo_color = color

func _sync_goats():
	# 1. Clear dead/sold goats
	var active_ids = []
	for g in GameManager.herd:
		active_ids.append(g.id)
	
	var ids_to_remove = []
	for gid in spawned_goats:
		if not gid in active_ids:
			ids_to_remove.append(gid)
	
	for gid in ids_to_remove:
		spawned_goats[gid].queue_free()
		spawned_goats.erase(gid)

	# 2. Add or update goats
	for g in GameManager.herd:
		if not spawned_goats.has(g.id):
			# Spawn new 3D goat model
			var new_goat_node = goat_scene.instantiate()
			new_goat_node.setup(g)
			goat_container.add_child(new_goat_node)
			spawned_goats[g.id] = new_goat_node
		else:
			# Update data reference
			spawned_goats[g.id].update_goat_data(g)

func _sync_donkey():
	var has_donkey = GameManager.has_guard_donkey
	var active_donkey_node = donkey_container.get_child(0) if donkey_container.get_child_count() > 0 else null

	if has_donkey and active_donkey_node == null:
		var new_donkey = donkey_scene.instantiate()
		donkey_container.add_child(new_donkey)
	elif not has_donkey and active_donkey_node != null:
		active_donkey_node.queue_free()
