extends Node
## Duck or no duck ?! — the state machine: title, run, choices (level up, Boss Fruit,
## points of interest), pause, end. Builds every node in code. Landscape only: in
## portrait a rotate hint covers the screen and the run waits.

enum S { TITLE, RUN, CHOICE, PAUSE, END, WAIT }

var state := S.TITLE
var world: World
var run: Run
var layer: CanvasLayer
var hud: Hud
var controls: TouchControls
var levelup: LevelUpScreen
var poi_screen: PoiScreen
var menu: MenuScreen
var rotate_hint: RotateHint
var queue: Array = []  # pending choices: {kind: "level"|"fruit"|"evo", min}
var wait_t := 0.0
var wait_then := ""
var cur_min := 0
var cur_source := "level"


func _ready() -> void:
	for id in Species.ALL:
		if not Species.get_def(id).get("boss", false):
			_bake.append(id)
	for id in Species.ALL:
		if Species.get_def(id).get("boss", false):
			_bake.append(id)
	_setup_input()
	world = World.new()
	world.process_mode = Node.PROCESS_MODE_PAUSABLE
	add_child(world)
	world.level_up.connect(_on_level_up)
	world.boss_fruit.connect(_on_boss_fruit)
	world.poi_choice.connect(_on_poi)
	world.player_died.connect(func() -> void: _wait(1.6, "lose"))
	world.run_won.connect(func() -> void: _wait(3.0, "win"))
	world.banner.connect(func(ti: String, sub: String) -> void: hud.show_banner(ti, sub))
	world.toast.connect(func(tx: String) -> void: hud.show_toast(tx))

	layer = CanvasLayer.new()
	layer.layer = 10
	add_child(layer)
	var root := Control.new()
	root.set_anchors_preset(Control.PRESET_FULL_RECT)
	root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.process_mode = Node.PROCESS_MODE_ALWAYS
	layer.add_child(root)
	hud = Hud.new()
	hud.world = world
	hud.pause_pressed.connect(_pause)
	root.add_child(hud)
	controls = TouchControls.new()
	controls.process_mode = Node.PROCESS_MODE_PAUSABLE
	controls.move_pressed.connect(func() -> void: world.combat.use_move())
	controls.ult_pressed.connect(func() -> void: world.combat.use_ult())
	root.add_child(controls)
	levelup = LevelUpScreen.new()
	levelup.picked.connect(_on_picked)
	levelup.reroll.connect(_on_reroll)
	levelup.upgrade.connect(_on_upgrade)
	root.add_child(levelup)
	poi_screen = PoiScreen.new()
	poi_screen.chosen.connect(_on_poi_option)
	root.add_child(poi_screen)
	menu = MenuScreen.new()
	menu.pressed.connect(_on_menu)
	root.add_child(menu)
	rotate_hint = RotateHint.new()
	root.add_child(rotate_hint)
	_title()
	_shot_args()
	if "--test" in OS.get_cmdline_user_args():
		var tester: Node = load("res://tests/sim_test.gd").new()
		tester.process_mode = Node.PROCESS_MODE_ALWAYS
		add_child(tester)
		tester.call_deferred("run", self)


## Screenshot mode for reviewing art: --shot=out.png [--scene=title|run|night|levelup|poi|boss|end] [--frames=N]
var _shot := ""
var _shot_frames := 90
var _shot_scene := "title"


func _shot_args() -> void:
	for a in OS.get_cmdline_user_args():
		if a.begins_with("--shot="):
			_shot = a.substr(7)
		elif a.begins_with("--frames="):
			_shot_frames = int(a.substr(9))
		elif a.begins_with("--scene="):
			_shot_scene = a.substr(8)
	if _shot == "":
		return
	Game.save_enabled = false
	if not _shot_scene in ["title", "genes"]:
		_start()
		run.level = 12
		for i in 14:
			run.take(String(Offers.roll(run, Game.rng, "level", 1)[0]))
		world.sync_player(true)
		match _shot_scene:
			"night":
				run.time = Run.DAY_LEN * 0.75
			"boss":
				run.time = Run.BOSS_TIMES[0] - 0.5
			"final":
				run.time = Run.FINAL_TIME - 0.5
				world.next_boss = 3
			"shore":
				# stand by a lake with trees around, to review terrain and props
				var best := world.player.position
				var best_s := -1
				for o in world.map.obstacles:
					if String(o["kind"]) != "tree":
						continue
					var op: Vector2 = o["p"]
					var sc := 0
					for a in 16:
						if world.map.water_at(op + Vector2.from_angle(a * TAU / 16.0) * 70.0) != 0:
							sc += 1
					if sc > best_s and sc < 10:
						best_s = sc
						best = op + Vector2(0, 30)
				world.player.position = best
				world.cam.position = best
	_shot_timer()


