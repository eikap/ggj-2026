@tool
extends Button

@onready var label: Label = $Label

@export var buttontext : String:
	set(value):
		buttontext = value
		if label:
			label.text = value



# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	$Label.text = buttontext


func _process(delta: float) -> void:
	$Label.text = buttontext
	pass
