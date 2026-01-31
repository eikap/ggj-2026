extends Node3D

@export var statusText : Label

@export var ipInput : TextEdit
@export var playerNameInput : TextEdit

func _enter_tree():
	Network.player_connected.connect(player_connected)
	
	if OS.has_feature("dedicated_server"):
		print("Server starting...")
		on_host_clicked()
		return

func on_host_clicked():
	if(!playerNameInput.text.is_empty()):
		Network.player_info.name = playerNameInput.text
	statusText.text = "Hosting..."
	var result = Network.create_game()
	
	if(result != OK):
		statusText.text = "Failed!"
		print("Failed!")
		return
		
	print("Success!")
	return
	
func on_join_clicked():
	statusText.text = "Joining..."
	if(!playerNameInput.text.is_empty()):
		Network.player_info.name = playerNameInput.text
	var result = Network.join_game(ipInput.text)
	
	if(result != OK):
		statusText.text = "Failed!"
		
	return

func player_connected(_peer_id, player_info):
	statusText.text += "\n" + player_info.name + " Joined!"
	return
