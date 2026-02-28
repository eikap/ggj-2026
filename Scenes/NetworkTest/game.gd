extends Node3D # Or Node2D.

@export var playerPrefab : PackedScene
@export_file_path("*.tscn") var lobbyScene : String

var game_started : bool = false
var game_start_timeout = 10.0

func _enter_tree():
	Network.player_disconnected.connect(player_disconnected)
	
	for playerID in Network.players.keys():
		var player = playerPrefab.instantiate();
		player.set_name("Player"+str(playerID))
		player.set_multiplayer_authority(playerID)
		
		Network.players[playerID].node = player
		
		add_child(player)

func player_disconnected(id):
	if(!Network.players.has(id)): return
	if(Network.players[id].has("node")):
		if(Network.players[id].node):
			Network.players[id].node.queue_free()

func _ready():
	# Preconfigure game.
	if !OS.has_feature("dedicated_server"):
		Network.player_loaded.rpc_id(1) # Tell the server that this peer has loaded.
		
func _process(delta: float) -> void:
	if (!is_multiplayer_authority()):
		return
	
	if (!game_started):
		game_start_timeout -= delta
		
		if(game_start_timeout <= 0):
			game_start_timeout = 10.0
			Network.end_game.rpc(lobbyScene)
		
		return
	
	var numPlayers = Network.players.size()
	
	var anyPlayerAlive = false
	for i in range(0, numPlayers):
		var playerID = Network.players.keys()[i]
		var player : Player = Network.players[playerID].node
		if (player == null): continue
		
		anyPlayerAlive = anyPlayerAlive || (player.playerState == Player.PlayerState.Alive)
		
	if (!anyPlayerAlive):
		for i in range(0, numPlayers):
			var playerID = Network.players.keys()[i]
			var player : Player = Network.players[playerID].node
			if (player == null): continue
			
			Network.end_game.rpc_id(playerID, lobbyScene)
		Network.end_game.rpc_id(1, lobbyScene)

# Called only on the server.
func start_game():
	var numPlayers = Network.players.size()
	var maskedPlayers = floor(float(numPlayers) / 2.0) #max(1, numPlayers - 2)
	game_started = true
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
