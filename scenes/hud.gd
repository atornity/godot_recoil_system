extends Control

@export var shake_scale: float = 1
@export var affects_rotation = 1
@export var affects_scale = 1

@onready var camera = $"../Camera3D"


func _input(event):
	if event.is_action_pressed("action_equip_pistol"):
		$MarginContainer/VBoxContainer2/WeaponLabel.text = "[1] [2] [3] equip weapon : pistol"
	if event.is_action_pressed("action_equip_rifle"):
		$MarginContainer/VBoxContainer2/WeaponLabel.text = "[1] [2] [3] equip weapon : rifle"
	if event.is_action_pressed("action_equip_shotgun"):
		$MarginContainer/VBoxContainer2/WeaponLabel.text = "[1] [2] [3] equip weapon : shotgun"

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	process_hud_shake(delta)
	
	$MarginContainer/VBoxContainer/ShakeLabel.text = "[s] toggle shake : {0}".format(["enabled" if Globals.shake_enabled else "disabled"])
	$MarginContainer/VBoxContainer/RecoilLabel.text = "[r] toggle recoil : {0}".format(["enabled" if Globals.recoil_enabled else "disabled"])
	$MarginContainer/VBoxContainer/HudLabel.text = "[h] toggle hud shake : {0}".format(["enabled" if Globals.hud_shake_enabled else "disabled"])
	
	$MarginContainer/VBoxContainer2/SensLabel.text = "[up] [down] shange sensitivity : {0}".format([Globals.sensitivity_scale])
	

func process_hud_shake(delta: float):
	if !Globals.hud_shake_enabled:
		return
	
	var shake: Vector3 = camera.shake * shake_scale
	var shake_fov: float = camera.shake_fov * shake_scale
	
	position = Vector2(shake.y, shake.x) * (33333 / camera.fov)
	scale = Vector2(1, 1) * (1 + shake_fov * 0.005 * affects_scale) # todo: maybe fix this idk
	rotation = shake.z * (50 / camera.fov) * affects_rotation
	
