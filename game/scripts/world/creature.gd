class_name Creature
extends Node2D
## One creature: the player or any pond animal. Holds parts, stats and timers, integrates
## its own movement and draws itself through CreatureArt. Decisions (AI) and combat live
## in World, which sees everyone at once.

const PLAYER_COLOR := Color(0.96, 0.62, 0.72)

var species := "player"
var is_player := false
var is_boss := false
var parts: Dictionary = {}
var level := 0
var stats: Dictionary = {}
var r := 12.0
var hp := 30.0
var max_hp := 30.0
var bite_dmg := 3.0
var speed := 110.0
var color := PLAYER_COLOR
var behavior := "neutral"
var biome := 0

var vel := Vector2.ZERO
var desired := Vector2.ZERO
var facing := 0.0
var anim_t := 0.0
var move_amt := 0.0

var bite_cd := 0.0
var bite_anim := 0.0
var flap_anim := 0.0
var hurt_flash := 0.0
var squash := 0.0
var stun := 0.0
var fear := 0.0
var poison := 0.0
var poison_t := 0.0
var since_hurt := 99.0
var dash_t := 0.0
var dash_dir := Vector2.ZERO
var dash_mult := 3.2
var cd_move := 0.0
var cd_special := 0.0
var dead := false

# AI
var ai_timer := 0.0
var target: Creature = null
var angry_at: Creature = null
var angry_t := 0.0
var last_hit_by: Creature = null
var state := "wander"
var wander := Vector2.ZERO
var home := Vector2.ZERO
var hunt_mult := 1.0
var speed_mult := 1.0
# boss
var boss_t := 0.0
var boss_phase := ""
var boss_phase_t := 0.0
var boss_cycle := 0


func _ready() -> void:
	anim_t = randf() * 10.0


func setup_player(p: Dictionary, lv: int) -> void:
	is_player = true
	species = "player"
	parts = p.duplicate()
	level = lv
	color = PLAYER_COLOR
	refresh_stats(true)
	z_index = 5


func setup_species(id: String, stage: int, bio: int, rng: RandomNumberGenerator) -> void:
	species = id
	var d := Species.get_def(id)
	behavior = String(d["behavior"])
	is_boss = behavior == "boss"
	biome = bio
	color = d["color"]
	parts = Species.parts_at_stage(id, stage)
	level = int(d["biome"]) * 3
	var base_r := float(d["r"])
	r = base_r * (1.0 if is_boss else rng.randf_range(0.85, 1.18))
	speed_mult = float(d["speed"])
	refresh_stats(true)
	ai_timer = rng.randf() * 0.3
	wander = Vector2.from_angle(rng.randf() * TAU)
	z_index = 8 if is_boss else 2


func refresh_stats(full_heal: bool = false) -> void:
	stats = Parts.compute_stats(parts, level)
	var ratio := hp / maxf(1.0, max_hp)
	if is_player:
		r = Evolution.radius_for(level, float(stats["size"]))
		max_hp = float(stats["hp"])
		bite_dmg = float(stats["bite"])
		speed = float(stats["speed"]) * (1.0 + 0.012 * level)
	else:
		var d := Species.get_def(species)
		max_hp = float(stats["hp"]) * float(d["hp"])
		bite_dmg = float(stats["bite"]) * float(d["bite"])
		speed = float(stats["speed"]) * speed_mult
	hp = max_hp if full_heal else max_hp * ratio


func set_parts(p: Dictionary) -> void:
	parts = p.duplicate()
	refresh_stats(false)
	squash = 1.0
	queue_redraw()


func duck_count() -> int:
	return int(stats.get("duck_count", 0))


func sight() -> float:
	return float(stats.get("sight", 230.0)) + r * 3.0


func can_act() -> bool:
	return stun <= 0.0 and not dead


