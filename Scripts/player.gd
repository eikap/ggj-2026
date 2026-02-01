class_name Player
extends Node3D

@export_category("Controls")
@export var maxSpeed = 2
@export var acceleration = 3
@export var rotationSnappiness = 3
@export var networkCorrectionSpeed = 1
@export var movementRangeX = 3
@export var movementFloorY = 0

@export_category("Gameplay Features")
@export var diver : Diver
@export var detectionArea : Area3D
@export var oxygenLabel : Label3D
@export var oxygenDepletionRate = 8

signal gave_away_mask
signal lost_mask

var moveVelocity : Vector2
var networkPosition : Vector3

var mousePressed : bool = false
var mouseDoubleClick : bool = false
var mouseLastClickTime : int = 0

var oxygen = 100.0
var survived = false

var stealTarget : Player
var giveTarget : Player
var crushID : int

func _process(delta):
	var crushPlayer : Player = get_crush_player()
	if(crushPlayer && crushPlayer.oxygen <= 0):
		if(oxygenLabel):
			oxygenLabel.text = "Crush Dead!"
			
			return
			
	
	if(survived):
		if(oxygenLabel):
			oxygenLabel.text = "Survived!"
			
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
			
			var speedMultiplier = 1
			if(has_mask()):
				speedMultiplier = 0.9
			targetVelocity = direction * maxSpeed * speedMultiplier
			
		moveVelocity += (targetVelocity - moveVelocity) * delta * acceleration
		
		if(has_mask()):
			oxygen = clamp(oxygen + oxygenDepletionRate * delta, 0, 100)
		else:
			oxygen = clamp(oxygen - oxygenDepletionRate * delta, 0, 100)
			
		pick_current_target()
		
		var shouldInteract = (Input.is_action_just_pressed("interact") || mouseDoubleClick)
		if shouldInteract:
			if has_mask() && giveTarget && !giveTarget.has_mask():
				set_masked_state.rpc(false, true, true)
				giveTarget.set_masked_state.rpc(true, true, true)
			elif !has_mask() && stealTarget && stealTarget.has_mask():
				set_masked_state.rpc(true, false, true)
				stealTarget.set_masked_state.rpc(false, false, true)
		
	var velocity3d = Vector3(moveVelocity.x, -moveVelocity.y, 0) 
	position += velocity3d * delta
	
	position.x = clamp(position.x, -movementRangeX, movementRangeX)
	position.y = max(position.y, movementFloorY)
	#position = clamp(position, Vector3(-movementRangeX, movementFloorY, 0), Vector3(movementRangeX, movementFloorY, 0))
	
	mouseDoubleClick = false
	
	#var weight = velocity3d.length()
	#if(weight > 0):
	#	var targetRotation = Vector3.LEFT.angle_to(velocity3d)
	#	rotation = Vector3(0, 0, targetRotation)
		#rotation = rotation.slerp(Vector3(0, 0, targetRotation), delta * weight * rotationSnappiness)
	
	if(oxygenLabel):
		var localPlayer : Player = Network.get_local_player_node()
		
		var name = ""
		if Network.players.has(get_multiplayer_authority()):
			name = Network.players[get_multiplayer_authority()].name
		
		if(localPlayer && localPlayer.crushID == get_multiplayer_authority()):
			oxygenLabel.text = "[<3] %s [<3]\nOxygen: %d%%" % [name,oxygen]
		else:
			oxygenLabel.text = "%s\nOxygen: %d%%" % [name,oxygen]
		
	
	if(is_multiplayer_authority()):
		update_network_state.rpc(moveVelocity, position, oxygen, survived)
	elif(position.distance_squared_to(networkPosition) > 0.1):
		position += (networkPosition - position) * delta * networkCorrectionSpeed
	
func _input(event):
	if(!is_multiplayer_authority()):
		return
		
	# Mouse in viewport coordinates.
	if event is InputEventMouseButton:
		mousePressed = event.pressed
		
		if mousePressed:
			var currTime = Time.get_ticks_msec()
			var timeSinceLastClick = currTime - mouseLastClickTime
			
			if timeSinceLastClick < 300:
				mouseDoubleClick = true
				mouseLastClickTime = 0
			else:
				mouseLastClickTime = Time.get_ticks_msec()
			
	#if event is InputEventMouseButton || event is InputEventMouseMotion:
	#	mousePos = event.position
	
func pick_current_target():
	var overlaps = detectionArea.get_overlapping_areas()
		
	var closestPlayer : Player
	var closestDistance = 1000000
		
	for area in overlaps:
		if !(area.get_parent() is Player):
			survived = true
			break
			
		var overlappingPlayer = area.get_parent() as Player
		var distanceToPlayer = position.distance_squared_to(overlappingPlayer.position)
		
		if get_crush_player() == overlappingPlayer:
			giveTarget = overlappingPlayer
		elif (distanceToPlayer < closestDistance):
			closestPlayer = overlappingPlayer
			closestDistance = distanceToPlayer
			
	stealTarget = closestPlayer
	
	
	
@rpc
func update_network_state(newVelocity : Vector2, newPosition : Vector3, newOxygen, newVictory):
	moveVelocity = newVelocity
	networkPosition = newPosition
	oxygen = newOxygen
	survived = newVictory
	
@rpc("any_peer", "call_local")
func set_masked_state(active : bool, willing : bool, emitEvent : bool):
	diver.mask.set_visible(active)
	
	if !willing && !active && is_multiplayer_authority():
		moveVelocity = Vector2.ZERO
	
	if emitEvent && !active:
		if willing:
			gave_away_mask.emit()
		else:
			lost_mask.emit()
	
@rpc("any_peer", "call_local")
func set_crush_id(crush):
	crushID = crush
	
@rpc("any_peer", "call_local")
func assign_color(randomNumber : int):
	diver.set_material_type(randomNumber)
	
func get_crush_player():
	if(!crushID):
		return null
		
	if(!Network.players.has(crushID)):
		return null
	
	return Network.players[crushID].node
	
func has_mask():
	return diver.mask.visible
