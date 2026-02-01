extends Node3D # Or Node2D.

@export var playerPrefab : PackedScene
@export_file_path("*.tscn") var lobbyScene : String

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
		
func _process(delta: float) -> void:
	if (!is_multiplayer_authority()):
		return
	
	var numPlayers = Network.players.size()
	
	var anyPlayerAlive = false
	for i in range(0, numPlayers):
		var playerID = Network.players.keys()[i]
		var player : Player = Network.players[playerID].node
		
		anyPlayerAlive = anyPlayerAlive || (player.playerState == Player.PlayerState.Alive)
		
	if (!anyPlayerAlive):
		Network.end_game.rpc(lobbyScene)

# Called only on the server.
func start_game():
	var numPlayers = Network.players.size()
	var maskedPlayers = floor(float(numPlayers) / 2.0) #max(1, numPlayers - 2)
	
	for i in range(0, maskedPlayers):
		var playerID = Network.players.keys()[i]
		var player : Player = Network.players[playerID].node
		
		player.set_masked_state.rpc(true, true, false)
	
	for i in range(0, numPlayers):
		var playerID = Network.players.keys()[i]
		var player : Player = Network.players[playerID].node
		
		player.set_crush_id.rpc(Network.players.keys()[(i + 1) % numPlayers])
		player.assign_color.rpc(i)
	
	# All peers are ready to receive RPCs in this scene.
	pass
