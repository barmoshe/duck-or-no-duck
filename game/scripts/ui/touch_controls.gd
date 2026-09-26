class_name TouchControls
extends Control
## Floating joystick (any touch that isn't a button, left 60% preferred) plus DASH and
## ULTIMATE buttons in the right thumb zone, and Crab's E button above them while there
## is something to use (a mushroom to eat, a ? spot to look at). Raw multi-touch in _input; touch ids are
## tracked per finger with no assumptions about their values (iOS sends huge ones).
## Mouse drag works on desktop; touch-emulated mouse events are ignored.

signal move_pressed
signal ult_pressed
signal act_pressed

const STICK_R := 22.0
const BTN_R := 15.0
const DEAD := 0.16

var vector := Vector2.ZERO
var stick_id := -99999
var stick_on := false
var base := Vector2.ZERO
var knob := Vector2.ZERO
var btns := {
	"move": {"label": "", "id": "", "cd": 0.0, "max": 1.0, "pos": Vector2.ZERO, "pressed": 0.0},
	"ult": {"label": "", "id": "", "cd": 0.0, "max": 1.0, "pos": Vector2.ZERO, "pressed": 0.0},
	"act": {"label": "", "id": "key_e", "cd": 0.0, "max": 1.0, "pos": Vector2.ZERO, "pressed": 0.0},
}
var blocked: Array[Rect2] = []
var hint_t := 0.0


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	set_anchors_preset(Control.PRESET_FULL_RECT)


func reset() -> void:
	vector = Vector2.ZERO
	stick_on = false


func _layout() -> void:
	var s := Game.safe_rect(size)
	btns["move"]["pos"] = (Vector2(s.end.x - 22, s.end.y - 36)).floor()
	btns["ult"]["pos"] = (Vector2(s.end.x - 58, s.end.y - 27)).floor()
	btns["act"]["pos"] = (Vector2(s.end.x - 44, s.end.y - 70)).floor()
	if size.x < size.y:
		btns["ult"]["pos"] = (Vector2(s.end.x - 26, s.end.y - 62)).floor()
		btns["act"]["pos"] = (Vector2(s.end.x - 58, s.end.y - 44)).floor()


func _process(dt: float) -> void:
	position = Vector2.ZERO
	size = get_viewport_rect().size
	hint_t += dt
	_layout()
	for k in btns:
		btns[k]["pressed"] = maxf(0.0, float(btns[k]["pressed"]) - dt * 5.0)
	queue_redraw()


func _hit(p: Vector2) -> String:
	for k in btns:
		if String(btns[k]["label"]) != "" and p.distance_to(btns[k]["pos"]) < BTN_R + 6.0:
			return k
	return ""


func _input(event: InputEvent) -> void:
	if not is_visible_in_tree():
		return
	if event is InputEventMouse and event.device == InputEvent.DEVICE_ID_EMULATION:
		return
	var e := make_input_local(event)
	if e is InputEventScreenTouch:
		_touch(e.index, e.pressed, e.position)
	elif e is InputEventScreenDrag:
		_drag(e.index, e.position)
	elif e is InputEventMouseButton and e.button_index == MOUSE_BUTTON_LEFT:
		_touch(-777, e.pressed, e.position)
	elif e is InputEventMouseMotion and stick_on and stick_id == -777:
		_drag(-777, e.position)


func _touch(idx: int, pressed: bool, p: Vector2) -> void:
	if pressed:
		for r in blocked:
			if r.grow(4.0).has_point(p):
				return
		var b := _hit(p)
		if b != "":
			btns[b]["pressed"] = 1.0
			if b == "move":
				move_pressed.emit()
			elif b == "act":
				act_pressed.emit()
			else:
				ult_pressed.emit()
			return
		if not stick_on:
			stick_on = true
			stick_id = idx
			base = p
			knob = p
			vector = Vector2.ZERO
			hint_t = 999.0
	elif stick_on and idx == stick_id:
		stick_on = false
		vector = Vector2.ZERO


func _drag(idx: int, p: Vector2) -> void:
	if not stick_on or idx != stick_id:
		return
	var d := p - base
	if d.length() > STICK_R:
		base = p - d.normalized() * STICK_R
		d = p - base
	knob = p
	vector = d / STICK_R
	if vector.length() < DEAD:
		vector = Vector2.ZERO


func _ring(c: Vector2, r: float, col: Color) -> void:
	var n := int(r * 2.0)
	for i in n:
		var a := TAU * i / n
		draw_rect(Rect2((c + Vector2(cos(a), sin(a)) * r).floor(), Vector2.ONE), col)


func _draw() -> void:
	if stick_on:
		draw_circle(base.floor(), STICK_R, Color(1, 1, 1, 0.08))
		_ring(base, STICK_R, Color(1, 1, 1, 0.5))
		draw_circle(knob.floor(), 8.0, Color(1, 1, 1, 0.5))
		_ring(knob, 8.0, Pal.INK)
	elif hint_t < 10.0:
		var hp := (Vector2(size.x * 0.28, size.y * 0.72)).floor()
		var a := 0.3 + 0.2 * sin(hint_t * 4.0)
		_ring(hp, STICK_R, Color(1, 1, 1, a))
		draw_circle(hp + (Vector2(sin(hint_t * 2.0), cos(hint_t * 2.0) * 0.6) * 10.0).floor(), 7.0, Color(1, 1, 1, a))
		Ui.text(self, hp + Vector2(0, STICK_R + 12), "DRAG TO MOVE", Color(1, 1, 1, a + 0.3), Ui.small(), 8, 1)
	for k in btns:
		var b: Dictionary = btns[k]
		if String(b["label"]) == "":
			continue
		var pos: Vector2 = b["pos"]
		var rdy := float(b["cd"]) <= 0.0
		var off := Vector2(0, 1) * float(b["pressed"])
		var rr := BTN_R
		var c := (pos + off).floor()
		# a round wooden button: dark outline, tan rim, parchment face with the icon
		draw_circle(pos.floor() + Vector2(0, 2), rr + 1.0, Color(0, 0, 0, 0.3))
		draw_circle(c, rr + 1.0, Ui.WOOD_OUT)
		draw_circle(c, rr, Ui.WOOD)
		draw_arc(c, rr - 0.5, PI * 1.1, PI * 1.9, 12, Ui.WOOD_HI, 1.0)
		draw_circle(c, rr - 3.0, Ui.WOOD_OUT)
		draw_circle(c, rr - 4.0, (Ui.PARCHMENT if k in ["move", "act"] else Color("feae34")) if rdy else Color("8b9bb4"))
		var ic := Icons.tex(String(b.get("id", "")))
		var isz := ic.get_size()
		draw_texture(ic, (c - isz * 0.5).floor() + Vector2(1, 0), Color.WHITE if rdy else Color(1, 1, 1, 0.6))
		if not rdy:
			var frac := float(b["cd"]) / maxf(0.01, float(b["max"]))
			draw_arc(c, (rr - 4.0) * 0.5, -PI * 0.5, -PI * 0.5 + TAU * frac, 20, Color(0.09, 0.07, 0.14, 0.55), rr - 4.0, false)
		Ui.text(self, c + Vector2(0, rr + 8), String(b["label"]), Color.WHITE, Ui.small(), 8, 1)
