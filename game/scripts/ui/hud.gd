class_name Hud
extends Control
## In-run HUD at pixel resolution: Duck Meter (with the boss marks), HP, XP and level,
## Mutagen, equipped attacks with cooldowns, minimap, boss bar + timer, Breadfall
## countdown, challenge counter, edge arrows to the boss and the nearest "?", banners.

signal pause_pressed

var world: World
var banner_title := ""
var banner_sub := ""
var banner_t := 99.0
var toast_s := ""
var toast_t := 99.0
var t := 0.0
var boss_icons := {}
var map_tex: ImageTexture
var pause_rect := Rect2()


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	set_anchors_preset(Control.PRESET_FULL_RECT)
	process_mode = Node.PROCESS_MODE_ALWAYS


func build_minimap() -> void:
	var m := world.map
	var n := 64
	var img := Image.create_empty(n, n, false, Image.FORMAT_RGBA8)
	var cols := [Pal.e("grass"), Pal.e("pine"), Pal.e("tan"), Pal.e("mist"), Pal.e("ink")]
	for y in n:
		for x in n:
			var cx := int((x + 0.5) * MapGen.N / n)
			var cy := int((y + 0.5) * MapGen.N / n)
			var i := cy * MapGen.N + cx
			var c: Color = cols[m.biome[i]]
			if m.water[i] != 0 and m.biome[i] != 4:
				c = Pal.e("sky") if m.biome[i] != 3 else Pal.e("white")
			img.set_pixel(x, y, c)
	map_tex = ImageTexture.create_from_image(img)


func show_banner(title: String, sub: String) -> void:
	banner_title = title
	banner_sub = sub
	banner_t = 0.0


func show_toast(s: String) -> void:
	toast_s = s
	toast_t = 0.0


func _process(dt: float) -> void:
	position = Vector2.ZERO
	size = get_viewport_rect().size
	t += dt
	banner_t += dt
	toast_t += dt
	queue_redraw()


func _input(event: InputEvent) -> void:
	if not visible or not world or not world.running:
		return
	if event is InputEventMouse and event.device == InputEvent.DEVICE_ID_EMULATION:
		return
	var e := make_input_local(event)
	var pos := Vector2(-99, -99)
	if e is InputEventScreenTouch and e.pressed:
		pos = e.position
	elif e is InputEventMouseButton and e.pressed and e.button_index == MOUSE_BUTTON_LEFT:
		pos = e.position
	if pause_rect.grow(4.0).has_point(pos):
		get_viewport().set_input_as_handled()
		pause_pressed.emit()


