extends CanvasLayer
## Autoload "SceneTransition": black fade used when changing scenes / quitting.
##   SceneTransition.change_scene("res://some_scene.tscn")
##   SceneTransition.quit_game()

const FADE_TIME := 0.35

var _rect: ColorRect
var _busy := false


func _ready() -> void:
	layer = 100
	process_mode = Node.PROCESS_MODE_ALWAYS
	_rect = ColorRect.new()
	_rect.color = Color.BLACK
	_rect.modulate.a = 0.0
	_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_rect.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(_rect)


func change_scene(path: String) -> void:
	if _busy:
		return
	_busy = true
	_rect.mouse_filter = Control.MOUSE_FILTER_STOP  # block clicks while fading
	await _fade(1.0)
	var err := get_tree().change_scene_to_file(path)
	if err != OK:
		push_error("SceneTransition: could not load '%s' (error %d)" % [path, err])
	await get_tree().process_frame
	await _fade(0.0)
	_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_busy = false


func quit_game() -> void:
	if _busy:
		return
	_busy = true
	_rect.mouse_filter = Control.MOUSE_FILTER_STOP
	AudioManager.fade_out_music(FADE_TIME)
	await _fade(1.0)
	get_tree().quit()


func _fade(to_alpha: float) -> void:
	var tw := create_tween()
	tw.tween_property(_rect, "modulate:a", to_alpha, FADE_TIME)
	await tw.finished
