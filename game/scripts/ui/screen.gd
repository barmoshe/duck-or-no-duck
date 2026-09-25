class_name Screen
extends Control
## Base for full-screen pixel screens: draw() registers buttons as rects while drawing,
## _input fires a button when a tap is released over the one it started on. Input right
## after opening is ignored (0.25 s) so a tap meant for the game can't pick a card.

signal pressed(id: String)

var buttons: Array = []  # {id, r}
var down_id := ""
var open_t := 0.0
var t := 0.0


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	set_anchors_preset(Control.PRESET_FULL_RECT)
	process_mode = Node.PROCESS_MODE_ALWAYS
	visible = false


## Controls under a CanvasLayer can end up 0x0 (Wandcraft 0.3.0): size to the viewport.
func _fit() -> void:
	position = Vector2.ZERO
	size = get_viewport_rect().size


func show_screen() -> void:
	_fit()
	visible = true
	open_t = 0.0
	down_id = ""
	queue_redraw()


func hide_screen() -> void:
	visible = false
	down_id = ""


func _process(dt: float) -> void:
	_fit()
	if not visible:
		return
	open_t += dt
	t += dt
	queue_redraw()


func begin() -> void:
	buttons.clear()


func add_button(id: String, r: Rect2) -> void:
	buttons.append({"id": id, "r": r})


func hit_id(p: Vector2) -> String:
	for i in range(buttons.size() - 1, -1, -1):
		if (buttons[i]["r"] as Rect2).grow(2.0).has_point(p):
			return String(buttons[i]["id"])
	return ""


func is_down(id: String) -> bool:
	return down_id == id


func _input(event: InputEvent) -> void:
	if not visible:
		return
	if event is InputEventMouse and event.device == InputEvent.DEVICE_ID_EMULATION:
		return
	var e := make_input_local(event)
	var pos := Vector2.ZERO
	var is_press := false
	var is_release := false
	if e is InputEventScreenTouch:
		pos = e.position
		is_press = e.pressed
		is_release = not e.pressed
	elif e is InputEventMouseButton and e.button_index == MOUSE_BUTTON_LEFT:
		pos = e.position
		is_press = e.pressed
		is_release = not e.pressed
	else:
		return
	get_viewport().set_input_as_handled()
	if open_t < 0.25:
		return
	if is_press:
		down_id = hit_id(pos)
	elif is_release:
		var id := hit_id(pos)
		if id != "" and id == down_id:
			Sfx.play("click")
			press(id)
		down_id = ""


## Subclasses handle presses here (tests call it directly too).
func press(id: String) -> void:
	pressed.emit(id)


func safe() -> Rect2:
	return Game.safe_rect(size).grow(-4.0)
