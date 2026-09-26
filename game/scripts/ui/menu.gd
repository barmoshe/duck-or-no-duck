class_name MenuScreen
extends Screen
## Title, the Genetics pick before every run (two picks, each from a hand of three),
## the Genetics collection, Codex, Pause and End (with the DUCK / NO DUCK verdict).
## Everything is wood and parchment, the same look as the Evolution screen.

var mode := "title"
var run: Run
var end_info := {}  # {won, duck, unlocked: [], pressure_up}
var morph_step := 0
var morph_t := 0.0
var codex_page := 0
var gene_hand: Array = []
var gene_picked: Array = []


func open(m: String) -> void:
	mode = m
	show_screen()


## Start the pick-2-of-3 Genetics step before a run.
func start_genes() -> void:
	gene_picked.clear()
	gene_hand = Genetics.hand(Game.rng, gene_picked)
	open("genepick")


func press(id: String) -> void:
	if id.begins_with("gene:"):
		gene_picked.append(gene_hand[int(id.substr(5))])
		gene_hand = Genetics.hand(Game.rng, gene_picked)
		if gene_picked.size() >= 2 or gene_hand.is_empty():
			pressed.emit("genes_done")
		else:
			queue_redraw()
		return
	pressed.emit(id)


func _process(dt: float) -> void:
	super._process(dt)
	morph_t += dt
	if morph_t > (2.2 if morph_step >= 9 or morph_step == 0 else 0.8):
		morph_t = 0.0
		morph_step = (morph_step + 1) % 11


## The title's hero walks its evolution: slime, sprouting parts, mochi, then a mallard.
var _morphs: Array = []


func _morph_look() -> Dictionary:
	if _morphs.is_empty():
		var r := Run.new("pioneer", 0, null)
		_morphs.append(r.look.duplicate())
		for id in ["duck_bill", "webbed_feet", "beady_eyes", "tail_curl", "duck_wings", "down_feathers", "green_crest", "shell", "convergent"]:
			r.take(id)
			_morphs.append(r.look.duplicate())
	return _morphs[mini(morph_step, _morphs.size() - 1)]


func _draw() -> void:
	begin()
	match mode:
		"title":
			_title()
		"genepick":
			_genepick()
		"genetics":
			_genetics()
		"codex":
			_codex()
		"pause":
			_pause()
		"end":
			_end()


func _btn(id: String, r: Rect2, label: String, face: Color, enabled: bool = true, size: int = 8) -> void:
	Ui.wood_button(self, r, label, face, is_down(id), enabled, size)
	if enabled:
		add_button(id, r)


const GREEN := Color("3e8948")
const BROWN := Color("733e39")
const RED := Color("a22633")


