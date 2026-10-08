extends Control
## PLACEHOLDER first mission. Replace this scene with your real gameplay.
## (Keep the "back to menu" bit so you can always return.)

const MAIN_MENU := "res://scenes/main_menu/main_menu.tscn"

@onready var title_label: Label = %Title
@onready var info_label: Label = %Info
@onready var back_button: GameMenuButton = %BackButton


func _ready() -> void:
	UIStyle.style_label(title_label, 64, Color.WHITE, true, 10)
	UIStyle.style_label(info_label, 24, UIStyle.COLOR_TEXT_DIM, false, 2)
	back_button.pressed.connect(_back_to_menu)
	AudioManager.fade_out_music(1.2)   # in-game music would start here instead


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel"):
		_back_to_menu()


func _back_to_menu() -> void:
	await get_tree().create_timer(0.16).timeout
	SceneTransition.change_scene(MAIN_MENU)
