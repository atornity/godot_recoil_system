extends Node

var mouse_enabled = true;
var lock_mouse_x = false


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
