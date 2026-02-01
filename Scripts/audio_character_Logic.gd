extends AudioStreamPlayer2D
@onready var audio_character: AudioStreamPlayer2D = $"."
@onready var audio_voice: AudioStreamPlayer2D = $Audio_Voice
@onready var audio_bubbles: AudioStreamPlayer2D = $Audio_Bubbles
@onready var audio_mask_pass: AudioStreamPlayer2D = $Audio_Mask_Pass
@onready var audio_mask_steal: AudioStreamPlayer2D = $Audio_Mask_Steal
@onready var oxygen_level_test: VSlider = $"Oxygen level test"
@export var player: Player

var fadeOutGate = false

func _ready() -> void:
	player.gave_away_mask.connect(gaveAwayMask)
	player.lost_mask.connect(lostMask)

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta: float) -> void:
	if  player.oxygen < 80 && player.oxygen != 0 && audio_voice.playing == false:
		audio_voice.volume_db = -80
		audio_bubbles.volume_db = -80
		audio_bubbles.play()
		audio_voice.play()
		var fadeIn = get_tree().create_tween()
		fadeIn.tween_property(audio_voice,"volume_db",0,1)
		fadeIn.tween_property(audio_bubbles,"volume_db",0,1)
		fadeOutGate = true
		print("play")

	if  (player.oxygen >= 80 || player.oxygen == 0) && audio_voice.playing == true:
		if fadeOutGate == true:
			var fadeOut = get_tree().create_tween()
			fadeOut.tween_property(audio_bubbles,"volume_db",-80,0.5)
			fadeOut.tween_property(audio_voice,"volume_db",-80,0.5)
			print("fadeout start")
			fadeOutGate = false
		if audio_bubbles.volume_db == -80:
				audio_voice.stop()
				audio_bubbles.stop()
				print("sound stopped")

func gaveAwayMask():
	audio_mask_pass.play()

func lostMask():
	audio_mask_steal.play()
