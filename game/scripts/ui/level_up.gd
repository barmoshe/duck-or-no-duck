class_name LevelUpScreen
extends Screen
## The Evolution screen, after Everything is Crab's, laid out for a phone in landscape:
## a red ribbon title, the affinity panel on the left (emblem, points, +% chance) with a
## live preview of your creature, three cards on a parchment board in the middle, and
## Mutagen buttons on the right. Each card: rarity frame, type badge, a portrait of the
## evolution on YOUR creature, level pips, name + level, what it does with the numbers
## going from now to next, its affinity, and what it unlocks or bans.
## Tap a card to select it (it lifts and the preview shows it), tap again or EVOLVE.

signal picked(id: String)
signal reroll
signal upgrade

const RAR_COL := [Color("63c74d"), Color("0099db"), Color("b55088"), Color("feae34"), Color("e43b44")]
const CARD_BG := Color("733e39")
const BOX := Color("e4a672")
const BOX_TEXT := Color("3e2731")
const AFF_ORDER := ["predator", "prey", "gregarious", "imposing", "trickster", "duck"]

var run: Run
var hand: Array = []
var title := "EVOLUTION"
var sub := ""
var allow_mutagen := true
var sel := -1


func open(r: Run, h: Array, ttl: String, subtitle: String, mutagen_ok: bool) -> void:
	run = r
	hand = h
	title = ttl
	sub = subtitle
	allow_mutagen = mutagen_ok
	sel = -1
	show_screen()


func show_screen() -> void:
	sel = -1
	super.show_screen()


func press(id: String) -> void:
	if id.begins_with("card:"):
		var i := int(id.substr(5))
		if sel == i:
			picked.emit(hand[i])
		else:
			sel = i
	elif id.begins_with("pick:"):
		picked.emit(hand[int(id.substr(5))])
	elif id == "evolve" and sel >= 0:
		picked.emit(hand[sel])
	elif id == "reroll":
		reroll.emit()
	elif id == "upgrade":
		upgrade.emit()


# ------------------------------------------------------------------ layout
func _draw() -> void:
	begin()
	draw_rect(Rect2(Vector2.ZERO, size), Color(Pal.INK, 0.62))
	var s := safe()
	var branch := hand.size() > 0 and String(Evolutions.get_def(String(hand[0])).get("type", "")) == "branch"
	var y0 := s.position.y + 22.0
	var lw := 86.0 if s.size.x >= 430.0 else 0.0
	var rw := 58.0
	var board := Rect2(s.position.x + lw + (5.0 if lw > 0.0 else 0.0), y0, s.size.x - lw - rw - (10.0 if lw > 0.0 else 5.0), s.end.y - y0)
	# the parchment board with the cards
	Ui.wood(self, board)
	draw_rect(board.grow(-3), Ui.PARCHMENT)
	draw_rect(Rect2(board.position + Vector2(3, 3), Vector2(board.size.x - 6, 1)), Color(1, 1, 1, 0.4))
	var n := hand.size()
	var inner := board.grow(-6)
	var cw := floorf(minf(124.0, (inner.size.x - (n - 1) * 5.0) / maxf(1, n)))
	var total := cw * n + (n - 1) * 5.0
	var x0 := floorf(inner.position.x + (inner.size.x - total) * 0.5)
	for i in n:
		var r := Rect2(x0 + i * (cw + 5.0), inner.position.y + 3.0, cw, inner.size.y - 3.0)
		_card(r, String(hand[i]), i == sel, is_down("card:%d" % i), branch)
		add_button("card:%d" % i, r)
	_ribbon(Vector2(board.get_center().x, s.position.y + 1), title, branch)
	if lw > 0.0:
		_affinities(Rect2(s.position.x, y0, lw, s.end.y - y0))
	_side(Rect2(s.end.x - rw, y0, rw, s.end.y - y0))


func _ribbon(c: Vector2, text: String, branch: bool) -> void:
	Ui.ribbon(self, c, text, branch)