func _shot_timer() -> void:
	for i in _shot_frames:
		await get_tree().process_frame
		if _shot_scene in ["run", "night", "boss", "final"] and state == S.RUN:
			world.input_dir = Vector2(cos(i * 0.02), sin(i * 0.013)) * 0.6
		if _shot_scene == "eat" and i == _shot_frames - 25 and state == S.RUN:
			# standing at a pile of food with a full Cheek Pouch: the chew ring and pouch slots
			run.stats["pouch"] = 4.0
			for k in 6:
				var fd := world.spawn_food(world.player.position + Vector2(5 + k * 2, 2 - k), "fruit" if k % 2 == 0 else "meat", 3.0, k % 3)
				fd["v"] = Vector2.ZERO
	match _shot_scene:
		"levelup":
			queue.append({"kind": "level", "min": 0})
			_next_choice()
			levelup.press("card:1")
		"branch":
			queue.append({"kind": "fruit", "min": 0})
			_next_choice()
		"poi":
			_on_poi("sun_dial")
		"end":
			_end(true)
		"pause":
			_pause()
		"genes":
			menu.start_genes()
	for i in 10:
		await get_tree().process_frame
	print("sizes: vis=", get_viewport().get_visible_rect(), " hud=", hud.size, " menu=", menu.size, " root=", hud.get_parent().size, " win=", get_window().size, " content=", get_window().content_scale_size)
	var img := get_viewport().get_texture().get_image()
	img.save_png(_shot)
	print("shot saved: ", _shot, " ", img.get_size())
	get_tree().quit()


func _setup_input() -> void:
	var map := {
		"left": [KEY_A, KEY_LEFT], "right": [KEY_D, KEY_RIGHT], "up": [KEY_W, KEY_UP], "down": [KEY_S, KEY_DOWN],
		"ult": [KEY_SPACE, KEY_K], "move_ab": [KEY_SHIFT, KEY_J], "pause": [KEY_ESCAPE, KEY_P],
	}
	for action in map:
		if not InputMap.has_action(action):
			InputMap.add_action(action)
		for k in map[action]:
			var ev := InputEventKey.new()
			ev.physical_keycode = k
			InputMap.action_add_event(action, ev)


## Creature art is rendered once per body and cached; bake every animal while the title
## and menus are up (one per frame) so the first spawn of a species never stutters.
var _bake: Array = []


func _bake_step() -> void:
	if _bake.is_empty():
		return
	if state == S.RUN and world.running:
		return  # during play, bodies render on first spawn only
	Anatomy.frames(Species.look_of(String(_bake.pop_front())))


func _process(dt: float) -> void:
	_bake_step()
	var portrait := rotate_hint.active()
	match state:
		S.TITLE:
			world.cam.position += Vector2(14.0, 6.0) * dt
			world.cam.position = world.cam.position.clamp(Vector2(300, 200), Vector2(MapGen.SIZE - 300, MapGen.SIZE - 200))
		S.RUN:
			get_tree().paused = portrait
			var kb := Input.get_vector("left", "right", "up", "down")
			world.input_dir = controls.vector if controls.vector != Vector2.ZERO else kb
			if Input.is_action_just_pressed("ult"):
				world.combat.use_ult()
			if Input.is_action_just_pressed("move_ab"):
				world.combat.use_move()
			_buttons()
			if world.bosses.active():
				Sfx.music("boss")
			else:
				Sfx.music("night" if run.is_night() else "day")
		S.WAIT:
			wait_t -= dt
			if wait_t <= 0.0:
				_after_wait()
	if Input.is_action_just_pressed("pause"):
		if state == S.RUN:
			_pause()
		elif state == S.PAUSE:
			_resume()


func _buttons() -> void:
	var p := world.player
	if not World.valid(p):
		return
	var mv := run.move
	controls.btns["move"]["label"] = _short(mv)
	controls.btns["move"]["id"] = mv
	controls.btns["move"]["cd"] = world.combat.move_cd
	controls.btns["move"]["max"] = world.combat.move_max()
	var ul := run.ultimate
	controls.btns["ult"]["label"] = _short(ul)
	controls.btns["ult"]["id"] = ul
	controls.btns["ult"]["cd"] = world.combat.ult_cd
	controls.btns["ult"]["max"] = world.combat.ult_max()
	controls.blocked = [hud.pause_rect]