# ------------------------------------------------------------------ title
func _title() -> void:
	draw_rect(Rect2(Vector2.ZERO, size), Color(Pal.INK, 0.25))
	var s := safe()
	var cx := s.get_center().x
	var top := s.position.y
	var bot := s.end.y
	# the logo on a wooden sign
	var sign := Rect2(floorf(cx - 92), top + 4, 184, 52)
	Ui.wood(self, sign)
	draw_rect(Rect2(sign.position + Vector2(3, sign.size.y - 4), Vector2(sign.size.x - 6, 1)), Ui.WOOD_LO)
	Ui.text(self, Vector2(cx, top + 32), "DUCK", Pal.c("gold", 3), Ui.bold(), 32, 1)
	Ui.text(self, Vector2(cx, top + 50), "OR NO DUCK ?!", Color.WHITE, Ui.bold(), 16, 1)
	# the evolving hero between the sign and the buttons
	var cy := floorf((top + 60 + bot - 58) * 0.5) + 4
	var sc := 3 if s.size.y > 250 else 2
	draw_circle(Vector2(cx, cy + 6).floor(), 22.0 * sc / 2.0, Color(Pal.c("gold", 3), 0.14 + 0.05 * sin(t * 3.0)))
	Ui.creature_fit(self, _morph_look(), Rect2(cx - 22.0 * sc, cy - 14.0 * sc, 44.0 * sc, 26.0 * sc), int(t * 2.0))
	var bw := 130.0
	_btn("play", Rect2(cx - bw * 0.5, bot - 56, bw, 26), "PLAY", GREEN, true, 16)
	var row := ["genetics", "codex", "sound"]
	var labels := ["GENETICS", "CODEX", "SOUND " + ("ON" if Game.sound else "OFF")]
	if Game.pressure_unlocked > 0:
		row.insert(1, "pressure")
		labels.insert(1, "PRESSURE %d" % Game.pressure)
	var widths: Array[float] = []
	var total := 0.0
	for l in labels:
		var wv := Ui.text_w(Ui.small(), l, 8) + 14.0
		widths.append(wv)
		total += wv + 4.0
	var x := cx - (total - 4.0) * 0.5
	for i in row.size():
		_btn(row[i], Rect2(x, bot - 26, widths[i], 17), labels[i], BROWN)
		x += widths[i] + 4.0
	var st := Game.stats
	if int(st["runs"]) > 0:
		Ui.text(self, Vector2(s.end.x - 2, bot - 3), "RUNS %d  WINS %d  BEST LV %d" % [int(st["runs"]), int(st["wins"]), int(st["best_level"])], Ui.DIM, Ui.small(), 8, 2)
	Ui.text(self, Vector2(s.position.x + 2, bot - 3), "v0.3 " + Game.web_build(), Color(Ui.DIM, 0.6))


func _unhandled_input(event: InputEvent) -> void:
	if visible and event is InputEventKey and event.pressed and not event.echo and event.keycode in [KEY_ENTER, KEY_KP_ENTER]:
		match mode:
			"title":
				press("play")
			"genepick":
				if not gene_hand.is_empty():
					press("gene:0")
			"end":
				press("again")
			"pause":
				press("resume")


# ------------------------------------------------------------------ genetics pick (2 of 3)
func _genepick() -> void:
	draw_rect(Rect2(Vector2.ZERO, size), Color(Pal.INK, 0.7))
	var s := safe()
	var cx := s.get_center().x
	Ui.ribbon(self, Vector2(cx, s.position.y + 2), "GENETICS %d/2" % (gene_picked.size() + 1))
	Ui.text(self, Vector2(cx, s.position.y + 34), "Pick one. Both picks shape the creature you hatch as.", Color.WHITE, Ui.small(), 8, 1)
	var n := gene_hand.size()
	var cw := floorf(minf(128.0, (s.size.x - 20.0 - (n - 1) * 6.0) / maxf(1, n)))
	var ch := minf(96.0, s.size.y - 84.0)
	var x0 := floorf(cx - (cw * n + (n - 1) * 6.0) * 0.5)
	var y := s.position.y + 42
	for i in n:
		var id := String(gene_hand[i])
		var g: Dictionary = Genetics.ALL[id]
		var r := Rect2(x0 + i * (cw + 6.0), y + (1 if is_down("gene:%d" % i) else 0), cw, ch)
		Ui.board(self, r)
		draw_texture(Props.tex("mutagen"), Vector2(floorf(r.get_center().x - 4), r.position.y + 7))
		Ui.para(self, Vector2(r.position.x + 7, r.position.y + 30), String(g["name"]).to_upper(), r.size.x - 14, Ui.INK_TEXT, Ui.small(), 8, 9, false)
		draw_rect(Rect2(r.position.x + 7, r.position.y + 34, r.size.x - 14, 1), Color(Ui.INK_TEXT, 0.3))
		Ui.para(self, Vector2(r.position.x + 7, r.position.y + 46), String(g["desc"]), r.size.x - 14, Color("5a3a35"), Ui.small(), 8, 9, false)
		add_button("gene:%d" % i, r)
	if not gene_picked.is_empty():
		var names: Array[String] = []
		for p in gene_picked:
			names.append(String(Genetics.ALL[p]["name"]).to_upper())
		Ui.text(self, Vector2(cx, s.end.y - 24), "PICKED: " + ", ".join(names), Pal.e("leaf"), Ui.small(), 8, 1)
	_btn("back", Rect2(s.position.x, s.end.y - 18, 60, 18), "BACK", BROWN)


