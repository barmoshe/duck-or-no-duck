extends SceneTree
## Board of the hand-drawn animals and bosses: idle, walk (hop) and bite per species, at
## 6x on grass.   godot -s res://tests/animal_board.gd -- out.png [animals|bosses]
func _init() -> void:
	var args := OS.get_cmdline_user_args()
	var out: String = args[0]
	var which: String = args[1] if args.size() > 1 else "animals"
	var ids: Array = []
	for id in DarwinAnimals.ALL:
		var boss := bool(Species.get_def(id).get("boss", false))
		if boss == (which == "bosses"):
			ids.append(id)
	var cols := 4 if which == "animals" else 2
	var cells: Array = []
	var cw := 0
	var ch := 0
	for id in ids:
		var fr := Anatomy.frames(Species.look_of(id))
		var row := [(fr["idle"][0] as Texture2D).get_image(), (fr["walk"][1] as Texture2D).get_image(), (fr["bite"][0] as Texture2D).get_image()]
		cells.append(row)
		for im in row:
			cw = maxi(cw, im.get_width())
			ch = maxi(ch, im.get_height())
	var gw := cw * 3 + 6
	var rows := ceili(float(cells.size()) / cols)
	var sheet := Image.create_empty(gw * cols, (ch + 2) * rows, false, Image.FORMAT_RGBA8)
	sheet.fill(Color("5dbf47"))
	for i in cells.size():
		var ox := (i % cols) * gw
		var oy := (i / cols) * (ch + 2)
		for c in 3:
			var im: Image = cells[i][c]
			sheet.blend_rect(im, Rect2i(Vector2i.ZERO, im.get_size()), Vector2i(ox + c * cw, oy + ch - im.get_height()))
	sheet.resize(sheet.get_width() * 6, sheet.get_height() * 6, Image.INTERPOLATE_NEAREST)
	sheet.save_png(out)
	quit()
