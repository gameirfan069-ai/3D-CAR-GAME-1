extends CharacterBody3D
## Arcade driving model. Stats come from car_catalog.gd through set_spec().

const CarBuilder = preload("res://scripts/car_builder.gd")
const GRAVITY := 24.0

var spec: Dictionary = {}
var max_speed := 34.0
var acceleration := 24.0
var steering_power := 1.55
var reverse_speed := 10.0
var forward_speed := 0.0
var steer_amount := 0.0
var active := false                       # menus switch driving off
var respawn_position := Vector3(0.0, 1.0, 12.0)
var _collider: CollisionShape3D


func set_spec(new_spec: Dictionary, paint_hex: String) -> void:
	spec = new_spec
	max_speed = float(spec["top"])
	acceleration = float(spec["accel"])
	steering_power = float(spec["turn"])
	var length := float(spec["length"])
	var width := float(spec["width"])
	var height := float(spec["height"])

	# Collision box reaches down to the ground so the wheels rest on the road
	if _collider == null:
		_collider = CollisionShape3D.new()
		add_child(_collider)
	var box := BoxShape3D.new()
	box.size = Vector3(width * 0.95, height * 0.85, length * 0.95)
	_collider.shape = box
	_collider.position = Vector3(0.0, height * 0.425, 0.0)

	# Swap the visual model
	if has_node("Visual"):
		var old := get_node("Visual")
		remove_child(old)
		old.queue_free()
	add_child(CarBuilder.build(spec, paint_hex))


func speed_kmh() -> float:
	return absf(forward_speed) * 3.6


func _physics_process(delta: float) -> void:
	var accel_held := active and Input.is_action_pressed("accelerate")
	var brake_held := active and Input.is_action_pressed("brake")
	if accel_held:
		forward_speed = move_toward(forward_speed, max_speed, acceleration * delta)
	elif brake_held:
		var target := -reverse_speed if forward_speed < 0.5 else 0.0
		forward_speed = move_toward(forward_speed, target, acceleration * delta * 1.4)
	else:
		forward_speed = move_toward(forward_speed, 0.0, 8.0 * delta)

	# Smoothed steering. Steering is flipped while reversing, like a real car.
	var steer_target := Input.get_axis("steer_left", "steer_right") if active else 0.0
	steer_amount = move_toward(steer_amount, steer_target, 5.0 * delta)
	if absf(forward_speed) > 0.3:
		var reverse_flip := -1.0 if forward_speed < 0.0 else 1.0
		var speed_factor := clampf(absf(forward_speed) / 8.0, 0.25, 1.0)
		var stability := 1.0 - 0.35 * clampf(absf(forward_speed) / max_speed, 0.0, 1.0)
		rotate_y(-steer_amount * reverse_flip * steering_power * speed_factor * stability * delta)

	var forward := -global_transform.basis.z
	forward.y = 0.0
	forward = forward.normalized()
	velocity.x = forward.x * forward_speed
	velocity.z = forward.z * forward_speed
	velocity.y -= GRAVITY * delta
	move_and_slide()
	# After a collision, keep only the speed that is still going forward
	forward_speed = Vector2(velocity.x, velocity.z).dot(Vector2(forward.x, forward.z))

	if global_position.y < -10.0:
		global_position = respawn_position
		global_rotation = Vector3.ZERO
		velocity = Vector3.ZERO
		forward_speed = 0.0
