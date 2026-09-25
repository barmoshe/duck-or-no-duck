class_name RotateHint
extends Control
## Landscape only: a web page can't lock orientation, so in portrait this covers the
## screen with a "turn your phone" card (and main pauses the run).

var t := 0.0


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	set_anchors_preset(Control.PRESET_FULL_RECT)
	process_mode = Node.PROCESS_MODE_ALWAYS


func active() -> bool:
	return size.y > size.x * 1.05


func _process(dt: float) -> void:
	position = Vector2.ZERO
	size = get_viewport_rect().size
	t += dt
	visible = active()
	if visible:
		mouse_filter = Control.MOUSE_FILTER_STOP
		queue_redraw()
	else:
		mouse_filter = Control.MOUSE_FILTER_IGNORE


func _draw() -> void:
	draw_rect(Rect2(Vector2.ZERO, size), Pal.INK)
	var c := (size * 0.5).floor()
	var a := sin(t * 2.0) * 0.8
	var phone := PackedVector2Array([Vector2(-14, -24), Vector2(14, -24), Vector2(14, 24), Vector2(-14, 24)])
	for i in phone.size():
		phone[i] = c + Vector2(0, -30) + phone[i].rotated(clampf(a, 0.0, PI * 0.5))
	draw_colored_polygon(phone, Pal.c("grey", 3))
	Ui.text(self, c + Vector2(0, 30), "TURN YOUR PHONE", Pal.c("gold", 3), Ui.bold(), 16, 1)
	Ui.text(self, c + Vector2(0, 44), "Duck or no duck ?! plays sideways", Ui.DIM, Ui.small(), 8, 1)
