extends Node

# Autoload named Lobby

# These signals can be connected to by a UI lobby scene or the game scene.
signal player_connected(peer_id, player_info)
signal player_disconnected(peer_id)
signal server_disconnected

const PORT = 7001
const DEFAULT_SERVER_IP = "wss://ggj26-ws.nas.danieljbradshaw.co.uk" # IPv4 localhost
const MAX_CONNECTIONS = 20

# This will contain player info for every player,
# with the keys being each player's unique IDs.
var players = {}

# This is the local player info. This should be modified locally
# before the connection is made. It will be passed to every other peer.
# For example, the value of "name" can be set to something the player
# entered in a UI scene.
var player_info = {"name": "Name"}

var players_loaded = 0



func _ready():
	multiplayer.peer_connected.connect(_on_player_connected)
	multiplayer.peer_disconnected.connect(_on_player_disconnected)
	multiplayer.connected_to_server.connect(_on_connected_ok)
	multiplayer.connection_failed.connect(_on_connected_fail)
	multiplayer.server_disconnected.connect(_on_server_disconnected)


func join_game(address = ""):
	if OS.has_feature("production"):
		address = DEFAULT_SERVER_IP
	
	var peer = WebSocketMultiplayerPeer.new()
	var error = peer.create_client(address)
	if error:
		return error
	multiplayer.multiplayer_peer = peer
	return OK


func create_game():
	var peer = WebSocketMultiplayerPeer.new()
	var error = peer.create_server(PORT)
	if error:
		return error
	multiplayer.multiplayer_peer = peer

	if !OS.has_feature("dedicated_server"):
		players[1] = player_info
		player_connected.emit(1, player_info)
		
	return OK


func remove_multiplayer_peer():
	multiplayer.multiplayer_peer = OfflineMultiplayerPeer.new()
	players.clear()


# When the server decides to start the game from a UI scene,
# do Lobby.load_game.rpc(filepath)
@rpc("any_peer", "call_local", "reliable")
func load_game(game_scene_path):
	get_tree().change_scene_to_file(game_scene_path)


# Every peer will call this when they have loaded the game scene.
@rpc("any_peer", "call_local", "reliable")
func player_loaded():
	if multiplayer.is_server():
		players_loaded += 1
		if players_loaded == players.size():
			$/root/Game.start_game()
			players_loaded = 0


# When a peer connects, send them my player info.
# This allows transfer of all desired data for each player, not only the unique ID.
func _on_player_connected(id):
	if !OS.has_feature("dedicated_server"):
		_register_player.rpc_id(id, player_info)


@rpc("any_peer", "reliable")
func _register_player(new_player_info):
	var new_player_id = multiplayer.get_remote_sender_id()
	players[new_player_id] = new_player_info
	player_connected.emit(new_player_id, new_player_info)


func _on_player_disconnected(id):
	if(players[id].node):
		players[id].node.queue_free()
	
	players.erase(id)
	player_disconnected.emit(id)


func _on_connected_ok():
	print("Connected OK!")
	var peer_id = multiplayer.get_unique_id()
	players[peer_id] = player_info
	player_connected.emit(peer_id, player_info)


func _on_connected_fail():
	remove_multiplayer_peer()


func _on_server_disconnected():
	remove_multiplayer_peer()
	players.clear()
	server_disconnected.emit()
	
func get_local_player_node():
	if OS.has_feature("dedicated_server"):
		return null
		
	if !Network.players.has(multiplayer.get_unique_id()):
		return null
	
	return Network.players[multiplayer.get_unique_id()].node
