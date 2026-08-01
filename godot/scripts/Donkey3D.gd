extends Node3D

var target_pos: Vector3
var speed: float = 1.8
var random = RandomNumberGenerator.new()

func _ready():
	random.randomize()
	_teleport_to_active_pasture()
	_set_new_target()

func _process(delta: float):
	_update_movement(delta)

func _teleport_to_active_pasture():
	var start_x = -15.0 if GameManager.current_pasture == 1 else 15.0
	global_position = Vector3(start_x, 0.0, random.randf_range(-10, 10))

func _set_new_target():
	var tx = random.randf_range(-28, -8) if GameManager.current_pasture == 1 else random.randf_range(8, 28)
	var tz = random.randf_range(-22, 22)
	target_pos = Vector3(tx, 0.0, tz)

func _update_movement(delta: float):
	# Pasture boundary check
	var in_p1 = (global_position.x < 0)
	var should_be_p1 = (GameManager.current_pasture == 1)
	if in_p1 != should_be_p1:
		_set_new_target()

	var direction = target_pos - global_position
	direction.y = 0.0
	var distance = direction.length()

	if distance > 0.2:
		global_position += direction.normalized() * speed * delta
	else:
		_set_new_target()
