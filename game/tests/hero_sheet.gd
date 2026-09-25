extends SceneTree
## Review sheet for the Evolution Graphics System: row 1 = Puddle's frames (idle x4,
## move x4, attack); then Puddle along three evolution paths; then every animal rig.
##   godot --headless --path game -s res://tests/hero_sheet.gd -- out.png

func _frames_row(look: Dictionary) -> Array:
	var row: Array = []
	var fr := Anatomy.frames(look)
	for k in ["idle", "walk", "bite"]:
		for t in fr[k]:
			row.append((t as ImageTexture).get_image())
	return row


func _init() -> void:
	var out: String = OS.get_cmdline_user_args()[0] if OS.get_cmdline_user_args().size() > 0 else "user://hero.png"
	var rows: Array = []
	var r := Run.new("pioneer", 0, null)
	rows.append(_frames_row(r.look))
	for path in [["jaws", "more_eyes", "long_legs", "horns", "spines", "stinger", "night_vision", "hunter_eyes", "tail_whip"],
			["duck_bill", "webbed_feet", "down_feathers", "tail_curl", "beady_eyes", "duck_wings", "green_crest", "shell", "convergent"],
			["shell", "plating", "horns", "big_bones", "thick_hide", "tail_whip", "charge", "pincer_snap", "colossal"],
			["pheromones", "bright_colors", "charm_song", "skittish", "keen_nose", "camouflage", "long_legs", "egg_toss", "pack_call"]]:
		var rr := Run.new("pioneer", 0, null)
		var row: Array = [Anatomy.render(rr.look, "idle", 0)]
		for id in path:
			rr.take(id)
			row.append(Anatomy.render(rr.look, "idle", 0))
		rows.append(row)
	var an: Array = []
	for id in Species.ALL:
		if Species.get_def(id).get("boss", false):
			continue
		an.append(Anatomy.render(Species.look_of(id), "idle", 0))
		if an.size() == 10:
			rows.append(an)
			an = []
	if not an.is_empty():
		rows.append(an)
	var cw := 0
	var ch := 0
	for row in rows:
		for img in row:
			cw = maxi(cw, img.get_width())
			ch = maxi(ch, img.get_height())
	var cols := 10
	var sheet := Image.create_empty(cw * cols, ch * rows.size(), false, Image.FORMAT_RGBA8)
	sheet.fill(Color("4f9d4b"))
	for y in rows.size():
		for x in mini(cols, rows[y].size()):
			var img: Image = rows[y][x]
			sheet.blend_rect(img, Rect2i(Vector2i.ZERO, img.get_size()), Vector2i(x * cw + (cw - img.get_width()) / 2, y * ch + (ch - img.get_height()) / 2))
	sheet.resize(sheet.get_width() * 3, sheet.get_height() * 3, Image.INTERPOLATE_NEAREST)
	sheet.save_png(out)
	print("hero sheet -> ", out)
	quit()
