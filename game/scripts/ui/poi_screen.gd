class_name PoiScreen
extends Screen
## A point of interest's choice, in the Evolution screen's style: a ribbon with its name,
## its picture on a parchment board, and three option cards. Pick one, lose the rest.

signal chosen(fx: Dictionary)

var kind := ""


func open(k: String) -> void:
	kind = k
	show_screen()


func press(id: String) -> void:
	if id.begins_with("opt:"):
		var opts: Array = Pois.get_def(kind)["options"]
		chosen.emit(opts[int(id.substr(4))]["fx"])


func _draw() -> void:
	begin()
	draw_rect(Rect2(Vector2.ZERO, size), Color(Pal.INK, 0.62))
	var s := safe()
	var d := Pois.get_def(kind)
	if d.is_empty():
		return
	var cx := s.get_center().x
	Ui.ribbon(self, Vector2(cx, s.position.y + 2), String(d["name"]).to_upper())
	var b := Rect2(s.position.x + 4, s.position.y + 24, s.size.x - 8, s.size.y - 24)
	Ui.board(self, b)
	# the place itself, on the left of the board
	var tex := Props.tex("poi_" + kind)
	var tsz := tex.get_size() * 2
	var pic := Rect2(b.position.x + 8, b.position.y + 8, maxf(76.0, tsz.x + 12), b.size.y - 16)
	draw_rect(pic, Color("c28569"))
	draw_rect(pic.grow(-1), Color("ead4aa").darkened(0.06))
	draw_texture_rect(tex, Rect2((pic.get_center() - tsz * 0.5).floor(), tsz), false)
	Ui.para(self, Vector2(pic.position.x + 4, pic.end.y - 20), "CHOOSE ONE. THE OTHERS ARE GONE.", pic.size.x - 8, Color("5a3a35"), Ui.small(), 8, 8, false)
	var opts: Array = d["options"]
	var n := opts.size()
	var area := Rect2(pic.end.x + 6, b.position.y + 8, b.end.x - pic.end.x - 14, b.size.y - 16)
	var cw := floorf((area.size.x - (n - 1) * 5.0) / maxf(1, n))
	for i in n:
		var down := is_down("opt:%d" % i)
		var r := Rect2(area.position.x + i * (cw + 5.0), area.position.y + (1 if down else 0), cw, area.size.y)
		draw_rect(r, Pal.INK)
		draw_rect(r.grow(-1), Pal.e("amber"))
		var body := r.grow(-3)
		draw_rect(body, Color("733e39"))
		Ui.para(self, Vector2(body.position.x + 4, body.position.y + 11), String(opts[i]["name"]).to_upper(), body.size.x - 8, Color.WHITE, Ui.small(), 8, 9)
		var box := Rect2(body.position.x + 2, body.position.y + 26, body.size.x - 4, body.size.y - 28)
		draw_rect(box, Color("e4a672").darkened(0.25))
		draw_rect(box.grow(-1), Color("e4a672"))
		Ui.para(self, Vector2(box.position.x + 3, box.position.y + 10), String(opts[i]["desc"]), box.size.x - 6, Ui.INK_TEXT, Ui.small(), 8, 8, false)
		add_button("opt:%d" % i, r)
