extends Node3D # Or Node2D.

@export var playerPrefab : PackedScene

func _enter_tree():
	for playerID in Network.players.keys():
		var player = playerPrefab.instantiate();
		player.set_name("Player"+str(playerID))
		player.set_multiplayer_authority(playerID)
		
		Network.players[playerID].node = player
		
		add_child(player)
		

func _ready():
	# Preconfigure game.
	if !OS.has_feature("dedicated_server"):
		Network.player_loaded.rpc_id(1) # Tell the server that this peer has loaded.
	

# Called only on the server.
func start_game():
	var firstPlayerID = Network.players.keys()[0]
	var firstPlayer : Player = Network.players[firstPlayerID].node
	
	firstPlayer.set_masked_state.rpc(true)
	
	# All peers are ready to receive RPCs in this scene.
	pass
