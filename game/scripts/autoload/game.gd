extends Node
## Autoload "Game": pixel scaling (fit_pixels), safe area, fonts, settings and the meta
## save (genetics, achievements, Selective Pressure, codex).

const TARGET_SHORT := 225.0
const SAVE_PATH := "user://duck_meta.json"

var rng := RandomNumberGenerator.new()
var save_enabled := true

# settings
var sound := true
var music := true
var shake := true

# meta
var unlocked_genetics: Array = ["pioneer", "forager", "angler", "omni_gut"]
var achievements: Dictionary = {}  # id -> true
var pressure_unlocked := 0
var codex_species: Dictionary = {}  # id -> times eaten
var codex_evos: Dictionary = {}  # id -> true
var stats := {"runs": 0, "wins": 0, "best_level": 0, "best_duck": 0, "kills": 0}

# chosen for the next run
var genetic := "pioneer"
var genetics: Array = []  # the two picked for the next run
var pressure := 0

var _fitted := Vector2i.ZERO
var _fonts := {}
var _insets: Array[float] = [0.0, 0.0, 0.0, 0.0]
var _insets_for := Vector2i(-1, -1)


func _ready() -> void:
	rng.randomize()
	load_meta()
	if DisplayServer.get_name() == "headless":
		return
	get_window().size_changed.connect(fit_pixels)
	fit_pixels()


func _process(_dt: float) -> void:
	if DisplayServer.get_name() != "headless" and get_window().size != _fitted:
		fit_pixels()


# ------------------------------------------------------------------ pixels
func fit_pixels() -> void:
	var win := get_window()
	_fitted = win.size
	var size := Vector2(win.size)
	if size.y <= 0.0:
		return
	var k := pixel_scale()
	win.content_scale_mode = Window.CONTENT_SCALE_MODE_VIEWPORT
	win.content_scale_aspect = Window.CONTENT_SCALE_ASPECT_IGNORE
	win.content_scale_size = Vector2i(ceili(size.x / k), ceili(size.y / k))


func pixel_scale() -> float:
	if DisplayServer.get_name() == "headless":
		return 1.0
	var sz := get_window().size
	return maxf(1.0, roundf(float(mini(sz.x, sz.y)) / TARGET_SHORT))


func is_touch() -> bool:
	return OS.has_feature("mobile") or OS.has_feature("web_ios") or OS.has_feature("web_android") or DisplayServer.is_touchscreen_available()


## The screen area free of notches and the home bar, in virtual pixels.
func safe_rect(view: Vector2) -> Rect2:
	if DisplayServer.get_name() == "headless":
		return Rect2(Vector2.ZERO, view)
	if OS.has_feature("web"):
		var ins := _web_insets()
		var tl := Vector2(ins[3] * view.x, ins[0] * view.y)
		var br := Vector2(ins[1] * view.x, ins[2] * view.y)
		return Rect2(tl, view - tl - br)
	if not OS.has_feature("mobile"):
		return Rect2(Vector2.ZERO, view)
	var sr := Rect2(DisplayServer.get_display_safe_area())
	var k := pixel_scale()
	return Rect2(sr.position / k, sr.size / k).intersection(Rect2(Vector2.ZERO, view))


func _web_insets() -> Array[float]:
	var sz := get_window().size
	if sz == _insets_for:
		return _insets
	_insets_for = sz
	_insets = [0.0, 0.0, 0.0, 0.0]
	var raw := str(JavaScriptBridge.eval("window.duckSafeArea ? window.duckSafeArea() : ''", true))
	var parts := raw.split(",")
	if parts.size() == 4:
		for i in 4:
			_insets[i] = clampf(parts[i].to_float(), 0.0, 0.25)
	return _insets


func web_build() -> String:
	if not OS.has_feature("web"):
		return ""
	return str(JavaScriptBridge.eval("window.duckBuild || ''", true))


## Pixel fonts (SIL OFL): "small"/"bold" = Silkscreen (8 px grid), "body" = Pixelify Sans.
func font(kind := "body") -> Font:
	if _fonts.has(kind):
		return _fonts[kind]
	var path: String = {
		"small": "res://assets/fonts/Silkscreen-Regular.ttf",
		"bold": "res://assets/fonts/Silkscreen-Bold.ttf",
		"body": "res://assets/fonts/PixelifySans.ttf",
	}.get(kind, "")
	var f: Font = ThemeDB.fallback_font
	if path != "" and ResourceLoader.exists(path):
		var ff := load(path) as FontFile
		if ff:
			ff = ff.duplicate() as FontFile
			ff.antialiasing = TextServer.FONT_ANTIALIASING_NONE
			ff.hinting = TextServer.HINTING_NONE
			ff.subpixel_positioning = TextServer.SUBPIXEL_POSITIONING_DISABLED
			ff.force_autohinter = false
			f = ff
	_fonts[kind] = f
	return f


# ------------------------------------------------------------------ meta
func unlock(genetic_id: String) -> bool:
	if genetic_id in unlocked_genetics:
		return false
	unlocked_genetics.append(genetic_id)
	return true


func achieve(id: String) -> bool:
	if achievements.has(id):
		return false
	achievements[id] = true
	save_meta()
	return true


func save_meta() -> void:
	if not save_enabled:
		return
	var d := {
		"v": 1, "sound": sound, "music": music, "shake": shake,
		"genetics": unlocked_genetics, "achievements": achievements, "pressure_unlocked": pressure_unlocked,
		"codex_species": codex_species, "codex_evos": codex_evos, "stats": stats,
		"genetic": genetic, "pressure": pressure,
	}
	var tmp := SAVE_PATH + ".tmp"
	var f := FileAccess.open(tmp, FileAccess.WRITE)
	if f == null:
		return
	f.store_string(JSON.stringify(d))
	f.close()
	DirAccess.rename_absolute(ProjectSettings.globalize_path(tmp), ProjectSettings.globalize_path(SAVE_PATH))


func load_meta() -> void:
	if not FileAccess.file_exists(SAVE_PATH):
		return
	var txt := FileAccess.get_file_as_string(SAVE_PATH)
	var d = JSON.parse_string(txt)
	if typeof(d) != TYPE_DICTIONARY:
		return
	sound = bool(d.get("sound", true))
	music = bool(d.get("music", true))
	shake = bool(d.get("shake", true))
	unlocked_genetics = d.get("genetics", ["pioneer"])
	for g in ["pioneer", "forager", "angler", "omni_gut"]:
		if not g in unlocked_genetics:
			unlocked_genetics.append(g)
	achievements = d.get("achievements", {})
	pressure_unlocked = int(d.get("pressure_unlocked", 0))
	codex_species = d.get("codex_species", {})
	codex_evos = d.get("codex_evos", {})
	var s: Dictionary = d.get("stats", {})
	for k in s:
		stats[k] = s[k]
	genetic = String(d.get("genetic", "pioneer"))
	if not genetic in unlocked_genetics:
		genetic = "pioneer"
	pressure = clampi(int(d.get("pressure", 0)), 0, pressure_unlocked)


func reset_meta() -> void:
	unlocked_genetics = ["pioneer", "forager", "angler", "omni_gut"]
	achievements = {}
	pressure_unlocked = 0
	codex_species = {}
	codex_evos = {}
	stats = {"runs": 0, "wins": 0, "best_level": 0, "best_duck": 0, "kills": 0}
	genetic = "pioneer"
	pressure = 0
