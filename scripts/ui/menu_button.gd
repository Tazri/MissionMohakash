@tool
class_name GameMenuButton
extends Button
## Reusable menu button (scene: scenes/ui/menu_button.tscn).
##
## Set title / subtitle / icon / style in the Inspector, then connect the
## normal Button `pressed` signal. Hover + press animations and sounds are
## handled here, so every button in the game feels the same.
##
## Hover sound plays ONCE per hover: a button is "hovered" when the mouse is
## inside it OR it has keyboard/gamepad focus, and the sound only fires when
## that state changes from false -> true.

enum Style { PRIMARY, SECONDARY, DANGER }

@export var title := "BUTTON":
	set(v):
		title = v
		if is_node_ready():
			_apply_content()
@export var subtitle := "":
	set(v):
		subtitle = v
		if is_node_ready():
			_apply_content()
@export var icon_texture: Texture2D:
	set(v):
		icon_texture = v
		if is_node_ready():
			_apply_content()
@export var button_style: Style = Style.SECONDARY:
	set(v):
		button_style = v
		if is_node_ready():
			_apply_style()

@export_group("Animation")
@export var hover_scale := 1.03
@export var hover_slide := 10.0         # pixels the button slides right on hover
@export var press_scale := 0.965
@export var anim_time := 0.18

# name -> [bg, border, bg_hover, border_hover, glow, title, subtitle, icon]
const PALETTES := {
	Style.PRIMARY: {
		"bg": Color(0.09, 0.34, 0.88, 0.96), "border": Color(0.36, 0.60, 1.0, 1.0),
		"bg_h": Color(0.16, 0.46, 1.0, 1.0), "border_h": Color(0.72, 0.87, 1.0, 1.0),
		"glow": Color(0.22, 0.52, 1.0, 0.60),
		"title": Color(1, 1, 1), "sub": Color(0.82, 0.90, 1.0), "icon": Color(1, 1, 1),
	},
	Style.SECONDARY: {
		"bg": Color(0.035, 0.075, 0.19, 0.84), "border": Color(0.17, 0.25, 0.43, 1.0),
		"bg_h": Color(0.07, 0.17, 0.40, 0.94), "border_h": Color(0.40, 0.65, 1.0, 1.0),
		"glow": Color(0.22, 0.52, 1.0, 0.38),
		"title": Color(0.95, 0.97, 1.0), "sub": Color(0.62, 0.70, 0.86), "icon": Color(0.85, 0.92, 1.0),
	},
	Style.DANGER: {
		"bg": Color(0.27, 0.04, 0.12, 0.82), "border": Color(0.55, 0.15, 0.28, 1.0),
		"bg_h": Color(0.46, 0.07, 0.18, 0.94), "border_h": Color(1.0, 0.38, 0.48, 1.0),
		"glow": Color(1.0, 0.22, 0.32, 0.42),
		"title": Color(1, 0.95, 0.96), "sub": Color(0.88, 0.62, 0.68), "icon": Color(1.0, 0.42, 0.52),
	},
}

@onready var _visual: Control = $Visual
@onready var _panel: Panel = $Visual/Panel
@onready var _icon: TextureRect = $Visual/Content/Icon
@onready var _title: Label = $Visual/Content/Texts/Title
@onready var _subtitle: Label = $Visual/Content/Texts/Subtitle
@onready var _chevron: TextureRect = $Visual/Chevron

var _box: StyleBoxFlat
var _mouse_inside := false
var _focus_from_mouse := false
var _hovered := false
var _tween: Tween


func _ready() -> void:
	# The Button itself draws nothing - the "Visual" child does all the drawing.
	text = ""
	flat = true
	for state in ["normal", "hover", "pressed", "disabled", "focus", "hover_pressed"]:
		add_theme_stylebox_override(state, StyleBoxEmpty.new())
	mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND

	_box = StyleBoxFlat.new()
	_box.set_corner_radius_all(10)
	_box.set_border_width_all(2)
	_box.shadow_size = 0
	_panel.add_theme_stylebox_override("panel", _box)

	_apply_content()
	_apply_style()
	resized.connect(_update_pivot)
	_update_pivot()

	if Engine.is_editor_hint():
		return
	mouse_entered.connect(_on_mouse_entered)
	mouse_exited.connect(_on_mouse_exited)
	focus_entered.connect(_refresh_hover)
	focus_exited.connect(_refresh_hover)
	button_down.connect(_on_button_down)
	button_up.connect(_on_button_up)