# ------------------------------------------------------------------ a card
func _card(r0: Rect2, id: String, selected: bool, down: bool, branch: bool) -> void:
	var d := Evolutions.get_def(id)
	var cur := run.rank(id)
	var rar := Evolutions.offered_rarity(id, cur + 1)
	var col: Color = RAR_COL[rar]
	var r := Rect2(r0.position + Vector2(0, (-4.0 if selected else 0.0) + (1.0 if down else 0.0)), r0.size).abs()
	r = Rect2(r.position.floor(), r.size.floor())
	# frame: shadow, ink, rarity color, maroon body
	draw_rect(Rect2(r.position + Vector2(1, 3), r.size), Color(0, 0, 0, 0.3))
	if selected:
		var glow := 0.5 + 0.5 * sin(t * 6.0)
		draw_rect(r.grow(2), Color(Pal.e("lemon"), 0.5 + 0.4 * glow))
	draw_rect(r, Pal.INK)
	draw_rect(r.grow(-1), col)
	draw_rect(Rect2(r.position + Vector2(1, 1), Vector2(r.size.x - 2, 1)), col.lightened(0.35))
	var body := r.grow(-3)
	draw_rect(body, CARD_BG if not d.get("duck_part", false) or run.duck_parts() == 0 else Color("7a4a2a"))
	if branch or rar == 4:
		# ornate corners on branching cards
		for q in [r.position, Vector2(r.end.x - 5, r.position.y), Vector2(r.position.x, r.end.y - 5), r.end - Vector2(5, 5)]:
			draw_rect(Rect2(q, Vector2(5, 5)), Pal.e("amber"))
			draw_rect(Rect2(q + Vector2(1, 1), Vector2(3, 3)), Pal.e("orange"))
	# level pips + NEW star
	var mx := int(d.get("max", 1))
	var px0 := body.position.x + 3
	if mx > 1:
		for i in mx:
			var pr := Rect2(px0 + i * 6, body.position.y + 3, 4, 4)
			draw_rect(pr.grow(1), Pal.INK)
			var filled := i < cur
			var nxt := i == cur
			draw_rect(pr, Pal.e("amber") if filled else (Pal.e("lemon") if nxt and int(t * 3.0) % 2 == 0 else Color("5a3a35")))
	if cur == 0:
		_star(Vector2(px0 + (mx * 6 if mx > 1 else 0) + 4, body.position.y + 5))
	# the type badge
	var bt := String(d.get("type", "passive"))
	if bt != "passive":
		var br := Rect2(body.end.x - 16, body.position.y + 1, 16, 14)
		draw_rect(br, Pal.INK)
		draw_rect(br.grow(-1), col.lerp(Ui.PARCHMENT, 0.4))
		draw_texture(Icons.tex("badge_" + bt), br.position + Vector2(2, 1))
	# portrait
	var pt := Portrait.tex(run, id)
	var pp := Vector2(floorf(body.get_center().x - Portrait.W * 0.5), body.position.y + 10)
	draw_rect(Rect2(pp - Vector2(1, 1), Vector2(Portrait.W + 2, Portrait.H + 2)), col.darkened(0.2))
	draw_texture(pt, pp)
	# name + level
	var y := pp.y + Portrait.H + 10
	var nm := String(d["name"]).to_upper()
	if mx > 1:
		nm += " (LVL %d)" % (cur + 1)
	var nh := Ui.para(self, Vector2(body.position.x + 3, y), nm, body.size.x - 6, Color.WHITE, Ui.small(), 8, 9)
	y += nh - 3
	# the text box: what it does, then the numbers now -> next
	var foot := 16.0
	var box := Rect2(body.position.x + 2, y, body.size.x - 4, body.end.y - y - foot)
	draw_rect(box, BOX.darkened(0.25))
	draw_rect(box.grow(-1), BOX)
	var ty := box.position.y + 9
	var used := Ui.para(self, Vector2(box.position.x + 3, ty), _short_desc(d), box.size.x - 6, BOX_TEXT, Ui.small(), 8, 8, false)
	ty += used + 1
	for ln in Evolutions.lines(id, cur):
		if ty > box.end.y - 3:
			break
		_stat_line(Vector2(box.position.x + 3, ty), box.size.x - 6, ln)
		ty += 8
	var repl := run.would_replace(id)
	if repl != "" and ty <= box.end.y - 3:
		Ui.para(self, Vector2(box.position.x + 3, ty), "REPLACES " + String(Evolutions.get_def(repl)["name"]).to_upper(), box.size.x - 6, Pal.e("wine"), Ui.small(), 8, 8, false)
	# footer: affinity emblem, unlocks, bans
	var fy := body.end.y - foot + 2
	var aff := String(d.get("aff", "prey"))
	var em := "aff_" + aff
	if aff == "duck" and run.duck_parts() == 0:
		em = "aff_egg"  # the hidden affinity stays a mystery until you own a duck part
	draw_texture(Icons.tex(em), Vector2(body.position.x + 2, fy))
	var fx := body.position.x + 18
	var ul := Evolutions.unlocks_of(id)
	if not ul.is_empty():
		draw_texture(Icons.tex("chip_lock"), Vector2(fx, fy))
		Ui.text(self, Vector2(fx + 11, fy + 9), str(ul.size()), Pal.e("lemon"))
		fx += 22
	var bans := Evolutions.bans_of(id)
	if not bans.is_empty():
		draw_texture(Icons.tex("chip_ban"), Vector2(fx, fy))
		Ui.text(self, Vector2(fx + 11, fy + 9), str(bans.size()), Pal.e("salmon"))


