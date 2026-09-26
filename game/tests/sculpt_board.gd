extends SceneTree
## Style board for the creatures (Puddle in Darwin style, animals in living clay): Puddle's evolution line, animals and a boss,
## each as idle + walk + bite, at 4x.   godot -s res://tests/sculpt_board.gd -- out.png [set]
func _init() -> void:
	var args := OS.get_cmdline_user_args()
	var out: String = args[0]
	var set_name: String = args[1] if args.size() > 1 else "puddle"
	var looks: Array = []
	if set_name == "puddle":
		for build in [[], ["long_legs"], ["long_legs", "sharp_teeth", "hunter_eyes", "lean_muscle"],
				["jaws", "jaws", "sharp_teeth", "sharp_teeth", "lean_muscle", "hunter_eyes", "carnivore", "bloodlust", "night_vision"],
				["skittish", "long_legs", "keen_nose", "camouflage", "herbivore", "skittish", "long_legs", "efficient_gut", "more_eyes"],
				["thick_hide", "thick_hide", "big_bones", "horns", "shell", "plating", "spines", "colossal"],
				["quick_wit", "venom_glands", "stinger", "echo", "mutant_luck", "big_brain", "quick_wit", "more_eyes", "venom_glands", "spit"],
				["pheromones", "bright_colors", "charm_song", "soothing_hum", "pheromones", "bright_colors", "charm_song", "egg_toss", "pack_call"],
				["jaws", "sharp_teeth", "lean_muscle", "hunter_eyes", "carnivore", "night_vision", "branch_wings", "branch_legs"],
				["thick_hide", "horns", "shell", "plating", "big_bones", "spines", "branch_shell", "branch_arms"],
				["skittish", "keen_nose", "camouflage", "long_legs", "herbivore", "more_eyes", "branch_tentacles", "branch_ruminant"],
				["duck_bill", "webbed_feet", "down_feathers", "duck_wings", "tail_curl", "beady_eyes", "green_crest", "convergent"]]:
			var r := Run.new("pioneer", 0, null)
			r.level = 1 + build.size()
			for e in build:
				r.take(e)
			r.recompute()
			looks.append(r.look)
	elif set_name == "bosses":
		for id in ["duckodile", "quackaconda", "mother_goose", "shelldrake", "duckaroo", "great_mallard"]:
			looks.append(Species.look_of(id))
	else:
		for id in ["frog", "fox", "beetle", "heron", "crab", "pike", "duckling", "tortoise", "scorpion", "hare"]:
			var lk := Species.look_of(id)
			lk["scale"] = 1
			looks.append(lk)
	var imgs: Array = []
	var t0 := Time.get_ticks_usec()
	for lk in looks:
		var fr := Anatomy.frames(lk)
		imgs.append([(fr["idle"][0] as Texture2D).get_image(), (fr["walk"][2] as Texture2D).get_image(), (fr["bite"][0] as Texture2D).get_image()])
	print("rendered %d genomes in %.1f ms" % [looks.size(), (Time.get_ticks_usec() - t0) / 1000.0])
	var cw := 0
	var ch := 0
	for row in imgs:
		for im in row:
			cw = maxi(cw, im.get_width())
			ch = maxi(ch, im.get_height())
	var sheet := Image.create_empty(cw * 3 + 8, ch * imgs.size(), false, Image.FORMAT_RGBA8)
	sheet.fill(Color("5dbf47"))
	for r2 in imgs.size():
		for c in 3:
			var im2: Image = imgs[r2][c]
			sheet.blend_rect(im2, Rect2i(Vector2i.ZERO, im2.get_size()), Vector2i(c * cw + (cw - im2.get_width()) / 2, r2 * ch + ch - im2.get_height()))
	sheet.resize(sheet.get_width() * 4, sheet.get_height() * 4, Image.INTERPOLATE_NEAREST)
	sheet.save_png(out)
	quit()