func _draw() -> void:
	if world == null or world.run == null or world.player == null:
		return
	var run := world.run
	var p := world.player
	var s := Game.safe_rect(size).grow(-3.0)
	var L := s.position.x
	var R := s.end.x
	var T := s.position.y

	# --- the timer bar (Crab): a clock and the run's clock with the bosses hanging under
	# it in the order they come, between the HP block (left) and pause + minimap (right)
	var dm_l := L + 112.0
	var dm_r := R - 46.0 - 26.0
	var dm_w := maxf(80.0, dm_r - dm_l)
	var dm := Rect2(floorf(dm_l), T, floorf(dm_w), 9)
	draw_texture(Icons.tex("hud_clock"), Vector2(dm.position.x - 12, T - 1))
	var night := run.is_night()
	Ui.wood_bar(self, dm, run.time / Run.FINAL_TIME, Color("a22633") if not night else Color("3a4466"))
	var inner_w := dm.size.x - 4.0
	var marks: Array = Run.BOSS_TIMES.duplicate()
	marks.append(Run.FINAL_TIME)
	for i in marks.size():
		var x := dm.position.x + 2.0 + floorf((inner_w - 1.0) * float(marks[i]) / Run.FINAL_TIME)
		var id := String(run.boss_order[i])
		var done := run.time >= float(marks[i])
		var ic := _boss_icon(id)
		var isz := ic.get_size()
		var ip := Vector2(x - isz.x * 0.5, dm.end.y + 1).floor()
		if i == marks.size() - 1:
			ip.x = minf(ip.x, dm.end.x - isz.x + 4)
		draw_rect(Rect2(x, dm.position.y + 2, 1, dm.size.y - 4), Ui.WOOD_HI)
		draw_texture(ic, ip, Color(1, 1, 1, 0.4) if done else Color.WHITE)
	# the day/night marker riding the bar: a sun or a moon
	var sx := dm.position.x + 2.0 + floorf((inner_w - 1.0) * run.time / Run.FINAL_TIME)
	draw_circle(Vector2(sx, dm.position.y + 4.5), 3.5, Ui.WOOD_OUT)
	draw_circle(Vector2(sx, dm.position.y + 4.5), 2.5, Pal.c("gold", 3) if not night else Pal.c("snow", 4))

	# --- HP: a heart and a framed red bar, top left
	var y0 := T
	draw_texture(Icons.tex("hud_heart"), Vector2(L, y0))
	Ui.wood_bar(self, Rect2(L + 13, y0, 84, 11), p.hp / maxf(1.0, p.max_hp), Color("e43b44"), "%d/%d" % [ceili(maxf(0.0, p.hp)), ceili(p.max_hp)])
	var info_y := y0 + 14.0
	if run.duck_parts() > 0:
		info_y += 9
		Ui.text(self, Vector2(L + 1, y0 + 22), "DUCK %d/8" % run.duck_parts(), Pal.c("gold", 3))
	if world.ally_count() > 0:
		info_y += 9
		Ui.text(self, Vector2(L, info_y), "ALLIES %d/%d" % [world.ally_count(), int(run.stats["ally_max"])], Pal.c("pink", 3))
	if world.hidden():
		Ui.text(self, Vector2(s.get_center().x, s.end.y - 30), "HIDING IN A BURROW", Pal.c("brown", 4), Ui.small(), 8, 1)
	if world.dizzy > 0.0:
		Ui.text(self, Vector2(s.get_center().x, s.end.y - 38), "DIZZY!", Pal.c("purple", 4), Ui.small(), 8, 1)

	# --- attacks: framed icon slots, bottom left, dark while cooling down
	var ss := 20.0
	var ax := L
	for id in run.attacks:
		var cd := float(world.combat.cds.get(id, 0.0))
		var mx := float(Attacks.ATTACK[id]["cd"]) * Attacks.rank_cd(run.rank(id)) * float(run.stats["cd_mult"])
		Ui.slot(self, Rect2(ax, s.end.y - ss, ss, ss), Icons.tex(id), cd / maxf(0.01, mx))
		ax += ss + 3.0

	# --- XP: the fruit with the level on it and a framed bar, bottom center
	var xl := maxf(ax + 16.0, s.position.x + s.size.x * 0.22)
	var xr_end := minf(R - 80.0, s.position.x + s.size.x * 0.78)
	var xr := Rect2(floorf(xl), s.end.y - 11, floorf(maxf(60.0, xr_end - xl)), 11)
	Ui.wood_bar(self, xr, run.xp / run.xp_need(), Color("63c74d"), "%d/%d" % [int(run.xp), int(run.xp_need())])
	draw_texture(Icons.tex("hud_fruit"), Vector2(xr.position.x - 13, xr.position.y - 2))
	Ui.text(self, Vector2(xr.position.x - 6, xr.end.y + 1), str(run.level), Color.WHITE, Ui.small(), 8, 1)

	# --- minimap in a wooden frame, top right
	var ms := 46.0
	var mr := Rect2(R - ms, T + 1, ms, ms)
	if map_tex:
		Ui.wood(self, mr.grow(2))
		draw_texture_rect(map_tex, mr, false)
		var k := ms / MapGen.SIZE
		for poi in world.pois:
			if not poi["used"]:
				draw_rect(Rect2(mr.position + (poi["p"] as Vector2) * k - Vector2(1, 1), Vector2(2, 2)), Pal.c("gold", 4))
		for a in world.actors:
			if a.is_boss and not a.dead:
				draw_rect(Rect2(mr.position + a.position * k - Vector2(1, 1), Vector2(3, 3)), Pal.c("red", 3 + int(t * 6) % 2))
			elif a.alpha and not a.dead:
				draw_rect(Rect2(mr.position + a.position * k, Vector2(1, 1)), Pal.c("gold", 3))
		var pp := mr.position + p.position * k
		draw_rect(Rect2(pp - Vector2(1, 1), Vector2(3, 3)), Color.WHITE)
		draw_rect(Rect2(pp, Vector2(1, 1)), Pal.c("blue", 2))
	# Mutagen, top right under the map (as in Crab)
	var mt := Vector2(R - 2, T + ms + 13)
	Ui.text(self, mt, str(run.mutagen), Color.WHITE, Ui.bold(), 16, 2)
	draw_texture(Props.tex("mutagen"), Vector2(mt.x - Ui.text_w(Ui.bold(), str(run.mutagen), 16) - 12, mt.y - 11))
	# pause button left of the map
	pause_rect = Rect2(R - ms - 20, T, 15, 14)
	Ui.wood(self, pause_rect)
	draw_rect(Rect2(pause_rect.position + Vector2(5, 4), Vector2(2, 6)), Ui.PARCHMENT)
	draw_rect(Rect2(pause_rect.position + Vector2(9, 4), Vector2(2, 6)), Ui.PARCHMENT)

	# --- boss bar
	var bosses := world.bosses
	if World.valid(bosses.boss):
		var b := bosses.boss
		var bb := Rect2(floorf(s.get_center().x - dm_w * 0.5), T + 30, dm_w, 9)
		Ui.wood_bar(self, bb, b.hp / b.max_hp, Pal.c("red", 3))
		var label := String(Species.get_def(b.species)["name"]).to_upper()
		if bosses.bread_on:
			label += "  BREADFALL %d" % ceili(bosses.bread_left)
		elif not bosses.final_active:
			label += "  GIVES UP IN %d" % ceili(bosses.timer)
		Ui.text(self, Vector2(bb.get_center().x, bb.end.y + 9), label, Pal.c("red", 4), Ui.small(), 8, 1)
		_edge_arrow(b.position, Pal.c("red", 3))
	var np := world.nearest_poi()
	if not np.is_empty() and (np["p"] as Vector2).distance_to(p.position) < 700.0:
		_edge_arrow(np["p"], Pal.c("gold", 4), "?")
	# --- banner + toast
	if banner_t < 3.0:
		var a := clampf(minf(banner_t * 6.0, (3.0 - banner_t) * 3.0), 0.0, 1.0)
		var by := floorf(size.y * 0.4)
		draw_rect(Rect2(0, by - 16, size.x, 30), Color(Pal.INK, 0.55 * a))
		Ui.text(self, Vector2(size.x * 0.5, by), banner_title, Color(Pal.c("gold", 3), a), Ui.bold(), 16, 1)
		Ui.text(self, Vector2(size.x * 0.5, by + 10), banner_sub, Color(Color.WHITE, a), Ui.small(), 8, 1)
	if toast_t < 2.0:
		var a2 := clampf(minf(toast_t * 6.0, (2.0 - toast_t) * 3.0), 0.0, 1.0)
		Ui.text(self, Vector2(size.x * 0.5, floorf(size.y * 0.4) + 30), toast_s, Color(Color.WHITE, a2), Ui.small(), 8, 1)


