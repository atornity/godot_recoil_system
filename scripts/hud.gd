extends Control

@export var shake_scale: float = 1
@export var affects_position: float = 1
@export var affects_rotation: float = 1
@export var affects_scale: float = 1

@onready var camera = $"../Camera3D"

var hide = false


func _input(event):
	if event.is_action_pressed("action_equip_pistol"):
		$MarginContainer/VBoxContainer2/WeaponLabel.text = "[1] [2] [3] equip weapon : pistol"
	if event.is_action_pressed("action_equip_rifle"):
		$MarginContainer/VBoxContainer2/WeaponLabel.text = "[1] [2] [3] equip weapon : rifle"
	if event.is_action_pressed("action_equip_shotgun"):
		$MarginContainer/VBoxContainer2/WeaponLabel.text = "[1] [2] [3] equip weapon : shotgun"
	
	if event.is_action_pressed("debug_toggle_show_hud"):
		hide = !hide
		$"../Camera3D/AimDebugRoot".visible = !hide
		$MarginContainer.visible = !hide
	
	if event.is_action_pressed("debug_toggle_show_aim"):
		$"../Camera3D/AimDebugRoot".visible = !$"../Camera3D/AimDebugRoot".visible

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	process_hud_shake(delta)
	
	# to make sure ratating/scaling is from the center rather than top left
	pivot_offset = get_viewport_rect().size / 2
	
	$MarginContainer/VBoxContainer/ShakeLabel.text = "[s] toggle shake : {0}".format(["enabled" if Globals.shake_enabled else "disabled"])
	$MarginContainer/VBoxContainer/RecoilLabel.text = "[r] toggle recoil : {0}".format(["enabled" if Globals.recoil_enabled else "disabled"])
	$MarginContainer/VBoxContainer/HudLabel.text = "[h] toggle hud shake : {0}".format(["enabled" if Globals.hud_shake_enabled else "disabled"])
	$MarginContainer/VBoxContainer/MuteLabel.text = "[m] toggle audio : {0}".format(["enabled" if Globals.audio_enabled else "disabled"])
	$MarginContainer/VBoxContainer2/SensLabel.text = "[up] [down] shange sensitivity : {0}".format([Globals.sensitivity_scale])
	

func process_hud_shake(delta: float):
	if !Globals.hud_shake_enabled:
		return
	
	var shake: Vector3 = camera.shake * shake_scale
	var shake_fov: float = camera.shake_fov * shake_scale
	var view_size = get_viewport_rect().size
	
	position = Vector2(shake.y, shake.x) * (view_size.y * 50 / camera.fov) # this still needs work
	scale = Vector2(1, 1) * (1 - shake_fov * 0.01 * affects_scale)
	rotation = shake.z * affects_rotation
	
