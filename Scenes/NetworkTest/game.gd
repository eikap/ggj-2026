extends Node3D # Or Node2D.

@export var playerPrefab : PackedScene

func _enter_tree():
	for playerID in Network.players:
		var player = playerPrefab.instantiate();
		player.set_name("Player"+str(playerID))
		player.set_multiplayer_authority(playerID)
		add_child(player)

func _ready():
	# Preconfigure game.
	Network.player_loaded.rpc_id(1) # Tell the server that this peer has loaded.
	

# Called only on the server.
func start_game():
	# All peers are ready to receive RPCs in this scene.
	pass
