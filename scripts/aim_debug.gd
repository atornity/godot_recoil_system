extends Node3D


func _process(delta):
	basis = Basis.from_euler($"..".look_rotation)
