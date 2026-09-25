class_name MenuScreen
extends Screen
## Title, Genetics, Codex, Pause and End screens, one mode at a time.

var mode := "title"
var run: Run
var end_info := {}  # {won, unlocked: []}
var morph_step := 0
var morph_t := 0.0
var codex_page := 0


func open(m: String) -> void:
	mode = m
	show_screen()


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
		"genetics":
			_genetics()
		"codex":
			_codex()
		"pause":
			_pause()
		"end":
			_end()


func _btn(id: String, r: Rect2, label: String, col: Color, enabled: bool = true, size: int = 8) -> void:
	Ui.button(self, r, label, col, is_down(id), enabled, size)
	if enabled:
		add_button(id, r)


# ------------------------------------------------------------------ title
func _title() -> void:
	draw_rect(Rect2(Vector2.ZERO, size), Color(Pal.INK, 0.3))
	var s := safe()
	var cx := s.get_center().x
	var top := s.position.y
	var bot := s.end.y
	# logo
	Ui.text(self, Vector2(cx, top + 30), "DUCK", Pal.c("gold", 3), Ui.bold(), 32, 1)
	Ui.text(self, Vector2(cx, top + 47), "OR NO DUCK ?!", Color.WHITE, Ui.bold(), 16, 1)
	# the evolving hero between the logo and the buttons
	var cy := floorf((top + 52 + bot - 60) * 0.5) + 4
	var sc := 3 if s.size.y > 250 else 2
	draw_circle(Vector2(cx, cy + 6).floor(), 22.0 * sc / 2.0, Color(Pal.c("gold", 3), 0.12 + 0.05 * sin(t * 3.0)))
	Ui.creature(self, _morph_look(), Vector2(cx, cy), sc, int(t * 2.0))
	# buttons: PLAY, then a row of small ones, then the stats line
	var bw := 130.0
	_btn("play", Rect2(cx - bw * 0.5, bot - 54, bw, 22), "PLAY", Pal.c("gold", 3), true, 16)
	var row := ["genetics", "codex", "sound"]
	var labels := ["GENETIC: " + String(Genetics.ALL[Game.genetic]["name"]).to_upper(), "CODEX", "SOUND " + ("ON" if Game.sound else "OFF")]
	if Game.pressure_unlocked > 0:
		row.insert(1, "pressure")
		labels.insert(1, "PRESSURE %d" % Game.pressure)
	var widths: Array[float] = []
	var total := 0.0
	for l in labels:
		var wv := Ui.text_w(Ui.small(), l, 8) + 12.0
		widths.append(wv)
		total += wv + 4.0
	var x := cx - (total - 4.0) * 0.5
	for i in row.size():
		_btn(row[i], Rect2(x, bot - 28, widths[i], 15), labels[i], Pal.c("green", 3) if row[i] == "genetics" else Color("5a6988"))
		x += widths[i] + 4.0
	var st := Game.stats
	if int(st["runs"]) > 0:
		Ui.text(self, Vector2(cx, bot - 3), "RUNS %d  WINS %d  BEST LV %d" % [int(st["runs"]), int(st["wins"]), int(st["best_level"])], Ui.DIM, Ui.small(), 8, 1)
	Ui.text(self, Vector2(s.position.x + 2, bot - 3), "v0.1 " + Game.web_build(), Color(Ui.DIM, 0.6))


func _unhandled_input(event: InputEvent) -> void:
	if visible and event is InputEventKey and event.pressed and not event.echo and event.keycode in [KEY_ENTER, KEY_KP_ENTER]:
		if mode == "title":
			press("play")
		elif mode == "end":
			press("again")
		elif mode == "pause":
			press("resume")