# ------------------------------------------------------------------ genetics collection
func _genetics() -> void:
	draw_rect(Rect2(Vector2.ZERO, size), Color(Pal.INK, 0.7))
	var s := safe()
	var cx := s.get_center().x
	Ui.ribbon(self, Vector2(cx, s.position.y + 2), "GENETICS")
	var b := Rect2(s.position.x + 6, s.position.y + 26, s.size.x - 12, s.size.y - 50)
	Ui.board(self, b)
	var cols := 2
	var cw := (b.size.x - 12) / cols
	var rows := ceili(Genetics.ORDER.size() / float(cols))
	var rh := minf(30.0, (b.size.y - 8) / rows)
	for i in Genetics.ORDER.size():
		var id := String(Genetics.ORDER[i])
		var g: Dictionary = Genetics.ALL[id]
		var ok: bool = id in Game.unlocked_genetics
		var p := b.position + Vector2(6 + (i % cols) * cw, 6 + (i / cols) * rh)
		Ui.text(self, p + Vector2(0, 8), String(g["name"]).to_upper() if ok else "???", Ui.INK_TEXT if ok else Color("8b6a5a"), Ui.small(), 8, 0, false)
		var sub := String(g["desc"]) if ok else "LOCKED: " + String(g["goal"])
		Ui.para(self, p + Vector2(0, 17), sub, cw - 8, Color("5a3a35") if ok else Pal.e("wine"), Ui.small(), 8, 8, false)
	Ui.text(self, Vector2(cx, s.end.y - 12), "Before every run you pick two of them.", Color.WHITE, Ui.small(), 8, 1)
	_btn("back", Rect2(s.position.x, s.end.y - 18, 60, 18), "BACK", BROWN)


# ------------------------------------------------------------------ codex
func _codex() -> void:
	draw_rect(Rect2(Vector2.ZERO, size), Color(Pal.INK, 0.7))
	var s := safe()
	var cx := s.get_center().x
	Ui.ribbon(self, Vector2(cx, s.position.y + 2), "CODEX")
	var b := Rect2(s.position.x + 6, s.position.y + 26, s.size.x - 12, s.size.y - 50)
	Ui.board(self, b)
	var ids: Array = []
	for id in Species.ALL:
		ids.append(id)
	var cols := maxi(3, int((b.size.x - 8) / 60.0))
	var cw := (b.size.x - 8) / cols
	var ch := 44.0
	var rows_fit := maxi(1, int((b.size.y - 8) / ch))
	var per := cols * rows_fit
	var pages := ceili(ids.size() / float(per))
	codex_page = clampi(codex_page, 0, pages - 1)
	for i in range(codex_page * per, mini(ids.size(), (codex_page + 1) * per)):
		var k := i - codex_page * per
		var r := Rect2(b.position.x + 4 + (k % cols) * cw, b.position.y + 4 + (k / cols) * ch, cw - 3, ch - 3)
		var id: String = ids[i]
		var seen := Game.codex_species.has(id)
		draw_rect(r, Color("c28569"))
		draw_rect(r.grow(-1), Color("ead4aa").darkened(0.06))
		if seen:
			var lk := Species.look_of(id)
			lk["size"] = mini(int(lk["size"]), 8)
			Ui.creature_fit(self, lk, Rect2(r.position + Vector2(2, 2), r.size - Vector2(4, 14)))
			Ui.text(self, Vector2(r.get_center().x, r.end.y - 3), String(Species.ALL[id]["name"]).to_upper().substr(0, 11), Ui.INK_TEXT, Ui.small(), 8, 1, false)
		else:
			Ui.text(self, r.get_center() + Vector2(0, 4), "?", Color("8b6a5a"), Ui.bold(), 16, 1, false)
	var found := Game.codex_evos.size()
	Ui.text(self, Vector2(cx, s.end.y - 6), "EVOLUTIONS FOUND %d / %d" % [found, Evolutions.ALL.size()], Pal.c("gold", 3), Ui.small(), 8, 1)
	if pages > 1:
		_btn("page", Rect2(s.end.x - 70, s.end.y - 18, 70, 18), "PAGE %d/%d" % [codex_page + 1, pages], BROWN)
	_btn("back", Rect2(s.position.x, s.end.y - 18, 60, 18), "BACK", BROWN)


