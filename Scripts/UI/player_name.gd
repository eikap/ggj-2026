extends HBoxContainer

@onready var playerNameLabel: Label = $"Player Name"

@export var playerName = "Player Name":
	set(value):
		playerName = value
		setPlayerName(playerName)
		
			
@export var isLocalPlayer = false:
	set(value):
		isLocalPlayer = value
		setPlayerName(playerName)

func setPlayerName(newName: String) -> void:
	if playerNameLabel:
		if isLocalPlayer:
			playerNameLabel.text = newName + " (You)"
		else:
			playerNameLabel.text = newName

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	setPlayerName(playerName)
