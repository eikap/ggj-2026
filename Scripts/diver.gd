class_name Diver
extends Node3D

@export var mask : Node3D
@export var animPlayer : AnimationPlayer

@export var materials : Array[Material]
@export var coloredNodes : Array[MeshInstance3D]

func set_material_type(randomNumber):
	if materials.is_empty():
		return
	
	var idx : int = abs(randomNumber) % materials.size()
	for node in coloredNodes:
		node.set_surface_override_material(0, materials[idx])
