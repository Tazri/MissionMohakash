extends Control
## "How to Play" overlay shown on top of the main menu.
## Edit CONTROLS and TIPS below to match your real game.

signal closed

# [key(s), what it does]  <- PLACEHOLDER controls, change freely
const CONTROLS := [
	["W A S D / ARROWS", "Steer your ship"],
	["SHIFT", "Boost thrusters"],
	["SPACE", "Fire / interact"],
	["MOUSE", "Aim"],
	["ESC", "Pause the mission"],
]

const TIPS := [
	"Collect fuel cells to keep your engines running.",
	"Avoid asteroid fields - hull damage is permanent.",
	"Reach the next planet's orbit to complete the mission.",
]

@onready var window: PanelContainer = %Window
@onready var header: Label = %Header
@onready var subheader: Label = %SubHeader
@onready var controls_grid: GridContainer = %Controls
@onready var tips_title: Label = %TipsTitle
@onready var tips_box: VBoxContainer = %Tips
@onready var back_button: GameMenuButton = %BackButton

var _closing := false


func _ready() -> void:
	_style_window()
	UIStyle.style_label(header, 40, Color.WHITE, true, 6)
	UIStyle.style_label(subheader, 18, UIStyle.COLOR_TEXT_DIM, false, 1)
	UIStyle.style_label(tips_title, 20, UIStyle.COLOR_ACCENT, true, 4)
	_build_controls()
	_build_tips()
	back_button.pressed.connect(close)

	# Pop-in animation (wait one frame so the window has its final size)
	modulate.a = 0.0
	await get_tree().process_frame
	window.pivot_offset = window.size / 2.0
	window.scale = Vector2.ONE * 0.94
	var t := create_tween().set_parallel(true).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	t.tween_property(self, "modulate:a", 1.0, 0.25)
	t.tween_property(window, "scale", Vector2.ONE, 0.3)


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel"):
		get_viewport().set_input_as_handled()
		AudioManager.play_click()
		close()


func close() -> void:
	if _closing:
		return
	_closing = true
	await get_tree().create_timer(0.12).timeout
	var t := create_tween().set_parallel(true).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN)
	t.tween_property(self, "modulate:a", 0.0, 0.2)
	t.tween_property(window, "scale", Vector2.ONE * 0.96, 0.2)
	await t.finished
	closed.emit()
	queue_free()


func _style_window() -> void:
	var sb := StyleBoxFlat.new()
	sb.bg_color = Color(0.03, 0.06, 0.16, 0.95)
	sb.border_color = Color(0.25, 0.42, 0.80, 1.0)
	sb.set_border_width_all(2)
	sb.set_corner_radius_all(18)
	sb.shadow_color = Color(0.2, 0.45, 1.0, 0.25)
	sb.shadow_size = 40
	window.add_theme_stylebox_override("panel", sb)


func _build_controls() -> void:
	for row in CONTROLS:
		var chip := PanelContainer.new()
		var sb := StyleBoxFlat.new()
		sb.bg_color = Color(0.09, 0.17, 0.38, 0.9)
		sb.border_color = Color(0.32, 0.52, 0.95, 1.0)
		sb.set_border_width_all(1)
		sb.set_corner_radius_all(7)
		sb.content_margin_left = 14
		sb.content_margin_right = 14
		sb.content_margin_top = 6
		sb.content_margin_bottom = 6
		chip.add_theme_stylebox_override("panel", sb)
		chip.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
		var key := Label.new()
		key.text = row[0]
		UIStyle.style_label(key, 19, Color.WHITE, true, 2)
		chip.add_child(key)
		controls_grid.add_child(chip)

		var desc := Label.new()
		desc.text = row[1]
		desc.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		UIStyle.style_label(desc, 22, UIStyle.COLOR_TEXT, false, 1)
		controls_grid.add_child(desc)


func _build_tips() -> void:
	for tip in TIPS:
		var l := Label.new()
		l.text = "•  " + tip
		l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		UIStyle.style_label(l, 20, UIStyle.COLOR_TEXT_DIM, false, 1)
		tips_box.add_child(l)
