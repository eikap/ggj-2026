extends Node3D

var owningPlayer = 0

@export var maxSpeed = 2
@export var acceleration = 3

var moveVelocity : Vector2
var mousePressed : bool = false

func _process(delta):
	if(get_multiplayer_authority() == multiplayer.get_unique_id()):
		var targetVelocity = Vector2.ZERO
		
		if(mousePressed):
			var screenSpacePos : Vector2 = get_viewport().get_camera_3d().unproject_position(position)
			var mousePos = get_viewport().get_mouse_position()
			
			var direction = (mousePos - screenSpacePos).normalized()
			targetVelocity = direction * maxSpeed
			
		moveVelocity += (targetVelocity - moveVelocity) * delta * acceleration
		update_network_state.rpc(moveVelocity)
		
	var velocity3d = Vector3(moveVelocity.x, -moveVelocity.y, 0) 
	position += velocity3d * delta
	
func _input(event):
	# Mouse in viewport coordinates.
	if event is InputEventMouseButton:
		mousePressed = event.pressed
	
	#if event is InputEventMouseButton || event is InputEventMouseMotion:
	#	mousePos = event.position
	
@rpc
func update_network_state(newVelocity):
	moveVelocity = newVelocity
