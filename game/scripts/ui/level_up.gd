class_name LevelUpScreen
extends Screen
## Three evolution cards. Each card shows what you'll look like with it, its rarity,
## type, affinity, rank and what it replaces. Mutagen buys a reroll (1, +1 each) or a
## rarity upgrade for the whole hand (10, +10 each); both reset every level.

signal picked(id: String)
signal reroll
signal upgrade

var run: Run
var hand: Array = []
var title := "LEVEL UP!"
var sub := ""
var allow_mutagen := true


func open(r: Run, h: Array, ttl: String, subtitle: String, mutagen_ok: bool) -> void:
	run = r
	hand = h
	title = ttl
	sub = subtitle
	allow_mutagen = mutagen_ok
	show_screen()


func press(id: String) -> void:
	if id.begins_with("card:"):
		picked.emit(hand[int(id.substr(5))])
	elif id == "reroll":
		reroll.emit()
	elif id == "upgrade":
		upgrade.emit()


func _draw() -> void:
	begin()
	draw_rect(Rect2(Vector2.ZERO, size), Color(Pal.INK, 0.78))
	var s := safe()
	var y := s.position.y + 4
	var pulse := int(t * 4.0) % 2
	Ui.text(self, Vector2(s.get_center().x, y + 14), title, Pal.c("gold", 3 + pulse), Ui.bold(), 16, 1)
	y += 20
	if sub != "":
		Ui.text(self, Vector2(s.get_center().x, y + 8), sub, Ui.DIM, Ui.small(), 8, 1)
		y += 10
	var row := s.size.x >= 3 * 112 + 16
	var bottom := 34.0 if allow_mutagen else 8.0
	var area := Rect2(s.position.x, y + 4, s.size.x, s.end.y - y - 4 - bottom)
	var n := hand.size()
	for i in n:
		var r: Rect2
		if row:
			var cw := minf(140.0, (area.size.x - (n - 1) * 6) / n)
			var total := cw * n + (n - 1) * 6
			var x0 := area.position.x + (area.size.x - total) * 0.5
			r = Rect2(x0 + i * (cw + 6), area.position.y, cw, minf(area.size.y, 176.0))
		else:
			var ch := minf(78.0, (area.size.y - (n - 1) * 5) / n)
			r = Rect2(area.position.x, area.position.y + i * (ch + 5), area.size.x, ch)
		_card(r, String(hand[i]), row, is_down("card:%d" % i))
		add_button("card:%d" % i, r)
	if allow_mutagen:
		var by := s.end.y - 26
		var bw := minf(120.0, s.size.x * 0.4)
		var cx := s.get_center().x
		var free := run.free_rerolls > 0
		var rr := Rect2(cx - bw - 4, by, bw, 20)
		var can_r := free or run.mutagen >= run.reroll_cost
		Ui.button(self, rr, "REROLL (%s)" % ("FREE" if free else str(run.reroll_cost)), Pal.c("blue", 2), is_down("reroll"), can_r)
		if can_r:
			add_button("reroll", rr)
		var ur := Rect2(cx + 4, by, bw, 20)
		var can_u := run.mutagen >= run.upgrade_cost and Offers.min_rarity_of(hand) < 3
		Ui.button(self, ur, "UPGRADE (%d)" % run.upgrade_cost, Pal.c("purple", 3), is_down("upgrade"), can_u)
		if can_u:
			add_button("upgrade", ur)
		_dna(Vector2(s.end.x - 30, by + 6))


func _dna(p: Vector2) -> void:
	draw_texture(Props.tex("mutagen"), p.floor())
	Ui.text(self, p + Vector2(11, 9), str(run.mutagen), Pal.c("green", 4))


