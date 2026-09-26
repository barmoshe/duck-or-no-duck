extends SceneTree
## Puddle (Darwin style) review sheet: builds from the composer, at 8x on parchment.
##   godot -s res://tests/darwin_board.gd -- out.png "part+part,part,..."
func _init() -> void:
	var args := OS.get_cmdline_user_args()
	var out: String = args[0]
	var sets: Array = String(args[1]).split(",") if args.size() > 1 else [""]
	var imgs: Array = []
	for st in sets:
		var parts: Array = []
		for p in String(st).split("+"):
			if p != "":
				parts.append(p)
		imgs.append(DarwinArt.compose(parts, {}))
	var cw := 0
	var ch := 0
	for im in imgs:
		cw = maxi(cw, im.get_width() + 4)
		ch = maxi(ch, im.get_height() + 4)
	var cols := mini(imgs.size(), 5)
	var rows := int(ceil(imgs.size() / float(cols)))
	var sheet := Image.create_empty(cw * cols, ch * rows, false, Image.FORMAT_RGBA8)
	sheet.fill(Color("d8c9a0"))
	for i in imgs.size():
		var im2: Image = imgs[i]
		sheet.blend_rect(im2, Rect2i(Vector2i.ZERO, im2.get_size()), Vector2i((i % cols) * cw + (cw - im2.get_width()) / 2, (i / cols) * ch + ch - im2.get_height() - 2))
	sheet.resize(sheet.get_width() * 8, sheet.get_height() * 8, Image.INTERPOLATE_NEAREST)
	sheet.save_png(out)
	quit()
