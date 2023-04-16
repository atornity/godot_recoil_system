extends Camera3D

enum FireMode {
	AUTOMATIC,
	MANUAL,
}

enum RecoilMode {
	PROCEDURAL,
	PATTERN,
}

@export var fire_mode = FireMode.AUTOMATIC
@export var fire_rate: float = 0.2
@export var recoil_mode = RecoilMode.PROCEDURAL
# this is a bad pattern lol
@export var recoil_pattern := [
	Vector3(0.1 , -0.04, 0),
	Vector3(0.11 , -0.05, 0),
	Vector3(0.12 , 0.04, 0),
	Vector3(0.12 , 0.03, 0),
	Vector3(0.11 , -0.08, 0),
	Vector3(0.11 , 0.1, 0),
	Vector3(0.11 , 0.07, 0),
	Vector3(0.11 , -0.04, 0),
	Vector3(0.12 , -0.02, 0),
	Vector3(0.13 , 0.05, 0),
]
@export var recoil_scale: float = 1
@export var sensitivity = Vector2i(5, 5)

var look_rotation = transform.basis.get_euler()

var is_shooting = false
var shots_fired = 0
var can_shoot = true
var shoot_time: float = 0

var target_recoil = Vector3.ZERO
var recoil = Vector3.ZERO
var recoil_speed: float = 5
var recoil_return_speed: float = 0.5

func _input(event):
	mouse_input(event)


func _process(delta):
	if Globals.lock_mouse_x:
		look_rotation.x = 0
	
	process_shooting(delta)
	process_recoil(delta)
	
	transform.basis = Basis.from_euler(look_rotation + recoil)


func mouse_input(event):
	if !Globals.mouse_enabled || Input.mouse_mode != Input.MOUSE_MODE_CAPTURED: return
	
	if event is InputEventMouseMotion:
		var mouse_delta = event.relative * Vector2(sensitivity.x, sensitivity.y) * 0.001
		
		look_rotation.y -= mouse_delta.x
		look_rotation.x -= mouse_delta.y
		
		recoil_compensation(mouse_delta)


func process_shooting(delta: float):
	match fire_mode:
		FireMode.AUTOMATIC:
			if Input.is_action_just_pressed("action_shoot"):
				is_shooting = true
			if Input.is_action_just_released("action_shoot"):
				is_shooting = false
		FireMode.MANUAL:
			is_shooting = Input.is_action_just_pressed("action_shoot")
	
	if !can_shoot:
		shoot_time += delta
		if shoot_time >= fire_rate:
			shoot_time = 0
			can_shoot = true
	
	if is_shooting and can_shoot:
		match recoil_mode:
			RecoilMode.PROCEDURAL:
				add_recoil(Vector3(0.1, randf_range(-0.1, 0.1), 0) * recoil_scale)
			RecoilMode.PATTERN:
				var i = min(shots_fired, recoil_pattern.size() - 1)
				add_recoil(recoil_pattern[i] * recoil_scale)
		shots_fired += 1
		can_shoot = false
	
	if !is_shooting:
		shots_fired = 0


@warning_ignore("shadowed_variable")
func add_recoil(recoil: Vector3):
	target_recoil += recoil 


func process_recoil(delta: float):
	# constantly interpolate target_recoil back to zero
	target_recoil.x -= min(sign(target_recoil.x) * delta * recoil_return_speed, abs(target_recoil.x))
	target_recoil.y -= min(sign(target_recoil.y) * delta * recoil_return_speed, abs(target_recoil.y))
	target_recoil.z -= min(sign(target_recoil.z) * delta * recoil_return_speed, abs(target_recoil.z))
	
	# interpolate recoil to target_recoil to make it smooooooooth :D
	recoil = lerp(recoil, target_recoil, delta * recoil_speed)


# when compensating for the recoil (by dragging mouse down while shooting)
# we want to remove that mouse input from the recoil so that the look rotation
# doesn't end up lower than when we started shooting
# hope this makes sense!
func recoil_compensation(mouse_delta: Vector2):
	# I'm not going to explain how any of this works sorry
	
	# x axis
	# you can read this as "if we're componsating for recoil in this direction"
	if target_recoil.x < 0 && mouse_delta.y < 0:
		# if we go past 0, we set recoil to 0
		# and add the existing recoil to look_rotation
		if target_recoil.x - mouse_delta.y > 0:
			look_rotation.x += target_recoil.x
			recoil.x -= target_recoil.x
			target_recoil.x = 0
		# otherwise, we substract mouse delta from recoil 
		# and add mouse delta to look_rotation
		else:
			look_rotation.x += mouse_delta.y
			target_recoil.x -= mouse_delta.y
			recoil.x -= mouse_delta.y
	
	elif target_recoil.x > 0 && mouse_delta.y > 0:
		if target_recoil.x - mouse_delta.y < 0:
			look_rotation.x += target_recoil.y
			recoil.x -= target_recoil.y
			target_recoil.x = 0
		else:
			look_rotation.x += mouse_delta.y
			target_recoil.x -= mouse_delta.y
			recoil.x -= mouse_delta.y
	
	# y axis
	if target_recoil.y < 0 && mouse_delta.x < 0:
		if target_recoil.y - mouse_delta.y > 0:
			look_rotation.y += target_recoil.y
			recoil.y -= target_recoil.y
			target_recoil.y = 0
		else:
			look_rotation.y += mouse_delta.x
			target_recoil.y -= mouse_delta.x
			recoil.y -= mouse_delta.x
	
	elif target_recoil.y > 0 && mouse_delta.x > 0:
		if target_recoil.y - mouse_delta.x < 0:
			look_rotation.y += target_recoil.y
			recoil.y -= target_recoil.y
			target_recoil.y = 0
		else:
			look_rotation.y += mouse_delta.x
			target_recoil.y -= mouse_delta.x
			recoil.y -= mouse_delta.x
	
	# z axis
	# jk, we don't need that
	# ~phew