## A button label: the evolution's last word, at most 5 letters ("Body Slam" -> "SLAM").
func _short(id: String) -> String:
	if id == "":
		return ""
	var words := String(Evolutions.get_def(id)["name"]).to_upper().split(" ")
	return words[words.size() - 1].substr(0, 5)


func _notification(what: int) -> void:
	if what == NOTIFICATION_APPLICATION_FOCUS_OUT and state == S.RUN:
		_pause()


func _set_state(s: S) -> void:
	state = s
	var in_run := s in [S.RUN, S.CHOICE, S.PAUSE, S.WAIT]
	hud.visible = in_run
	controls.visible = s == S.RUN
	if s != S.RUN:
		controls.reset()
		world.input_dir = Vector2.ZERO


# ------------------------------------------------------------------ title and menus
func _title() -> void:
	get_tree().paused = false
	levelup.hide_screen()
	poi_screen.hide_screen()
	run = Run.new(Game.genetics, Game.pressure, Game.rng)
	world.build(Game.rng.randi(), run)
	world.running = false
	world.player.visible = false
	world.cam.position = world.map.start + Vector2(0, -40)
	hud.world = world
	menu.run = null
	menu.open("title")
	Sfx.music("day")
	_set_state(S.TITLE)


func _on_menu(id: String) -> void:
	match id:
		"play", "again":
			menu.start_genes()
		"genes_done":
			Game.genetics = menu.gene_picked.duplicate()
			_start()
		"genetics":
			menu.open("genetics")
		"codex":
			menu.codex_page = 0
			menu.open("codex")
		"page":
			menu.codex_page += 1
			menu.queue_redraw()
		"back", "title":
			if state == S.END:
				_title()
			else:
				menu.open("title")
		"pressure":
			Game.pressure = (Game.pressure + 1) % (Game.pressure_unlocked + 1)
			Game.save_meta()
		"sound":
			Game.sound = not Game.sound
			Game.save_meta()
		"shake":
			Game.shake = not Game.shake
			Game.save_meta()
		"resume":
			_resume()
		"quit":
			get_tree().paused = false
			_end(false)


func _start() -> void:
	get_tree().paused = false
	menu.hide_screen()
	run = Run.new(Game.genetics, Game.pressure, Game.rng)
	world.build(Game.rng.randi(), run)
	hud.world = world
	hud.build_minimap()
	controls.hint_t = 0.0
	queue.clear()
	Game.stats["runs"] = int(Game.stats["runs"]) + 1
	_set_state(S.RUN)
	hud.show_banner("DUCK OR NO DUCK ?!", "Eat. Evolve. Survive the bosses.")
	if run.has_gene("chosen"):
		queue.append({"kind": "evo", "min": 1})
		_next_choice()


func _pause() -> void:
	if state != S.RUN:
		return
	get_tree().paused = true
	menu.run = run
	menu.open("pause")
	_set_state(S.PAUSE)


func _resume() -> void:
	menu.hide_screen()
	get_tree().paused = false
	_set_state(S.RUN)


# ------------------------------------------------------------------ choices
func _on_level_up(n: int) -> void:
	for i in n:
		queue.append({"kind": "level", "min": 0})
	if state == S.RUN:
		_next_choice()


func _on_boss_fruit(_boss_id: String) -> void:
	queue.push_front({"kind": "fruit", "min": 0})
	if state == S.RUN:
		_next_choice()


func _on_poi(kind: String) -> void:
	get_tree().paused = true
	poi_screen.open(kind)
	_set_state(S.CHOICE)


func _on_poi_option(fx: Dictionary) -> void:
	poi_screen.hide_screen()
	world.apply_fx(fx)
	if fx.has("evo"):
		queue.push_front({"kind": "evo", "min": int(fx["evo"])})
	get_tree().paused = false
	_set_state(S.RUN)
	_next_choice()


