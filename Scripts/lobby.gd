extends Node3D

@export var statusText : Label

@export var joinButton : Button
@export var startButton : Button

@export var ipInput : TextEdit
@export var playerNameInput : TextEdit

@export_file_path("*.tscn") var gameScene : String

@export_file_path("*.json") var playerNames : String
var player_name_adjectives	: Array[String] = []
var player_name_nouns		: Array[String] = []

func _enter_tree():
	Network.player_connected.connect(player_connected)
	load_player_names()
	
	if OS.has_feature("dedicated_server"):
		print("Server starting...")
		on_host_clicked()
		return

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
		
	startButton.set_visible(true)
	joinButton.set_visible(false)
	
func on_start_clicked():
	Network.load_game.rpc(gameScene)
	return

func player_connected(_peer_id, player_info):
	if (_peer_id == multiplayer.get_unique_id()):
		statusText.text += "\nYou (" + player_info.name + ") Joined!"
	else:
		statusText.text += "\n" + player_info.name + " Joined!"
	return


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
