extends Camera3D

@export var moveSpeed = 2

func _process(delta):
	if OS.has_feature("dedicated_server"):
		return
	
	var localPlayer : Player = Network.players[multiplayer.get_unique_id()].node
	
	if(!localPlayer):
		return
		
	position.y += (localPlayer.position.y - position.y) * moveSpeed * delta