## Passives whose text only repeats their numbers show just the numbers.
func _short_desc(d: Dictionary) -> String:
	var ds := String(d.get("desc", ""))
	if String(d.get("type", "")) == "passive" and ds.begins_with("+") and not d.get("stats", {}).is_empty():
		return ""
	return ds


func _stat_line(p: Vector2, w: float, ln: Array) -> void:
	var lab := String(ln[0]).to_upper()
	var now := String(ln[1])
	var nxt := String(ln[2])
	var right := nxt if now == "" else now + ">" + nxt
	var rw := Ui.text_w(Ui.small(), right, 8)
	var lab_w := w - rw - 3
	# shorten the label rather than overflow the box
	while Ui.text_w(Ui.small(), lab, 8) > lab_w and lab.length() > 3:
		lab = lab.substr(0, lab.length() - 1)
	Ui.text(self, p, lab, BOX_TEXT, Ui.small(), 8, 0, false)
	var x := p.x + w - rw
	if now != "":
		Ui.text(self, Vector2(x, p.y), now + ">", Pal.e("grape"), Ui.small(), 8, 0, false)
		x += Ui.text_w(Ui.small(), now + ">", 8)
	Ui.text(self, Vector2(x, p.y), nxt, Pal.e("pine"), Ui.small(), 8, 0, false)


func _star(c: Vector2) -> void:
	var col := Pal.e("lemon")
	draw_rect(Rect2(c + Vector2(-1, -3), Vector2(3, 7)), Pal.INK)
	draw_rect(Rect2(c + Vector2(-3, -1), Vector2(7, 3)), Pal.INK)
	draw_rect(Rect2(c + Vector2(0, -2), Vector2(1, 5)), col)
	draw_rect(Rect2(c + Vector2(-2, 0), Vector2(5, 1)), col)