# ----------------------------------------------------------------- appearance
func _update_pivot() -> void:
	_visual.pivot_offset = _visual.size / 2.0


func _apply_content() -> void:
	_title.text = title
	_subtitle.text = subtitle
	_subtitle.visible = subtitle != ""
	_icon.texture = icon_texture
	_icon.visible = icon_texture != null


func _apply_style() -> void:
	var p: Dictionary = PALETTES[button_style]
	_box.bg_color = p["bg"]
	_box.border_color = p["border"]
	_box.shadow_color = Color(p["glow"].r, p["glow"].g, p["glow"].b, 0.0)
	UIStyle.style_label(_title, 27, p["title"], true, 4)
	UIStyle.style_label(_subtitle, 17, p["sub"], false, 1)
	_icon.self_modulate = p["icon"]
	_chevron.self_modulate = Color(p["icon"].r, p["icon"].g, p["icon"].b, 0.75)


# ------------------------------------------------------------------ hover
func _on_mouse_entered() -> void:
	_mouse_inside = true
	_refresh_hover()


func _on_mouse_exited() -> void:
	_mouse_inside = false
	# A click gives the button focus; drop it when the mouse leaves so the
	# button doesn't stay highlighted. (Keyboard focus is left alone.)
	if _focus_from_mouse and has_focus():
		release_focus()
	_focus_from_mouse = false
	_refresh_hover()


func _gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		_focus_from_mouse = true
	elif event is InputEventKey or event is InputEventJoypadButton:
		_focus_from_mouse = false


func _refresh_hover() -> void:
	var want := (_mouse_inside or has_focus()) and not disabled
	if want == _hovered:
		return  # state unchanged -> no animation, and NO repeated sound
	_hovered = want
	if _hovered:
		AudioManager.play_hover()
	_animate_hover(_hovered)


func _animate_hover(on: bool) -> void:
	var p: Dictionary = PALETTES[button_style]
	_restart_tween()
	var t := _tween
	t.set_parallel(true).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	t.tween_property(_visual, "scale", Vector2.ONE * (hover_scale if on else 1.0), anim_time)
	t.tween_property(_visual, "position:x", hover_slide if on else 0.0, anim_time)
	t.tween_property(_visual, "modulate", Color(1.12, 1.12, 1.12) if on else Color.WHITE, anim_time)
	t.tween_property(_box, "bg_color", p["bg_h"] if on else p["bg"], anim_time)
	t.tween_property(_box, "border_color", p["border_h"] if on else p["border"], anim_time)
	t.tween_property(_box, "shadow_size", 22 if on else 0, anim_time)
	t.tween_property(_box, "shadow_color:a", p["glow"].a if on else 0.0, anim_time)
	t.tween_property(_chevron, "position:x", 6.0 if on else 0.0, anim_time)


# ------------------------------------------------------------------ press
func _on_button_down() -> void:
	AudioManager.play_click()
	_restart_tween()
	var t := _tween
	t.set_parallel(true).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	t.tween_property(_visual, "scale", Vector2.ONE * press_scale, 0.07)
	t.tween_property(_visual, "modulate", Color(1.45, 1.45, 1.45), 0.07)   # quick flash
	t.tween_property(_box, "border_color", Color.WHITE, 0.07)
	t.tween_property(_box, "shadow_size", 34, 0.07)


func _on_button_up() -> void:
	# Spring back (to hover state if the pointer is still over the button).
	var on := _hovered
	var p: Dictionary = PALETTES[button_style]
	_restart_tween()
	var t := _tween
	t.set_parallel(true).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	t.tween_property(_visual, "scale", Vector2.ONE * (hover_scale if on else 1.0), 0.22)
	t.tween_property(_visual, "modulate", Color(1.12, 1.12, 1.12) if on else Color.WHITE, 0.22)
	t.tween_property(_box, "border_color", p["border_h"] if on else p["border"], 0.22)
	t.tween_property(_box, "shadow_size", 22 if on else 0, 0.22)


func _restart_tween() -> void:
	if _tween and _tween.is_valid():
		_tween.kill()
	_tween = create_tween()
