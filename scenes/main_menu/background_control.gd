extends Control

@onready var intro_video: VideoStreamPlayer = $IntroVideo
@onready var loop_video: VideoStreamPlayer = $LoopVideo


func _ready() -> void:
	intro_video.play();


func _on_intro_video_finished() -> void:
	print("INTRO VIDEO FINISHED!")

	

	# Show loop video
	loop_video.show()
	loop_video.paused = false
	loop_video.loop = true;
	loop_video.play();
	# Hide intro
	#intro_video.hide()
	#intro_video.stop()