func tick(dt: float) -> void:
	anim_t += dt
	bite_cd = maxf(0.0, bite_cd - dt)
	bite_anim = maxf(0.0, bite_anim - dt * 5.0)
	flap_anim = maxf(0.0, flap_anim - dt * 2.5)
	hurt_flash = maxf(0.0, hurt_flash - dt * 5.0)
	squash = maxf(0.0, squash - dt * 4.0)
	stun = maxf(0.0, stun - dt)
	fear = maxf(0.0, fear - dt)
	angry_t = maxf(0.0, angry_t - dt)
	cd_move = maxf(0.0, cd_move - dt)
	cd_special = maxf(0.0, cd_special - dt)
	since_hurt += dt
	if poison_t > 0.0:
		poison_t -= dt
		hp -= poison * dt
	if since_hurt > 2.5 and hp < max_hp:
		hp = minf(max_hp, hp + float(stats.get("regen", 0.4)) * 0.02 * max_hp * dt)

	var want := Vector2.ZERO if stun > 0.0 else desired * speed
	if dash_t > 0.0:
		dash_t -= dt
		want = dash_dir * speed * dash_mult
		vel = vel.lerp(want, minf(1.0, dt * 20.0))
	else:
		vel = vel.lerp(want, minf(1.0, dt * 7.0))
	position += vel * dt
	var spd := vel.length()
	move_amt = clampf(spd / maxf(1.0, speed), 0.0, 1.5)
	if spd > 8.0 and stun <= 0.0:
		facing = lerp_angle(facing, vel.angle(), minf(1.0, dt * 10.0))
	# stay in the pond
	var lim := Game.WORLD_R - r
	if position.length() > lim:
		position = position.normalized() * lim
		vel = vel.slide(position.normalized())


func start_dash(dir: Vector2, dur: float, mult: float) -> void:
	dash_dir = dir.normalized() if dir.length() > 0.1 else Vector2.from_angle(facing)
	dash_t = dur
	dash_mult = mult
	squash = 1.0


func is_dashing() -> bool:
	return dash_t > 0.0


func _draw() -> void:
	if is_player:
		draw_circle(Vector2.ZERO, r * 1.55, Color(1, 1, 1, 0.1), true, -1.0, true)
		draw_arc(Vector2.ZERO, r * 1.55, 0, TAU, 32, Color(1, 1, 1, 0.35), maxf(1.5, r * 0.06), true)
	elif is_boss:
		draw_arc(Vector2.ZERO, r * 1.3, 0, TAU, 48, Color(1, 0.85, 0.2, 0.35 + 0.2 * sin(anim_t * 4.0)), 5.0, true)
	# soft shadow
	draw_set_transform(Vector2(r * 0.12, r * 0.18), facing, Vector2(1.1, 0.9))
	draw_circle(Vector2.ZERO, r * 1.05, Color(0, 0, 0, 0.16), true, -1.0, true)
	var sq := squash * 0.18
	var wob := sin(anim_t * 10.0) * 0.03 * move_amt
	var sc := Vector2(1.0 + sq + wob, 1.0 - sq * 0.8 - wob)
	var col := color
	if hurt_flash > 0.0:
		col = col.lerp(Color(1, 0.25, 0.25), hurt_flash * 0.7)
	if poison_t > 0.0:
		col = col.lerp(Color(0.5, 0.9, 0.2), 0.35)
	draw_set_transform(Vector2.ZERO, facing, sc)
	CreatureArt.draw_creature(self, parts, r, col, anim_t, move_amt, bite_anim, flap_anim)
	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
	if stun > 0.0:
		for i in 3:
			var a := anim_t * 5.0 + TAU * i / 3.0
			var p := Vector2(cos(a) * r * 0.8, -r * 1.2 + sin(a) * r * 0.25)
			draw_circle(p, maxf(2.5, r * 0.12), Color(1, 0.95, 0.4), true, -1.0, true)
	if not is_player and not is_boss and hp < max_hp and hp > 0.0:
		var wbar := maxf(18.0, r * 1.6)
		var y := -r * 1.35 - 6.0
		draw_rect(Rect2(-wbar * 0.5, y, wbar, 4.0), Color(0, 0, 0, 0.45))
		draw_rect(Rect2(-wbar * 0.5, y, wbar * hp / max_hp, 4.0), Color(1.0, 0.4, 0.35))