func _next_choice() -> void:
	if queue.is_empty() or not world.running:
		get_tree().paused = false
		levelup.hide_screen()
		_set_state(S.RUN)
		return
	var c: Dictionary = queue.pop_front()
	run.reroll_cost = 1
	run.upgrade_cost = 10
	run.free_rerolls = 1 if run.has_gene("expert") else 0
	cur_min = int(c["min"])
	match String(c["kind"]):
		"level":
			cur_source = "level"
			_show_hand("EVOLUTION", "Level %d" % run.level, true)
		"fruit":
			cur_source = "boss"
			_show_hand("BRANCHING EVOLUTION", "Boss Fruit: your body plan branches", false)
		"evo":
			cur_source = "poi"
			_show_hand("EVOLVE", "Rare or better", true)


func _show_hand(title: String, sub: String, mutagen: bool) -> void:
	var hand := Offers.roll(run, Game.rng, cur_source, 3, cur_min)
	if hand.is_empty():
		_next_choice()
		return
	get_tree().paused = true
	levelup.open(run, hand, title, sub, mutagen)
	Sfx.play("evolve", 1.0, -4.0)
	_set_state(S.CHOICE)


func _on_picked(id: String) -> void:
	var old_look: Dictionary = run.look.duplicate()
	var replaced := run.take(id)
	Game.codex_evos[id] = true
	world.sync_player()
	# the new part grows out: a few in-between bodies before the new one
	if not old_look.is_empty():
		world.player.play_morph(old_look, run.look)
	world.fx.burst(world.player.position + Vector2(0, -world.player.r), Pal.c("gold", 4), 20, 70.0, 1.0, 0.6)
	var d := Evolutions.get_def(id)
	if String(d.get("type", "")) == "branch":
		# the body plan branches: a white flash, a burst in your colors, a banner
		var pl := world.player
		pl.hit_flash(Color.WHITE)
		world.fx.ring(pl.position + Vector2(0, -pl.r), 4.0, 70.0, 0.7, Color.WHITE)
		world.fx.burst(pl.position + Vector2(0, -pl.r), Pal.c(String(run.look.get("ramp", "slime")), 3), 40, 100.0, 2.0, 0.9)
		world.hitstop = 0.25
		Sfx.play("stage")
		hud.show_banner("BRANCHED: %s" % String(d["name"]).to_upper(), "Your body plan changes. New evolutions open up.")
	if d.get("duck_part", false):
		var n := run.duck_parts()
		hud.show_banner("DUCK!" if n < 8 else "TOTAL ANATIFICATION", "%d of 8 duck parts" % n)
		if n >= 8:
			Game.achieve("total_anatification")
	elif replaced != "":
		hud.show_toast("%s replaced %s" % [String(d["name"]), String(Evolutions.get_def(replaced)["name"])])
	levelup.hide_screen()
	_next_choice()


func _on_reroll() -> void:
	if run.free_rerolls > 0:
		run.free_rerolls -= 1
	elif run.mutagen >= run.reroll_cost:
		run.mutagen -= run.reroll_cost
		run.reroll_cost += 1
	else:
		return
	levelup.hand = Offers.roll(run, Game.rng, cur_source, 3, cur_min)
	levelup.show_screen()


func _on_upgrade() -> void:
	if run.mutagen < run.upgrade_cost:
		return
	run.mutagen -= run.upgrade_cost
	run.upgrade_cost += 10
	cur_min = mini(3, Offers.min_rarity_of(run, levelup.hand) + 1)
	levelup.hand = Offers.roll(run, Game.rng, cur_source, 3, cur_min)
	Sfx.play("mutagen")
	levelup.show_screen()


# ------------------------------------------------------------------ end
func _wait(t: float, then: String) -> void:
	wait_t = t
	wait_then = then
	levelup.hide_screen()
	poi_screen.hide_screen()
	get_tree().paused = false
	_set_state(S.WAIT)


func _after_wait() -> void:
	_end(wait_then == "win")


func _end(won: bool) -> void:
	world.running = false
	run.won = won
	var st := Game.stats
	st["best_level"] = maxi(int(st["best_level"]), run.level)
	st["kills"] = int(st["kills"]) + run.kills
	var duck := Genetics.is_duck(run)
	Game.achieve("verdict_duck" if duck else "verdict_noduck")
	var info := {"won": won, "duck": duck, "unlocked": Genetics.evaluate(run), "pressure_up": false}
	if won:
		st["wins"] = int(st["wins"]) + 1
		if run.pressure >= Game.pressure_unlocked and Game.pressure_unlocked < 5:
			Game.pressure_unlocked += 1
			info["pressure_up"] = true
	Game.save_meta()
	menu.run = run
	menu.end_info = info
	menu.open("end")
	Sfx.music("day")
	_set_state(S.END)