func _boss_icon(id: String) -> Texture2D:
	if not boss_icons.has(id):
		var lk := Species.look_of(id)
		lk["scale"] = 1
		var img := Anatomy.render(lk, "idle", 0)
		img = img.get_region(img.get_used_rect())
		while img.get_width() > 16 or img.get_height() > 14:
			img.resize(maxi(1, img.get_width() / 2), maxi(1, img.get_height() / 2), Image.INTERPOLATE_NEAREST)
		boss_icons[id] = ImageTexture.create_from_image(img)
	return boss_icons[id]


func _edge_arrow(world_p: Vector2, col: Color, label: String = "") -> void:
	if size.x < 60.0 or size.y < 60.0:
		return
	var sp := get_viewport().canvas_transform * world_p
	var vr := Rect2(Vector2.ZERO, size).grow(-14.0)
	if vr.has_point(sp):
		return
	var c := size * 0.5
	var dir := (sp - c).normalized()
	# clamp to the rect edge
	var tx := (vr.size.x * 0.5) / maxf(0.001, absf(dir.x))
	var ty := (vr.size.y * 0.5) / maxf(0.001, absf(dir.y))
	var e := (c + dir * minf(tx, ty)).floor()
	var perp := dir.orthogonal()
	draw_colored_polygon(PackedVector2Array([e + dir * 5.0, e - dir * 3.0 + perp * 4.0, e - dir * 3.0 - perp * 4.0]), col)
	if label != "":
		Ui.text(self, e - dir * 10.0 + Vector2(-2, 3), label, col)