# ------------------------------------------------------------------ genetics
func _genetics() -> void:
	draw_rect(Rect2(Vector2.ZERO, size), Color(Pal.INK, 0.85))
	var s := safe()
	var cx := s.get_center().x
	Ui.text(self, Vector2(cx, s.position.y + 16), "GENETICS", Pal.c("green", 4), Ui.bold(), 16, 1)
	Ui.text(self, Vector2(cx, s.position.y + 26), "Pick how your next creature hatches", Ui.DIM, Ui.small(), 8, 1)
	var w := minf(s.size.x - 8, 300.0)
	var x := cx - w * 0.5
	var y := s.position.y + 34
	var rh := minf(30.0, (s.size.y - 70.0) / Genetics.ORDER.size())
	for id in Genetics.ORDER:
		var g: Dictionary = Genetics.ALL[id]
		var unlocked: bool = id in Game.unlocked_genetics
		var r := Rect2(x, y, w, rh - 3)
		var sel: bool = Game.genetic == id
		Ui.panel(self, r, Color("3e8948") if sel else Color("262b44"), Pal.c("gold", 3) if sel else Pal.INK)
		Ui.text(self, r.position + Vector2(5, 10), String(g["name"]).to_upper() if unlocked else "???", Color.WHITE if unlocked else Ui.DIM)
		Ui.text(self, r.position + Vector2(5, 20), String(g["desc"]) if unlocked else "LOCKED: " + String(g["goal"]), Color("c0cbdc") if unlocked else Pal.c("red", 3))
		if unlocked:
			add_button("gen:" + id, r)
		y += rh
	_btn("back", Rect2(cx - 40, s.end.y - 20, 80, 16), "BACK", Color("5a6988"))


# ------------------------------------------------------------------ codex
func _codex() -> void:
	draw_rect(Rect2(Vector2.ZERO, size), Color(Pal.INK, 0.9))
	var s := safe()
	var cx := s.get_center().x
	Ui.text(self, Vector2(cx, s.position.y + 16), "CODEX", Pal.c("blue", 4), Ui.bold(), 16, 1)
	var ids: Array = []
	for id in Species.ALL:
		ids.append(id)
	var cols := maxi(3, int((s.size.x - 8) / 62.0))
	var cw := (s.size.x - 8) / cols
	var ch := 46.0
	var rows_fit := maxi(1, int((s.size.y - 70) / ch))
	var per := cols * rows_fit
	var pages := ceili(ids.size() / float(per))
	codex_page = clampi(codex_page, 0, pages - 1)
	for i in range(codex_page * per, mini(ids.size(), (codex_page + 1) * per)):
		var k := i - codex_page * per
		var r := Rect2(s.position.x + 4 + (k % cols) * cw, s.position.y + 26 + (k / cols) * ch, cw - 3, ch - 3)
		var id: String = ids[i]
		var seen := Game.codex_species.has(id)
		Ui.panel(self, r, Color("262b44"))
		if seen:
			var lk := Species.look_of(id)
			lk["size"] = mini(int(lk["size"]), 8)
			Ui.creature(self, lk, r.get_center() + Vector2(0, -4), 1)
			Ui.text(self, Vector2(r.get_center().x, r.end.y - 4), String(Species.ALL[id]["name"]).to_upper().substr(0, 11), Color.WHITE, Ui.small(), 8, 1)
		else:
			Ui.text(self, r.get_center() + Vector2(0, 3), "?", Ui.DIM, Ui.bold(), 16, 1)
	var found := Game.codex_evos.size()
	Ui.text(self, Vector2(cx, s.end.y - 24), "EVOLUTIONS FOUND %d / %d" % [found, Evolutions.ALL.size()], Pal.c("gold", 3), Ui.small(), 8, 1)
	if pages > 1:
		_btn("page", Rect2(s.end.x - 60, s.end.y - 20, 56, 16), "PAGE %d/%d" % [codex_page + 1, pages], Color("5a6988"))
	_btn("back", Rect2(cx - 40, s.end.y - 20, 80, 16), "BACK", Color("5a6988"))


