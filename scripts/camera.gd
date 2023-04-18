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
@export var fire_rate: float = 0.18

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

@export var shake_scale: float = 0.1

@export var target_fov: float = 70
@export var sensitivity = Vector2i(5, 5)

var look_rotation = transform.basis.get_euler()

# shooty shoot
@onready var shoot_sound = $RifleAudio as AudioStreamPlayer3D
var is_shooting = false
var shots_fired = 0
var can_shoot = true
var shoot_time: float = 0
var shoot_impulse: float = 1

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
	switch_weapon_input(event)
	mouse_input(event)


func _process(delta):
	process_shooting(delta)
	process_shake(delta)
	process_recoil(delta)
	
	# apply recoil and shake to camera rotation
	transform.basis = Basis.from_euler(look_rotation + recoil + shake)
	fov = target_fov + shake_fov


func mouse_input(event):
	if Input.mouse_mode != Input.MOUSE_MODE_CAPTURED: return
	
	if event is InputEventMouseMotion:
		# the distance the mouse traveled scaled by sensitivity
		var mouse_delta = event.relative * Vector2(sensitivity.x, sensitivity.y) * 0.001 * Globals.sensitivity_scale
		
		look_rotation.y -= mouse_delta.x
		look_rotation.x -= mouse_delta.y
		
		recoil_compensation(mouse_delta)


@warning_ignore("shadowed_variable")
func shoot(recoil: Vector3):
	var ray = $RayCast3D as RayCast3D
	
	if ray.is_colliding():
		var coll = ray.get_collider()
		if coll.has_method("apply_impulse"):
			var pos = ray.global_position - coll.global_position
			coll.apply_impulse(-basis.z * shoot_impulse, pos * 0.5)
		$HitMarkAudio.play()
	
	if Globals.audio_enabled:
		shoot_sound.play()
	if Globals.shake_enabled:
		add_shake(Vector3(randf_range(-0.3, 0.3), randf_range(-0.3, 0.3), randf_range(-1, 1)) * shake_scale, 60 * shake_scale)
	if Globals.recoil_enabled:
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


func switch_weapon_input(event):
	if event.is_action_pressed("action_equip_pistol"):
		$SwitchWeaponAudio.play()
		shoot_sound = $PistolAudio
		fire_mode = FireMode.MANUAL
		fire_rate = 0.07
		recoil_scale = 0.9
		shake_scale = 0.05
		shoot_impulse = 1.5
	if event.is_action_pressed("action_equip_rifle"):
		$SwitchWeaponAudio.play()
		shoot_sound = $RifleAudio
		fire_mode = FireMode.AUTOMATIC
		fire_rate = 0.18
		recoil_scale = 1
		shake_scale = 0.1
		shoot_impulse = 1
	if event.is_action_pressed("action_equip_shotgun"):
		$SwitchWeaponAudio.play()
		shoot_sound = $ShotgunAudio
		fire_mode = FireMode.MANUAL
		fire_rate = 0.6
		recoil_scale = 3
		shake_scale = 0.4
		shoot_impulse = 8


@warning_ignore("shadowed_variable")
func add_recoil(recoil: Vector3):
	target_recoil += recoil 


func process_recoil(delta: float):
	# we don't need to do any of this if recoil is zero
	if target_recoil == Vector3.ZERO and recoil == Vector3.ZERO:
		return
	
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
	# we don't need to do any of this if recoil is zero
	if target_recoil == Vector3.ZERO and recoil == Vector3.ZERO:
		return
	
	# x axis
	# you can read this as "if we're componsating for recoil in this direction"
	if target_recoil.x < 0 && mouse_delta.y < 0:
		# if we go past 0, we set recoil to 0
		# and add the existing target_recoil to look_rotation
		if target_recoil.x - mouse_delta.y > 0:
			look_rotation.x += target_recoil.x
			target_recoil.x = 0
		# otherwise, we substract mouse delta from target_recoil 
		# and add mouse delta to look_rotation
		else:
			look_rotation.x += mouse_delta.y
			target_recoil.x -= mouse_delta.y
	
	elif target_recoil.x > 0 && mouse_delta.y > 0:
		if target_recoil.x - mouse_delta.y < 0:
			look_rotation.x += target_recoil.y
			target_recoil.x = 0
		else:
			look_rotation.x += mouse_delta.y
			target_recoil.x -= mouse_delta.y
	
	# do the same for the smooth recoil
	# might not be necesarry
	if recoil.x < 0 && mouse_delta.y < 0:
		if recoil.x - mouse_delta.y > 0:
			recoil.x = 0
		else:
			recoil.x -= mouse_delta.y
	
	elif recoil.x > 0 && mouse_delta.y > 0:
		if recoil.x - mouse_delta.y < 0:
			recoil.x = 0
		else:
			recoil.x -= mouse_delta.y
	
	# y axis
	if target_recoil.y < 0 && mouse_delta.x < 0:
		if target_recoil.y - mouse_delta.y > 0:
			look_rotation.y += target_recoil.y
			target_recoil.y = 0
		else:
			look_rotation.y += mouse_delta.x
			target_recoil.y -= mouse_delta.x
	
	elif target_recoil.y > 0 && mouse_delta.x > 0:
		if target_recoil.y - mouse_delta.x < 0:
			look_rotation.y += target_recoil.y
			target_recoil.y = 0
		else:
			look_rotation.y += mouse_delta.x
			target_recoil.y -= mouse_delta.x
	
	if recoil.y < 0 && mouse_delta.x < 0:
		if recoil.y - mouse_delta.x > 0:
			recoil.y = 0
		else:
			recoil.y -= mouse_delta.x
	
	elif recoil.y > 0 && mouse_delta.x > 0:
		if recoil.y - mouse_delta.x < 0:
			recoil.y = 0
		else:
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
