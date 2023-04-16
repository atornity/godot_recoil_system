extends Node

var mouse_enabled = true;
var lock_mouse_x = false
var recoil_enabled = true;
var shake_enabled = true;
var hud_shake_enabled = true;
var sensitivity_scale: float = 1


func _input(event):
	# allow disabling look input for debug purposes *beep* *boop*
	if event.is_action_pressed("debug_toggle_look_input"):
		mouse_enabled = !mouse_enabled
	
	# lock the mouse so we don't have to see the stupid mouse when playing :3
	# also unlock it when pressing escape so we can actually exit the game
	if Input.mouse_mode == Input.MOUSE_MODE_CAPTURED && event.is_action_pressed("mouse_release"):
		Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	elif Input.mouse_mode == Input.MOUSE_MODE_VISIBLE && event.is_action_pressed("mouse_capture"):
		Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	
	if event.is_action_pressed("debug_toggle_lock_mouse_x"):
		lock_mouse_x = !lock_mouse_x
	
	if event.is_action_pressed("debug_toggle_recoil"):
		recoil_enabled = !recoil_enabled
	
	if event.is_action_pressed("debug_toggle_hud_shake"):
		hud_shake_enabled = !hud_shake_enabled
	
	if event.is_action_pressed("debug_toggle_shake"):
		shake_enabled = !shake_enabled
	
	if event.is_action_pressed("set_mouse_sens_up"):
		sensitivity_scale += 0.1
	
	if event.is_action_pressed("set_mouse_sens_down"):
		sensitivity_scale = max(0.1, sensitivity_scale - 0.1)
