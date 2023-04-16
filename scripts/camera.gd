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

@export var shake_strength: float = 0.1

@export var target_fov: float = 70
@export var sensitivity = Vector2i(5, 5)

var look_rotation = transform.basis.get_euler()

# shooty shoot
var is_shooting = false
var shots_fired = 0
var can_shoot = true
var shoot_time: float = 0

# recoil
var target_recoil = Vector3.ZERO
var recoil = Vector3.ZERO
var recoil_speed: float = 5
var recoil_return_speed: float = 0.5

# camera shake
var shake = Vector3.ZERO
var shake_vel = Vector3.ZERO
var shake_speed: float = 6
var shake_stop_speed: float = 12
var shake_return_speed: float = 40
var shake_fov: float = 0
var shake_fov_vel: float = 0


func _input(event):
	mouse_input(event)


func _process(delta):
	if Globals.lock_mouse_x:
		look_rotation.x = 0
	
	process_shooting(delta)
	process_recoil(delta)
	process_shake(delta)
	
	# apply recoil and shake to camera rotation
	transform.basis = Basis.from_euler(look_rotation + recoil + shake)
	
	fov = target_fov + shake_fov


func mouse_input(event):
	if !Globals.mouse_enabled || Input.mouse_mode != Input.MOUSE_MODE_CAPTURED: return
	
	if event is InputEventMouseMotion:
		var mouse_delta = event.relative * Vector2(sensitivity.x, sensitivity.y) * 0.001
		
		look_rotation.y -= mouse_delta.x
		look_rotation.x -= mouse_delta.y
		
		recoil_compensation(mouse_delta)


@warning_ignore("shadowed_variable")
func shoot(recoil: Vector3):
	add_shake(Vector3(randf_range(-0.3, 0.3), randf_range(-0.3, 0.3), randf_range(-1, 1)) * shake_strength, 60 * shake_strength)
	add_recoil(recoil * recoil_scale)


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
				shoot(Vector3(0.1, randf_range(-0.1, 0.1), 0))
			RecoilMode.PATTERN:
				var i = min(shots_fired, recoil_pattern.size() - 1)
				shoot(recoil_pattern[i])
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


@warning_ignore("shadowed_variable", "shadowed_variable_base_class")
func add_shake(shake: Vector3, fov: float):
	shake_vel += shake
	shake_fov_vel += fov


func process_shake(delta: float):
	shake_fov_vel = lerpf(shake_fov_vel, 0, delta * shake_stop_speed)
	shake_fov_vel -= shake_return_speed * delta * shake_fov
	shake_fov += shake_speed * delta * shake_fov_vel
	
	shake_vel = lerp(shake_vel, Vector3.ZERO, delta * shake_stop_speed)
	shake_vel -= shake_return_speed * delta * shake
	shake += shake_speed * delta * shake_vel
