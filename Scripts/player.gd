class_name Player
extends Node3D

@export_category("Controls")
@export var maxSpeed = 2
@export var acceleration = 3
@export var networkCorrectionSpeed = 1

@export_category("Components")
@export var maskNode : Node


var moveVelocity : Vector2
var networkPosition : Vector3
var mousePressed : bool = false

var oxygen = 100.0

func _process(delta):
	if(is_multiplayer_authority()):
		var targetVelocity = Vector2.ZERO
		
		if(mousePressed):
			var screenSpacePos : Vector2 = get_viewport().get_camera_3d().unproject_position(position)
			var mousePos = get_viewport().get_mouse_position()
			
			var direction = (mousePos - screenSpacePos).normalized()
			targetVelocity = direction * maxSpeed
			
		moveVelocity += (targetVelocity - moveVelocity) * delta * acceleration
		
	var velocity3d = Vector3(moveVelocity.x, -moveVelocity.y, 0) 
	position += velocity3d * delta
	
	if(is_multiplayer_authority()):
		update_network_state.rpc(moveVelocity, position)
	elif(position.distance_squared_to(networkPosition) > 0.1):
		position += (networkPosition - position) * delta * networkCorrectionSpeed
	
func _input(event):
	# Mouse in viewport coordinates.
	if event is InputEventMouseButton:
		mousePressed = event.pressed
	
	#if event is InputEventMouseButton || event is InputEventMouseMotion:
	#	mousePos = event.position
	
@rpc
func update_network_state(newVelocity : Vector2, newPosition : Vector3):
	moveVelocity = newVelocity
	networkPosition = newPosition
	
@rpc("any_peer", "call_local")
func set_masked_state(active : bool):
	maskNode.set_visible(active)