# ------------------------------------------------------------------ pause
func _pause() -> void:
	draw_rect(Rect2(Vector2.ZERO, size), Color(Pal.INK, 0.7))
	var s := safe()
	var cx := s.get_center().x
	Ui.ribbon(self, Vector2(cx, s.position.y + 2), "PAUSED")
	if run == null:
		return
	var top := s.position.y + 26
	# left: you and your affinities
	var lb := Rect2(s.position.x, top, 96, s.end.y - top)
	Ui.board(self, lb)
	Ui.creature_fit(self, run.look, Rect2(lb.position.x + 6, lb.position.y + 6, lb.size.x - 12, 46), int(t * 2.0))
	var pts := run.affinity_points()
	var y := lb.position.y + 58
	for aff in ["predator", "prey", "gregarious", "imposing", "trickster", "duck"]:
		if aff == "duck" and run.duck_parts() == 0:
			continue
		draw_texture(Icons.tex("aff_" + aff), Vector2(lb.position.x + 6, y))
		Ui.text(self, Vector2(lb.position.x + 22, y + 9), str(int(pts.get(aff, 0))), Ui.INK_TEXT, Ui.small(), 8, 0, false)
		Ui.text(self, Vector2(lb.end.x - 6, y + 9), "+%d%%" % (int(pts.get(aff, 0)) * 10), Pal.e("grass"), Ui.small(), 8, 2, false)
		y += 14
	# middle: the build
	var rw := 70.0
	var mb := Rect2(lb.end.x + 5, top, s.end.x - lb.end.x - 10 - rw, s.end.y - top)
	Ui.board(self, mb)
	var x := mb.position.x + 6
	var yy := mb.position.y + 5
	var slots: Array = run.attacks.duplicate()
	if run.ultimate != "":
		slots.append(run.ultimate)
	slots.append(run.move)
	for id in slots:
		Ui.slot(self, Rect2(x, yy, 20, 20), Icons.tex(String(id)), 0.0)
		Ui.text(self, Vector2(x + 10, yy + 29), "L%d" % run.rank(String(id)), Ui.INK_TEXT, Ui.small(), 8, 1, false)
		x += 24
	yy += 40
	var pas: Array[String] = []
	for id in run.order:
		var d := Evolutions.get_def(id)
		if String(d.get("type", "")) in ["passive", "branch"]:
			pas.append("%s%s" % [String(d["name"]).to_upper(), "" if int(d.get("max", 1)) < 2 else " L%d" % run.rank(id)])
	var used := Ui.para(self, Vector2(mb.position.x + 6, yy), ", ".join(pas) if not pas.is_empty() else "NO PASSIVES YET", mb.size.x - 12, Ui.INK_TEXT, Ui.small(), 8, 8, false)
	yy += used + 2
	var fe := run.food_eaten
	var diet := "ATE %d FRUIT, %d MEAT, %d FISH" % [int(fe.get("fruit", 0)), int(fe.get("meat", 0)), int(fe.get("fish", 0))]
	Ui.para(self, Vector2(mb.position.x + 6, yy), diet, mb.size.x - 12, Color("5a3a35"), Ui.small(), 8, 8, false)
	var st := run.stats
	Ui.para(self, Vector2(mb.position.x + 6, mb.end.y - 14), "LV %d  PHY %d  ABI %d  HP %d  ARM %d  SPD %.1f  DUCK %d/8" % [run.level, st["physical"], st["ability"], st["max_hp"], st["armor"], st["speed"], run.duck_parts()], mb.size.x - 12, Ui.INK_TEXT, Ui.small(), 8, 8, false)
	# right: buttons
	var bx := s.end.x - rw
	_btn("resume", Rect2(bx, top, rw, 28), "RESUME", GREEN)
	_btn("sound", Rect2(bx, top + 33, rw, 20), "SOUND " + ("ON" if Game.sound else "OFF"), BROWN)
	_btn("shake", Rect2(bx, top + 57, rw, 20), "SHAKE " + ("ON" if Game.shake else "OFF"), BROWN)
	_btn("quit", Rect2(bx, s.end.y - 22, rw, 22), "GIVE UP", RED)


