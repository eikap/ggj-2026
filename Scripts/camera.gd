extends Camera3D

@export var moveSpeed = 2

func _process(delta):
	if OS.has_feature("dedicated_server"):
		return
	
	var localPlayer : Player = Network.get_local_player_node()
	
	if(!localPlayer):
		return
		
	position.y += (localPlayer.position.y - position.y) * moveSpeed * delta
