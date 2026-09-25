extends SceneTree
## Close-up review: a few looks at 8x.  godot -s res://tests/zoom_sheet.gd -- out.png id,id,...
func _init() -> void:
	var args := OS.get_cmdline_user_args()
	var out: String = args[0]
	var imgs: Array = []
	for id in String(args[1]).split(","):
		var look: Dictionary
		if id.begins_with("run:"):
			var r := Run.new("pioneer", 0, null)
			for e in id.substr(4).split("+"):
				if e != "":
					r.take(e)
			look = r.look
		else:
			look = Species.look_of(id)
			look["scale"] = 1
		for anim in [["idle", 0], ["idle", 1], ["move", 1], ["move", 3], ["attack", 0]]:
			var fr := Anatomy.frames(look)
			var tex: ImageTexture = (fr["walk"] if anim[0] == "move" else fr[anim[0]])[anim[1]] if anim[0] != "attack" else fr["bite"][0]
			imgs.append(tex.get_image())
	var cw := 0
	var ch := 0
	for i in imgs:
		cw = maxi(cw, i.get_width())
		ch = maxi(ch, i.get_height())
	var sheet := Image.create_empty(cw * 5, ch * (imgs.size() / 5), false, Image.FORMAT_RGBA8)
	sheet.fill(Color("4f9d4b"))
	for k in imgs.size():
		sheet.blend_rect(imgs[k], Rect2i(Vector2i.ZERO, imgs[k].get_size()), Vector2i((k % 5) * cw, (k / 5) * ch))
	sheet.resize(sheet.get_width() * 6, sheet.get_height() * 6, Image.INTERPOLATE_NEAREST)
	sheet.save_png(out)
	quit()
