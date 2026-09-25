extends SceneTree
## Renders every species (duck stage 0, 4 and 8) and sample player builds to one PNG sheet,
## scaled x4, for reviewing the generated pixel art.
##   godot --headless --path game -s res://tests/artsheet.gd -- out.png

func _init() -> void:
	var out := "user://artsheet.png"
	var args := OS.get_cmdline_user_args()
	if args.size() > 0:
		out = args[0]
	var cells: Array = []
	var only: Array = []
	var scale := 3
	if args.size() > 1:
		only = args[1].split(",")
		scale = 6
	for id in Species.ALL:
		if not only.is_empty() and not id in only:
			continue
		for st in [0]:
			cells.append([id + ":" + str(st), Anatomy.render(Species.look_of(id), "idle", 0)])
	var cw := 0
	var ch := 0
	for c in cells:
		cw = maxi(cw, (c[1] as Image).get_width())
		ch = maxi(ch, (c[1] as Image).get_height())
	cw += 4
	ch += 4
	var cols := 9
	var rows := ceili(cells.size() / float(cols))
	var sheet := Image.create_empty(cols * cw, rows * ch, false, Image.FORMAT_RGBA8)
	sheet.fill(Color("3e8948"))
	for i in cells.size():
		var img: Image = cells[i][1]
		var x := (i % cols) * cw + (cw - img.get_width()) / 2
		var y := (i / cols) * ch + (ch - img.get_height()) / 2
		sheet.blend_rect(img, Rect2i(Vector2i.ZERO, img.get_size()), Vector2i(x, y))
	sheet.resize(sheet.get_width() * scale, sheet.get_height() * scale, Image.INTERPOLATE_NEAREST)
	sheet.save_png(out)
	print("artsheet: %d cells -> %s" % [cells.size(), out])
	quit()
