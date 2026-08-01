extends Node3D

var goat_data: Goat
var target_pos: Vector3
var speed: float = 2.0
var random = RandomNumberGenerator.new()

@onready var sprite = $Sprite3D
@onready var label = $Label3D

func _ready():
	random.randomize()

func setup(p_goat: Goat):
	goat_data = p_goat
	# Randomly position within active pasture
	_teleport_to_active_pasture()
	_set_new_target()

func update_goat_data(p_goat: Goat):
	goat_data = p_goat
	_update_billboard_graphics()

func _teleport_to_active_pasture():
	var start_x = 0.0
	if GameManager.current_pasture == 1:
		start_x = random.randf_range(-30, -5)
	else:
		start_x = random.randf_range(5, 30)
	var start_z = random.randf_range(-25, 25)
	global_position = Vector3(start_x, 0.0, start_z)

func _set_new_target():
	var tx = 0.0
	if GameManager.current_pasture == 1:
		tx = random.randf_range(-30, -5)
	else:
		tx = random.randf_range(5, 30)
	var tz = random.randf_range(-25, 25)
	target_pos = Vector3(tx, 0.0, tz)

func _update_billboard_graphics():
	if not is_inside_tree() or label == null or sprite == null: return
	
	# Update floating label
	label.text = goat_data.name
	
	# Update billboard emoji
	if goat_data.is_sick:
		sprite.text = "🤒"
	elif goat_data.is_pregnant:
		sprite.text = "🤰"
	else:
		sprite.text = "🐐"

func _process(delta: float):
	if label == null: return
	# Lazy initialize UI elements once in tree
	if label.text == "":
		_update_billboard_graphics()
		
	# Verify we are in the correct pasture
	_pasture_boundary_check()

	var direction = target_pos - global_position
	direction.y = 0.0 # Keep on ground level
	var distance = direction.length()

	if distance > 0.2:
		global_position += direction.normalized() * speed * delta
	else:
		_set_new_target()

func _pasture_boundary_check():
	# If pasture changes, force goat to choose a target in the new pasture
	var in_p1 = (global_position.x < 0)
	var should_be_p1 = (GameManager.current_pasture == 1)
	if in_p1 != should_be_p1:
		_set_new_target()
