extends Node

@onready var intro: VideoStreamPlayer = $IntroVideo
@onready var loop: VideoStreamPlayer = $LoopVideo

func _ready():
	loop.hide()
	intro.show()
	intro.play()

func _on_intro_video_finished():
	intro.hide()
	loop.show()
	loop.play()
