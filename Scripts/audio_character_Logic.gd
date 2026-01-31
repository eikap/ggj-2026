extends AudioStreamPlayer2D
@onready var audio_voice: AudioStreamPlayer2D = $Audio_Voice
@onready var audio_bubbles: AudioStreamPlayer2D = $Audio_Bubbles
@onready var oxygen_level_test: VSlider = $"Oxygen level test"

var volume = 0
# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta: float) -> void:
	if  oxygen_level_test.value < 80 && audio_voice.playing == false:
		audio_bubbles.play()
		audio_voice.play()
	if  oxygen_level_test.value >= 80 && audio_voice.playing == true:
		audio_bubbles.stop()
		audio_voice.stop()
