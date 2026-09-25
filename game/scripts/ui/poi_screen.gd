class_name PoiScreen
extends Screen
## A point of interest's choice: its picture and three options; pick one, lose the rest.

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
	draw_rect(Rect2(Vector2.ZERO, size), Color(Pal.INK, 0.72))
	var s := safe()
	var d := Pois.get_def(kind)
	if d.is_empty():
		return
	var cx := s.get_center().x
	var tex := Props.tex("poi_" + kind)
	var tsz := tex.get_size() * 2
	var top := s.position.y + 10
	draw_texture_rect(tex, Rect2(Vector2(cx - tsz.x * 0.5, top), tsz).abs(), false)
	Ui.text(self, Vector2(cx, top + tsz.y + 14), String(d["name"]).to_upper(), Pal.c("gold", 4), Ui.bold(), 16, 1)
	Ui.text(self, Vector2(cx, top + tsz.y + 24), "Choose one. The others are gone.", Ui.DIM, Ui.small(), 8, 1)
	var opts: Array = d["options"]
	var n := opts.size()
	var cw := minf(140.0, (s.size.x - 20.0 - (n - 1) * 6) / n)
	var ch := 62.0
	var y := top + tsz.y + 32
	var x0 := cx - (cw * n + (n - 1) * 6) * 0.5
	for i in n:
		var r := Rect2(x0 + i * (cw + 6), y, cw, ch)
		var down := is_down("opt:%d" % i)
		var rr := Rect2(r.position + (Vector2(0, 1) if down else Vector2.ZERO), r.size)
		Ui.panel(self, rr, Color("262b44"), Pal.c("gold", 3), Color("3a4466"))
		Ui.text(self, Vector2(rr.get_center().x, rr.position.y + 12), String(opts[i]["name"]).to_upper(), Color.WHITE, Ui.small(), 8, 1)
		Ui.para(self, Vector2(rr.position.x + 5, rr.position.y + 24), String(opts[i]["desc"]), rr.size.x - 10, Color("c0cbdc"))
		add_button("opt:%d" % i, r)
