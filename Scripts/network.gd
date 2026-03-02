extends Node

# Autoload named Lobby

# These signals can be connected to by a UI lobby scene or the game scene.
signal player_connected(peer_id, player_info)
signal player_disconnected(peer_id)
signal players_changed

signal server_disconnected
signal server_connection_failed

const PORT = 7001
const DEFAULT_SERVER_IP = "wss://ggj26-ws.nas.danieljbradshaw.co.uk" # IPv4 localhost
const DEFAULT_SERVER_IP_2 = "wss://balticlight.ovh/ggj26-ws" # IPv4 localhost
const MAX_CONNECTIONS = 20
const GAME_PROTOCOL_VERSION = 2

# This will contain player info for every player,
# with the keys being each player's unique IDs.
var players = {}

# This is the local player info. This should be modified locally
# before the connection is made. It will be passed to every other peer.
# For example, the value of "name" can be set to something the player
# entered in a UI scene.
var player_info = {"name": "Name", "node" : null, "game_protocol_version": GAME_PROTOCOL_VERSION}

var players_loaded = 0
var players_launching_game = {}

var error_text = ""
static var past_round_info : Array
var game_scene : String

var disconnect_queue : Array[int]
var disconnect_delay = 0

func _ready():
	multiplayer.peer_connected.connect(_on_player_connected)
	multiplayer.peer_disconnected.connect(_on_player_disconnected)
	multiplayer.connected_to_server.connect(_on_connected_ok)
	multiplayer.connection_failed.connect(_on_connected_fail)
	multiplayer.server_disconnected.connect(_on_server_disconnected)

func _process(_delta):
	if(disconnect_delay > 0):
		disconnect_delay -= 1
		return
		
	if(multiplayer.is_server() && !disconnect_queue.is_empty()):
		for client in disconnect_queue:
			multiplayer.multiplayer_peer.disconnect_peer(client)
		
		disconnect_queue.clear()
			
func join_game(address = ""):
	if OS.has_feature("production"):
		address = DEFAULT_SERVER_IP
		
	if OS.has_feature("production2"):
		address = DEFAULT_SERVER_IP_2
	
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
	multiplayer.multiplayer_peer.close()
	multiplayer.multiplayer_peer = OfflineMultiplayerPeer.new()
	players.clear()

@rpc("any_peer", "call_remote", "reliable")
func start_game():
	if get_tree().root.name == "Game":
		return
		
	if !multiplayer.is_server():
		return
		
	players_launching_game = players.duplicate()
	players_loaded = 0
	
	load_game(game_scene)
	load_game.rpc(game_scene)

# When the server decides to start the game from a UI scene,
# do Lobby.load_game.rpc(filepath)
@rpc("authority", "call_remote", "reliable")
func load_game(game_scene_path):
	get_tree().change_scene_to_file(game_scene_path)
	
# When the server decides to start the game from a UI scene,
# do Lobby.load_game.rpc(filepath)
@rpc("any_peer", "call_local", "reliable")
func end_game(lobby_scene_path):
	past_round_info.clear()
	
	for player in players:
		var playerNode : Player = players[player].node
		var playerInfo = {}
		
		if (!playerNode): continue
		
		playerInfo.name = players[player].name
		playerInfo.state = playerNode.playerState
		past_round_info.append(playerInfo)
	
	if !OS.has_feature("dedicated_server"):
		remove_multiplayer_peer()

	get_tree().change_scene_to_file(lobby_scene_path)

# Every peer will call this when they have loaded the game scene.
@rpc("any_peer", "call_local", "reliable")
func player_loaded():
	if multiplayer.is_server():
		players_loaded += 1
		
		if players_loaded >= players_launching_game.size():
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
	
	print("Player %d connected!" % new_player_id)
	
	var has_protocol = new_player_info.has("game_protocol_version")
	
	if (!has_protocol || new_player_info.game_protocol_version != GAME_PROTOCOL_VERSION):
		if (multiplayer.is_server()):
			_server_error.rpc_id(new_player_id, "Outdated game version!")
			disconnect_queue.append(new_player_id)
			disconnect_delay = 2
		
		print("Protocol mismatch (", new_player_info.game_protocol_version if has_protocol else "invalid", "), rejecting!")
		return
	
	players[new_player_id] = new_player_info
	player_connected.emit(new_player_id, new_player_info)
	players_changed.emit()

@rpc
func _server_error(error):
	error_text = error

func _on_player_disconnected(id):
	print("Player %d connected!" % id)
	
	if !players.has(id):
		print("(nothing to clean up)")
		return
	
	player_disconnected.emit(id)
	players.erase(id)
	players_launching_game.erase(id)
	players_changed.emit()


func _on_connected_ok():
	print("Connected OK!")
	var peer_id = multiplayer.get_unique_id()
	players[peer_id] = player_info
	player_connected.emit(peer_id, player_info)


func _on_connected_fail():
	remove_multiplayer_peer()
	server_connection_failed.emit()

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