func _card(r: Rect2, id: String, tall: bool, down: bool) -> void:
	var d := Evolutions.get_def(id)
	var rar := int(d["rarity"])
	var rcol := Pal.c(String(Evolutions.RARITY_RAMP[rar]), 3 if rar > 0 else 3)
	var rr := Rect2(r.position + (Vector2(0, 1) if down else Vector2.ZERO), r.size)
	Ui.panel(self, rr, Color("262b44") if not d.get("duck_part", false) else Color("3e2731"), rcol, rcol.darkened(0.3))
	draw_rect(Rect2(rr.position + Vector2(1, 1), Vector2(rr.size.x - 2, 2)), rcol)
	# what you'd look like
	var look := run.look.duplicate()
	for k in d.get("look", {}):
		look[k] = d["look"][k]
	var owned := run.rank(id)
	var rank_s := "NEW" if owned == 0 else "RANK %d/%d" % [owned + 1, int(d["max"])]
	var repl := run.would_replace(id)
	var name_s := String(d["name"]).to_upper()
	if tall:
		var pc := Vector2(rr.get_center().x, rr.position.y + 34)
		draw_rect(Rect2(rr.position.x + 4, rr.position.y + 6, rr.size.x - 8, 50), Color("181425"))
		Ui.creature(self, look, pc + Vector2(0, 2), 2, int(t * 2.0))
		var y := rr.position.y + 66
		Ui.text(self, Vector2(rr.get_center().x, y), name_s, Color.WHITE, Ui.small(), 8, 1)
		y += 10
		Ui.text(self, Vector2(rr.get_center().x, y), "%s  %s" % [Evolutions.RARITY_NAMES[rar].to_upper(), String(Evolutions.TYPE_NAMES[d["type"]]).to_upper()], rcol, Ui.small(), 8, 1)
		y += 10
		Ui.gem(self, Vector2(rr.position.x + 8, y - 3), String(d["aff"]))
		Ui.text(self, Vector2(rr.position.x + 14, y), String(Evolutions.AFF_NAMES[d["aff"]]).to_upper(), Pal.c(String(Evolutions.AFF_RAMP[d["aff"]]), 3))
		Ui.text(self, Vector2(rr.end.x - 5, y), rank_s, Pal.c("gold", 4) if owned == 0 else Pal.c("green", 4), Ui.small(), 8, 2)
		y += 6
		var h := Ui.para(self, Vector2(rr.position.x + 5, y + 6), String(d["desc"]), rr.size.x - 10, Color("c0cbdc"), Ui.small(), 8, 9)
		if repl != "":
			Ui.para(self, Vector2(rr.position.x + 5, y + 10 + h), "REPLACES " + String(Evolutions.get_def(repl)["name"]).to_upper(), rr.size.x - 10, Pal.c("red", 3), Ui.small(), 8, 9)
	else:
		var box := Rect2(rr.position.x + 4, rr.position.y + 4, 56, rr.size.y - 8)
		draw_rect(box, Color("181425"))
		Ui.creature(self, look, box.get_center() + Vector2(0, 2), 2 if rr.size.y > 60 else 1, int(t * 2.0))
		var x := box.end.x + 6
		var y2 := rr.position.y + 11
		Ui.text(self, Vector2(x, y2), name_s, Color.WHITE)
		Ui.text(self, Vector2(rr.end.x - 5, y2), rank_s, Pal.c("gold", 4) if owned == 0 else Pal.c("green", 4), Ui.small(), 8, 2)
		y2 += 10
		Ui.gem(self, Vector2(x + 3, y2 - 3), String(d["aff"]))
		Ui.text(self, Vector2(x + 9, y2), "%s %s" % [Evolutions.RARITY_NAMES[rar].to_upper(), String(Evolutions.TYPE_NAMES[d["type"]]).to_upper()], rcol)
		y2 += 4
		var h2 := Ui.para(self, Vector2(x, y2 + 6), String(d["desc"]), rr.end.x - x - 5, Color("c0cbdc"), Ui.small(), 8, 9)
		if repl != "":
			Ui.text(self, Vector2(x, y2 + 13 + h2 - 3), "REPLACES " + String(Evolutions.get_def(repl)["name"]).to_upper(), Pal.c("red", 3))
