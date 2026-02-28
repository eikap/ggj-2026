extends Node3D

@export var statusText : Label

@export var joinButton : Button
@export var startButton : Button

@export var ipInput : TextEdit
@export var playerNameInput : TextEdit

@export_file_path("*.tscn") var gameScene : String
@export var playerNameUIElement : PackedScene

@export_file_path("*.json") var playerNames : String
var player_name_adjectives	: Array[String] = []
var player_name_nouns		: Array[String] = []

const min_num_players : int = 2

func _enter_tree():
	Network.game_scene = gameScene
	Network.player_connected.connect(player_connected)
	Network.player_disconnected.connect(player_disconnected)
	load_player_names()
	
	if (Network.past_round_info.size() > 0):
		
		for roundinfo in Network.past_round_info:
			var playerUINode = playerNameUIElement.instantiate()
			playerUINode.playerName = roundinfo.name
			playerUINode.setPlayerStatus(Player.PlayerStateString[roundinfo.state])
			$VBoxContainer/PlayerList/PlayerListContainer.add_child(playerUINode)
		
		statusText.text = Network.past_round_info[0].name
	
	if OS.has_feature("dedicated_server"):
		print("Server starting...")
		on_host_clicked()
		return
		
func _ready():
	update_lobby_status()

func on_host_clicked():
	Network.player_info.name = generate_random_name()
	statusText.text = "Hosting..."
	var result = Network.create_game()
	
	if(result != OK):
		statusText.text = "Failed!"
		print("Failed!")
		return
		
	print("Success!")
	startButton.set_visible(true)
	joinButton.set_visible(false)
	
func on_join_clicked():
	statusText.text = "Joining..."
	Network.player_info.name = generate_random_name()
	var result = Network.join_game(ipInput.text)
	
	if(result != OK):
		statusText.text = "Failed!"
		return
	
	var playerList = $VBoxContainer/PlayerList/PlayerListContainer
	for n in playerList.get_children():
		playerList.remove_child(n)
		n.queue_free() 
	
	startButton.set_visible(false)
	joinButton.set_visible(false)
	
func on_start_clicked():
	Network.start_game.rpc_id(0)
	return

func update_lobby_status():
	if (!is_multiplayer_authority()):
		return
	var playerNum = Network.players.size()
	var readyToGo = playerNum >= min_num_players
	
	var status = "Waiting for Players %s/%s" % [playerNum, min_num_players]
	
	if (readyToGo): status = "Ready to Play!"
	
	if(is_multiplayer_authority()):
		update_lobby_state.rpc(
			status,
			readyToGo
		)

func player_connected(_peer_id, player_info):
	var playerUINode = playerNameUIElement.instantiate()
	playerUINode.isLocalPlayer = _peer_id == multiplayer.get_unique_id()
	playerUINode.playerName = player_info.name
	$VBoxContainer/PlayerList/PlayerListContainer.add_child(playerUINode)
	
	update_lobby_status()

func player_disconnected(_peer_id):
	var playerUINodes = $VBoxContainer/PlayerList/PlayerListContainer.get_children()
	
	for playerUINode in playerUINodes:
		if (playerUINode.playerName == Network.players[_peer_id].name):
			$VBoxContainer/PlayerList/PlayerListContainer.remove_child(playerUINode)
			playerUINode.queue_free()
		
	update_lobby_status()

func _on_fullscreen_toggled(toggled_on: bool) -> void:
	if toggled_on == true:
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN)
	else:
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)
		
func load_player_names() -> bool:
	var json_text : String = FileAccess.open(playerNames, FileAccess.READ).get_as_text()
	var parse_result = JSON.parse_string(json_text)
	
	if parse_result == null:
		push_error("Failed to parse player names JSON")
		return false
		
	player_name_adjectives.assign(parse_result["adjectives"])
	player_name_nouns.assign(parse_result["nouns"])
	return true
	
func generate_random_name() -> String:
	var adj = player_name_adjectives[randi() % player_name_adjectives.size()]
	var noun = player_name_nouns[randi() % player_name_nouns.size()]
	return "%s %s" % [adj, noun]
	
@rpc()
func update_lobby_state(lobbyState: String, readyToStart: bool):
	statusText.text = lobbyState
	startButton.set_visible(readyToStart)
