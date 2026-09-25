class_name ArenaRing
extends Node2D
## The boss arena's edge: a ring of pixel stakes and a glowing line.

var radius := 150.0
var t := 0.0
var flood_t := 0.0


func _ready() -> void:
	z_index = -4


func _process(dt: float) -> void:
	t += dt
	flood_t = maxf(0.0, flood_t - dt)
	queue_redraw()


func _draw() -> void:
	if flood_t > 0.0:
		draw_circle(Vector2.ZERO, radius, Color(Pal.e("sky"), 0.35 * minf(1.0, flood_t)))
		for i in 30:
			var wp := Vector2(sin(i * 7.3 + t) * radius * 0.8, cos(i * 3.1) * radius * 0.8).floor()
			draw_rect(Rect2(wp, Vector2(3, 1)), Color(Pal.e("cyan"), 0.6 * minf(1.0, flood_t)))
	var n := int(radius * 0.6)
	for i in n:
		var a := TAU * i / n + t * 0.05
		var p := (Vector2(cos(a), sin(a)) * radius).floor()
		var on := (i + int(t * 8.0)) % 6 < 3
		draw_rect(Rect2(p, Vector2(2, 2)), Pal.c("red", 3) if on else Pal.c("red", 1))
	for i in 24:
		var a2 := TAU * i / 24.0
		var p2 := (Vector2(cos(a2), sin(a2)) * (radius + 3.0)).floor()
		draw_rect(Rect2(p2 + Vector2(0, -6), Vector2(2, 7)), Pal.c("brown", 1))
		draw_rect(Rect2(p2 + Vector2(0, -6), Vector2(2, 1)), Pal.c("brown", 3))
