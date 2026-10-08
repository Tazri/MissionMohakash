class_name UIStyle
extends RefCounted
## Shared look-and-feel helpers (fonts + colours) so every screen matches.
##
## FONTS: drop your own fonts into assets/fonts/ and they are picked up
## automatically:
##     assets/fonts/title.ttf   (headings, buttons - e.g. Orbitron / Rajdhani Bold)
##     assets/fonts/body.ttf    (small text)
## If they don't exist we fall back to installed system fonts.

const TITLE_FONT_PATH := "res://assets/fonts/title.ttf"
const BODY_FONT_PATH := "res://assets/fonts/body.ttf"

const COLOR_TEXT := Color(0.93, 0.96, 1.0)
const COLOR_TEXT_DIM := Color(0.62, 0.70, 0.85)
const COLOR_ACCENT := Color(0.35, 0.60, 1.0)

static var _cache := {}


static func _base_font(path: String, bold: bool) -> Font:
	if ResourceLoader.exists(path):
		return load(path)
	var sf := SystemFont.new()
	sf.font_names = PackedStringArray([
		"Orbitron", "Rajdhani", "Exo 2", "Oxanium", "Saira",
		"Bahnschrift", "Segoe UI", "Roboto", "Arial", "Helvetica",
	])
	sf.font_weight = 700 if bold else 400
	return sf


## Returns a font with extra letter-spacing (the wide tracked look of the reference).
static func get_font(bold: bool, spacing: int) -> Font:
	var key := "%s_%d" % [bold, spacing]
	if _cache.has(key):
		return _cache[key]
	var fv := FontVariation.new()
	fv.base_font = _base_font(TITLE_FONT_PATH if bold else BODY_FONT_PATH, bold)
	fv.spacing_glyph = spacing
	_cache[key] = fv
	return fv


## Applies font / size / colour to a Label in one call.
static func style_label(label: Label, size: int, color: Color, bold := false, spacing := 0) -> void:
	label.add_theme_font_override("font", get_font(bold, spacing))
	label.add_theme_font_size_override("font_size", size)
	label.add_theme_color_override("font_color", color)
