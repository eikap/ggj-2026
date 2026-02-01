extends CanvasLayer

@export var localOxygen : TextureProgressBar
@export var crushOxygen : TextureProgressBar

func _process(delta):
	if OS.has_feature("dedicated_server"):
		return
	
	var localPlayer : Player = Network.players[multiplayer.get_unique_id()].node
	
	if(!localPlayer):
		return
		
	localOxygen.value = localPlayer.oxygen
	
	if(!localPlayer.crushID):
		return
		
	if(!Network.players.has(localPlayer.crushID)):
		return
		
	var crush : Player = Network.players[localPlayer.crushID].node
	if(!crush):
		return
	
	crushOxygen.value = crush.oxygen
	
