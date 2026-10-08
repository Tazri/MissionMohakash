extends Control
## Main menu screen. Wires up the three buttons and plays the intro animation.

## The scene opened by START GAME. Change it in the Inspector (or here).
@export_file("*.tscn") var start_scene := "res://scenes/levels/level_01.tscn"

const HOW_TO_PLAY_SCENE := preload("res://scenes/how_to_play/how_to_play.tscn")
const PRESS_DELAY := 0.16        # lets the press animation play before acting
const PARALLAX_PIXELS := 14.0    # how far the background drifts with the mouse

@onready var background: TextureRect = $Background
@onready var menu_column: Control = $MenuColumn
@onready var logo: TextureRect = $MenuColumn/Logo
@onready var version_label: Label = $VersionLabel
@onready var start_button: GameMenuButton = %StartButton
@onready var how_button: GameMenuButton = %HowToPlayButton
@onready var quit_button: GameMenuButton = %QuitButton

var _locked := false
var _overlay: Control


func _ready() -> void:
	UIStyle.style_label(version_label, 17, Color(0.5, 0.6, 0.82, 0.75), false, 3)

	start_button.pressed.connect(_on_start_pressed)
	how_button.pressed.connect(_on_how_to_play_pressed)
	quit_button.pressed.connect(_on_quit_pressed)

	# Slight zoom so the parallax drift never exposes the background edge.
	background.scale = Vector2.ONE * 1.04
	background.resized.connect(func(): background.pivot_offset = background.size / 2.0)
	background.pivot_offset = background.size / 2.0

	AudioManager.play_music()
	_play_intro()

	# Web builds can't close the tab, so hide Quit there.
	if OS.has_feature("web"):
		quit_button.visible = false


func _process(delta: float) -> void:
	# Gentle mouse parallax on the background.
	var size_v := get_viewport_rect().size
	var m := (get_viewport().get_mouse_position() / size_v - Vector2(0.5, 0.5)).clampf(-0.5, 0.5)
	var target := -m * 2.0 * PARALLAX_PIXELS
	background.position = background.position.lerp(target, 1.0 - exp(-4.0 * delta))


func _play_intro() -> void:
	modulate.a = 0.0
	logo.modulate.a = 0.0
	version_label.modulate.a = 0.0
	var buttons: Array[GameMenuButton] = [start_button, how_button, quit_button]
	for b in buttons:
		b.modulate.a = 0.0
	var t := create_tween().set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	t.tween_property(self, "modulate:a", 1.0, 0.5)
	t.parallel().tween_property(logo, "modulate:a", 1.0, 0.8).set_delay(0.1)
	var delay := 0.35
	for b in buttons:
		t.parallel().tween_property(b, "modulate:a", 1.0, 0.45).set_delay(delay)
		delay += 0.12
	t.parallel().tween_property(version_label, "modulate:a", 1.0, 0.6).set_delay(0.8)


# Keyboard / gamepad support: first arrow press focuses START GAME.
func _unhandled_input(event: InputEvent) -> void:
	if _overlay or not menu_column.visible:
		return
	if get_viewport().gui_get_focus_owner() == null \
			and (event.is_action_pressed("ui_down") or event.is_action_pressed("ui_up")):
		start_button.grab_focus()
		get_viewport().set_input_as_handled()


# ----------------------------------------------------------------- buttons
func _on_start_pressed() -> void:
	if _locked:
		return
	_locked = true
	await get_tree().create_timer(PRESS_DELAY).timeout
	SceneTransition.change_scene(start_scene)


func _on_how_to_play_pressed() -> void:
	if _locked:
		return
	_locked = true
	await get_tree().create_timer(PRESS_DELAY).timeout
	_overlay = HOW_TO_PLAY_SCENE.instantiate()
	add_child(_overlay)
	_overlay.closed.connect(_on_how_to_play_closed)
	menu_column.visible = false


func _on_how_to_play_closed() -> void:
	_overlay = null
	menu_column.visible = true
	_locked = false


func _on_quit_pressed() -> void:
	if _locked:
		return
	_locked = true
	await get_tree().create_timer(PRESS_DELAY).timeout
	SceneTransition.quit_game()