# ------------------------------------------------------------------ pause
func _pause() -> void:
	draw_rect(Rect2(Vector2.ZERO, size), Color(Pal.INK, 0.8))
	var s := safe()
	var cx := s.get_center().x
	Ui.text(self, Vector2(cx, s.position.y + 18), "PAUSED", Color.WHITE, Ui.bold(), 16, 1)
	var y := s.position.y + 30
	if run:
		Ui.creature(self, run.look, Vector2(cx, y + 26), 2, int(t * 2.0))
		y += 54
		var lines: Array[String] = []
		lines.append("LV %d  DUCK PARTS %d/8  TIME %d:%02d" % [run.level, run.duck_parts(), int(run.time) / 60, int(run.time) % 60])
		lines.append("ATTACKS: " + ", ".join(run.attacks.map(func(a): return "%s %d" % [String(Evolutions.get_def(a)["name"]), run.rank(a)])))
		lines.append("ULTIMATE: " + (String(Evolutions.get_def(run.ultimate)["name"]) if run.ultimate != "" else "none") + "   MOVE: " + String(Evolutions.get_def(run.move)["name"]))
		var pas: Array[String] = []
		for id in run.order:
			if Evolutions.get_def(id)["type"] in ["passive", "branch"]:
				pas.append("%s%s" % [String(Evolutions.get_def(id)["name"]), "" if run.rank(id) < 2 else " x%d" % run.rank(id)])
		lines.append("PASSIVES: " + (", ".join(pas) if not pas.is_empty() else "none yet"))
		var st := run.stats
		lines.append("PHY %d  ABI %d  HP %d  SPD %.1f  ARM %d  SOC %d" % [st["physical"], st["ability"], st["max_hp"], st["speed"], st["armor"], st["social"]])
		for ln in lines:
			y += Ui.para(self, Vector2(s.position.x + 8, y), ln, s.size.x - 16, Color("c0cbdc"))
	var bw := 110.0
	var by := maxf(y + 6, s.end.y - 64)
	_btn("resume", Rect2(cx - bw * 0.5, by, bw, 18), "RESUME", Pal.c("gold", 3))
	_btn("sound", Rect2(cx - bw * 0.5, by + 22, bw * 0.48, 16), "SOUND " + ("ON" if Game.sound else "OFF"), Color("5a6988"))
	_btn("shake", Rect2(cx + bw * 0.02, by + 22, bw * 0.48, 16), "SHAKE " + ("ON" if Game.shake else "OFF"), Color("5a6988"))
	_btn("quit", Rect2(cx - bw * 0.5, by + 42, bw, 16), "GIVE UP", Pal.c("red", 2))


# ------------------------------------------------------------------ end
func _end() -> void:
	draw_rect(Rect2(Vector2.ZERO, size), Color(Pal.INK, 0.85))
	var s := safe()
	var cx := s.get_center().x
	var won := bool(end_info.get("won", false))
	var y := s.position.y + 20
	Ui.text(self, Vector2(cx, y), "DUCK!" if won else "NO DUCK...EXTINCT", Pal.c("gold", 3) if won else Pal.c("red", 3), Ui.bold(), 16, 1)
	y += 12
	Ui.text(self, Vector2(cx, y), "The pond is yours." if won else "The pond keeps evolving without you.", Ui.DIM, Ui.small(), 8, 1)
	if run:
		Ui.creature(self, run.look, Vector2(cx, y + 30), 3 if s.size.y > 300 else 2, int(t * 2.0))
		y += 62
		var lines := [
			"TIME %d:%02d   LEVEL %d" % [int(run.time) / 60, int(run.time) % 60, run.level],
			"EATEN %d   BOSSES BEATEN %d   SURVIVED %d" % [run.kills, run.bosses_killed, run.bosses_survived],
			"DUCK PARTS %d/8   EVOLUTIONS %d" % [run.best_duck_parts, run.order.size()],
		]
		for ln in lines:
			Ui.text(self, Vector2(cx, y), ln, Color.WHITE, Ui.small(), 8, 1)
			y += 10
	var unl: Array = end_info.get("unlocked", [])
	for id in unl:
		y += 2
		Ui.text(self, Vector2(cx, y), "UNLOCKED GENETIC: " + String(Genetics.ALL[id]["name"]).to_upper(), Pal.c("green", 4), Ui.small(), 8, 1)
		y += 10
	if end_info.get("pressure_up", false):
		Ui.text(self, Vector2(cx, y), "SELECTIVE PRESSURE %d UNLOCKED" % Game.pressure_unlocked, Pal.c("red", 4), Ui.small(), 8, 1)
		y += 10
	var bw := 110.0
	var by := maxf(y + 8, s.end.y - 42)
	_btn("again", Rect2(cx - bw * 0.5, by, bw, 18), "PLAY AGAIN", Pal.c("gold", 3))
	_btn("title", Rect2(cx - bw * 0.5, by + 22, bw, 16), "TITLE", Color("5a6988"))