# ------------------------------------------------------------------ side panels
func _affinities(r: Rect2) -> void:
	Ui.wood(self, r)
	draw_rect(r.grow(-3), Ui.PARCHMENT)
	var pts := run.affinity_points()
	var y := r.position.y + 5
	for aff in AFF_ORDER:
		if aff == "duck" and run.duck_parts() == 0:
			continue
		draw_texture(Icons.tex("aff_" + aff), Vector2(r.position.x + 5, y))
		var p := int(pts.get(aff, 0))
		Ui.text(self, Vector2(r.position.x + 21, y + 9), str(p), BOX_TEXT, Ui.small(), 8, 0, false)
		Ui.text(self, Vector2(r.end.x - 5, y + 9), "+%d%%" % (p * 10), Pal.e("grass") if p > 0 else Ui.DIM, Ui.small(), 8, 2, false)
		y += 15
	# live preview: you now, or you with the selected card
	var pr := Rect2(r.position.x + 5, y + 3, r.size.x - 10, r.end.y - y - 8)
	if pr.size.y < 30:
		return
	draw_rect(pr, Color("c28569"))
	draw_rect(pr.grow(-1), Color("ead4aa").darkened(0.08))
	var look := run.look
	var label := "YOU"
	if sel >= 0 and sel < hand.size():
		look = _preview_look(String(hand[sel]))
		label = "WITH IT"
	Ui.creature_fit(self, look, Rect2(pr.position + Vector2(3, 3), pr.size - Vector2(6, 14)), int(t * 2.0))
	Ui.text(self, Vector2(pr.get_center().x, pr.end.y - 3), label, BOX_TEXT, Ui.small(), 8, 1, false)


var _previews := {}


## Your body after taking a card (cached while the screen is open).
func _preview_look(id: String) -> Dictionary:
	var k := id + "|" + str(run.owned.hash()) + "|" + str(run.level)
	if not _previews.has(k):
		_previews[k] = run.preview(id)
	return _previews[k]


func _side(r: Rect2) -> void:
	var y := r.position.y
	# mutagen
	Ui.wood(self, Rect2(r.position.x, y, r.size.x, 18))
	draw_texture(Props.tex("mutagen"), Vector2(r.position.x + 5, y + 3))
	Ui.text(self, Vector2(r.end.x - 6, y + 13), str(run.mutagen), Pal.e("leaf"), Ui.small(), 8, 2)
	y += 23
	if allow_mutagen:
		var ur := Rect2(r.position.x, y, r.size.x, 30)
		var can_u := run.mutagen >= run.upgrade_cost and Offers.min_rarity_of(run, hand) < 3
		_wood_button(ur, "UPGRADE", "%d" % run.upgrade_cost, can_u, is_down("upgrade"))
		if can_u:
			add_button("upgrade", ur)
		y += 35
		var rr := Rect2(r.position.x, y, r.size.x, 30)
		var free := run.free_rerolls > 0
		var can_r := free or run.mutagen >= run.reroll_cost
		_wood_button(rr, "REROLL", "FREE" if free else "%d" % run.reroll_cost, can_r, is_down("reroll"))
		if can_r:
			add_button("reroll", rr)
	var er := Rect2(r.position.x, r.end.y - 34, r.size.x, 34)
	if sel >= 0:
		var down := is_down("evolve")
		var e2 := Rect2(er.position + Vector2(0, 1 if down else 0), er.size)
		Ui.wood(self, e2)
		var g := Pal.e("leaf") if int(t * 3.0) % 2 == 0 else Pal.e("grass")
		draw_rect(e2.grow(-3), g)
		Ui.text(self, Vector2(e2.get_center().x, e2.get_center().y + 4), "EVOLVE", Color.WHITE, Ui.small(), 8, 1)
		add_button("evolve", er)
	else:
		Ui.para(self, Vector2(r.position.x + 1, er.position.y + 10), "TAP A CARD", r.size.x, Color.WHITE, Ui.small(), 8, 9)


func _wood_button(r: Rect2, label: String, cost: String, enabled: bool, down: bool) -> void:
	var rr := Rect2(r.position + Vector2(0, 1 if down else 0), r.size)
	Ui.wood(self, rr)
	draw_rect(rr.grow(-3), Color("5a3a35") if enabled else Color("3e2731"))
	var c := Color.WHITE if enabled else Ui.DIM
	Ui.text(self, Vector2(rr.get_center().x, rr.position.y + 12), label, c, Ui.small(), 8, 1)
	draw_texture(Props.tex("mutagen"), Vector2(rr.position.x + 6, rr.position.y + 15), Color(1, 1, 1, 1.0 if enabled else 0.5))
	Ui.text(self, Vector2(rr.end.x - 6, rr.position.y + 25), cost, Pal.e("leaf") if enabled else Ui.DIM, Ui.small(), 8, 2)
