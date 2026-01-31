class_name Player
extends Node3D

@export_category("Controls")
@export var maxSpeed = 2
@export var acceleration = 3
@export var networkCorrectionSpeed = 1

@export_category("Gameplay Features")
@export var maskNode : Node
@export var detectionArea : Area3D
@export var oxygenLabel : Label3D
@export var oxygenDepletionRate = 5


var moveVelocity : Vector2
var networkPosition : Vector3
var mousePressed : bool = false

var oxygen = 100.0
var victory = false

var targetPlayer : Player

func _process(delta):
	if(victory):
		if(oxygenLabel):
			oxygenLabel.text = "Won!"
			
		return
	
	if(oxygen <= 0):
		if(oxygenLabel):
			oxygenLabel.text = "Dead!"
		
		return
	
	if(is_multiplayer_authority()):
		var targetVelocity = Vector2.ZERO
		
		if(mousePressed):
			var screenSpacePos : Vector2 = get_viewport().get_camera_3d().unproject_position(position)
			var mousePos = get_viewport().get_mouse_position()
			
			var direction = (mousePos - screenSpacePos).normalized()
			targetVelocity = direction * maxSpeed
			
		moveVelocity += (targetVelocity - moveVelocity) * delta * acceleration
		
		if(has_mask()):
			oxygen = clamp(oxygen + oxygenDepletionRate * delta, 0, 100)
		else:
			oxygen = clamp(oxygen - oxygenDepletionRate * delta, 0, 100)
			
		pick_current_target()
		
		if(targetPlayer && Input.is_action_just_pressed("interact")):
			var masked = targetPlayer.has_mask()
			if(has_mask() != masked):
				set_masked_state.rpc(masked)
				targetPlayer.set_masked_state.rpc(!masked)
		
	var velocity3d = Vector3(moveVelocity.x, -moveVelocity.y, 0) 
	position += velocity3d * delta
	
	if(oxygenLabel):
		oxygenLabel.text = "Oxygen: %d%%" % oxygen
	
	if(is_multiplayer_authority()):
		update_network_state.rpc(moveVelocity, position, oxygen, victory)
	elif(position.distance_squared_to(networkPosition) > 0.1):
		position += (networkPosition - position) * delta * networkCorrectionSpeed
	
func _input(event):
	if(!is_multiplayer_authority()):
		return
		
	# Mouse in viewport coordinates.
	if event is InputEventMouseButton:
		mousePressed = event.pressed
	
	#if event is InputEventMouseButton || event is InputEventMouseMotion:
	#	mousePos = event.position
	
func pick_current_target():
	var overlaps = detectionArea.get_overlapping_areas()
		
	var closestPlayer : Player
	var closestDistance = 1000000
		
	for area in overlaps:
		if !(area.get_parent() is Player):
			victory = true
			break
			
		var overlappingPlayer = area.get_parent() as Player
		var distanceToPlayer = position.distance_squared_to(overlappingPlayer.position)
		
		if (distanceToPlayer < closestDistance):
			closestPlayer = overlappingPlayer
			closestDistance = distanceToPlayer
			
	targetPlayer = closestPlayer
	
@rpc
func update_network_state(newVelocity : Vector2, newPosition : Vector3, newOxygen, newVictory):
	moveVelocity = newVelocity
	networkPosition = newPosition
	oxygen = newOxygen
	victory = newVictory
	
@rpc("any_peer", "call_local")
func set_masked_state(active : bool):
	maskNode.set_visible(active)
	
func has_mask():
	return maskNode.visible