# ------------------------------------------------------------------ end: the verdict
func _end() -> void:
	draw_rect(Rect2(Vector2.ZERO, size), Color(Pal.INK, 0.72))
	var s := safe()
	var cx := s.get_center().x
	var won := bool(end_info.get("won", false))
	var duck := bool(end_info.get("duck", false))
	Ui.ribbon(self, Vector2(cx, s.position.y + 2), "VERDICT: " + ("DUCK!" if duck else "NO DUCK"), not duck)
	var sub := "You beat the pond." if won else "Extinct at %d:%02d." % [int(run.time) / 60 if run else 0, int(run.time) % 60 if run else 0]
	sub += " You ended up a duck." if duck else " Whatever you were, it was not a duck."
	Ui.text(self, Vector2(cx, s.position.y + 34), sub, Pal.e("lemon") if won else Color.WHITE, Ui.small(), 8, 1)
	var b := Rect2(cx - minf(170.0, s.size.x * 0.5 - 6), s.position.y + 40, minf(340.0, s.size.x - 12), s.end.y - s.position.y - 66)
	Ui.board(self, b)
	if run:
		Ui.creature_fit(self, run.look, Rect2(b.position.x + 8, b.position.y + 8, 84, b.size.y - 16), int(t * 2.0))
		var x := b.position.x + 100
		var y := b.position.y + 16
		var fe := run.food_eaten
		var lines := [
			"TIME %d:%02d   LEVEL %d" % [int(run.time) / 60, int(run.time) % 60, run.level],
			"KILLS %d   BOSSES BEATEN %d   OUTLASTED %d" % [run.kills, run.bosses_killed, run.bosses_survived],
			"ATE %d FRUIT, %d MEAT, %d FISH" % [int(fe.get("fruit", 0)), int(fe.get("meat", 0)), int(fe.get("fish", 0))],
			"DUCK PARTS %d/8   EVOLUTIONS %d" % [run.best_duck_parts, run.order.size()],
		]
		for ln in lines:
			y += Ui.para(self, Vector2(x, y), ln, b.end.x - x - 6, Ui.INK_TEXT, Ui.small(), 8, 9, false) + 2
		for id in end_info.get("unlocked", []):
			Ui.text(self, Vector2(x, y), "NEW GENETIC: " + String(Genetics.ALL[id]["name"]).to_upper(), Pal.e("grass"), Ui.small(), 8, 0, false)
			y += 10
		if end_info.get("pressure_up", false):
			Ui.text(self, Vector2(x, y), "SELECTIVE PRESSURE %d UNLOCKED" % Game.pressure_unlocked, Pal.e("wine"), Ui.small(), 8, 0, false)
	var bw := 110.0
	_btn("again", Rect2(cx - bw - 3, s.end.y - 22, bw, 22), "PLAY AGAIN", GREEN)
	_btn("title", Rect2(cx + 3, s.end.y - 22, bw, 22), "TITLE", BROWN)
