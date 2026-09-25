class_name Weather
extends CanvasLayer
## Biome weather, every 2.5-3.5 minutes for 40 s, in the biome you're standing in:
## rain (Meadow: plants regrow x3), current (Lake: water pushes everyone), heatwave
## (Desert: -1 HP/s on dry sand), blizzard (Snowfield: everyone 30% slower).
## Drawn as a screen-space overlay of falling pixels.

const KINDS := {"grass": "rain", "lake": "current", "sand": "heatwave", "snow": "blizzard"}
const NAMES := {"rain": "RAIN", "current": "CURRENT", "heatwave": "HEATWAVE", "blizzard": "BLIZZARD"}
const DESCS := {"rain": "Plants regrow fast", "current": "The water pushes everyone", "heatwave": "Dry sand burns: get in the water",
	"blizzard": "Everyone slows down"}

var world: World
var kind := ""
var t := 0.0
var next := 150.0
var push := Vector2.ZERO
var drops: Array = []


func _ready() -> void:
	layer = 4
	var c := Control.new()
	c.mouse_filter = Control.MOUSE_FILTER_IGNORE
	c.set_anchors_preset(Control.PRESET_FULL_RECT)
	c.draw.connect(_draw_overlay)
	add_child(c)
	set_meta("canvas", c)


func reset() -> void:
	kind = ""
	t = 0.0
	next = 150.0 + randf() * 40.0
	drops.clear()


func step(dt: float) -> void:
	if kind == "":
		next -= dt
		if next <= 0.0 and world.running:
			var b := world.map.biome_name_at(world.player.position)
			if KINDS.has(b):
				kind = KINDS[b]
				t = 40.0
				push = Vector2.from_angle(randf() * TAU) * 60.0
				world.banner.emit(NAMES[kind], DESCS[kind])
				Sfx.play("wind")
	else:
		t -= dt
		if t <= 0.0:
			kind = ""
			next = 150.0 + randf() * 60.0
			world.toast.emit("The weather clears")
	_particles(dt)


func _particles(dt: float) -> void:
	var c: Control = get_meta("canvas")
	c.position = Vector2.ZERO
	c.size = world.get_viewport_rect().size
	var size := c.size
	if kind in ["rain", "blizzard"] and drops.size() < (90 if kind == "rain" else 70):
		for i in 3:
			drops.append(Vector2(randf() * size.x, -4.0))
	var v := Vector2(-20, 170) if kind == "rain" else Vector2(-30 + sin(Time.get_ticks_msec() * 0.001) * 20.0, 40)
	for i in range(drops.size() - 1, -1, -1):
		drops[i] += v * dt
		if drops[i].y > size.y + 4:
			if kind in ["rain", "blizzard"]:
				drops[i] = Vector2(randf() * size.x, -4.0)
			else:
				drops.remove_at(i)
	c.queue_redraw()


func _draw_overlay() -> void:
	var c: Control = get_meta("canvas")
	match kind:
		"rain":
			c.draw_rect(Rect2(Vector2.ZERO, c.size), Color(Pal.e("navy"), 0.12))
			for d in drops:
				c.draw_rect(Rect2(d.floor(), Vector2(1, 3)), Color(Pal.e("mist"), 0.6))
		"blizzard":
			c.draw_rect(Rect2(Vector2.ZERO, c.size), Color(Pal.e("white"), 0.14))
			for d in drops:
				c.draw_rect(Rect2(d.floor(), Vector2(1, 1)), Pal.e("white"))
		"heatwave":
			c.draw_rect(Rect2(Vector2.ZERO, c.size), Color(Pal.e("orange"), 0.1))
		"current":
			c.draw_rect(Rect2(Vector2.ZERO, c.size), Color(Pal.e("sky"), 0.06))
