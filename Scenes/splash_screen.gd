extends Node

func _ready():
	$AnimationPlayer.play("text fade in")

func _on_timer_timeout() -> void:
	get_tree().change_scene_to_file("res://Scenes/NetworkTest/LobbyTest.tscn")
