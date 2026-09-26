class_name Actor
extends Node2D
## Any creature in the world: the player, an animal, an ally or a boss. Holds its numbers
## and timers, moves itself, and animates a generated sprite (idle / walk / bite frames,
## flipped left-right, never rotated). World runs its brain and its fights.

const SHADER := "shader_type canvas_item;
uniform float flash = 0.0;
uniform vec4 flash_col : source_color = vec4(1.0);
uniform vec4 line_col : source_color = vec4(0.0);
uniform float fade = 1.0;
void fragment() {
	vec4 c = texture(TEXTURE, UV);
	float lum = dot(c.rgb, vec3(0.3, 0.59, 0.11));
	if (line_col.a > 0.0 && c.a > 0.5 && lum < 0.16) { c.rgb = line_col.rgb; }
	c.rgb = mix(c.rgb, flash_col.rgb, flash);
	c.a *= fade;
	COLOR = c;
}"

static var _shader: Shader

var species := "player"
var is_player := false
var is_ally := false
var is_boss := false
var alpha := false
var role := "prey"
var look: Dictionary = {}
var frames: Dictionary = {}
var r := 6.0
var hp := 50.0
var max_hp := 50.0
var dmg := 5.0
var armor := 0.0
var speed := 50.0
var xp_value := 3.0
var swim := false
var fly := false
var water_only := false
var wade := false

var vel := Vector2.ZERO
var desired := Vector2.ZERO
var face := 1.0
var anim_t := 0.0
var bite_t := 0.0
var flash := 0.0
var stun := 0.0
var slow := 0.0
var slow_t := 0.0
var poison := 0.0
var poison_t := 0.0
var bleed_t := 0.0
var since_hurt := 99.0
var hurt_by = null  # Actor (untyped: may be freed)
var dead := false
var dash_t := 0.0
var dash_v := Vector2.ZERO
var air := 0.0  # 0..1 arc height while leaping or gliding
var air_t := 0.0
var air_dur := 0.0
var under := false
var invuln := 0.0
var terrain := 1.0
var ice := false

# brain
var state := "wander"
var target = null  # Actor (untyped: may be freed)
var think_t := 0.0
var wander := Vector2.RIGHT
var home := Vector2.ZERO
var angry_t := 0.0
var attack_cd := 0.0
var asleep := false  # mimics
var biome := "meadow"
var life_t := -1.0  # summoned allies expire
var eat_t := 0.0
var goal: Dictionary = {}
var windup := 0.0

# boss
var phase := ""
var phase_t := 0.0
var boss_t := 0.0
var boss_cycle := 0
var boss_timer := 90.0

var sprite: Sprite2D
var shadow: Sprite2D
var mat: ShaderMaterial
var star: Sprite2D


func _init() -> void:
	sprite = Sprite2D.new()
	shadow = Sprite2D.new()
	shadow.texture = Props.tex("shadow")
	shadow.z_index = -1
	add_child(shadow)
	add_child(sprite)
	if _shader == null:
		_shader = Shader.new()
		_shader.code = SHADER
	mat = ShaderMaterial.new()
	mat.shader = _shader
	sprite.material = mat
	anim_t = randf() * 2.0
	wander = Vector2.from_angle(randf() * TAU)


func set_look(lk: Dictionary) -> void:
	look = lk.duplicate()
	frames = Anatomy.frames(look)
	var sz: Vector2i = frames["size"]
	var foot: Vector2 = frames["foot"]
	sprite.centered = false
	sprite.offset = -foot.round()
	sprite.texture = frames["idle"][0]
	var sw := maxf(8.0, float(look.get("size", 6)) * 2.6)
	shadow.scale = Vector2(sw / 16.0, maxf(0.6, sw / 30.0))
	shadow.position = Vector2(0, 0)
	if alpha:
		mat.set_shader_parameter("line_col", Pal.c("gold", 3))
		if star == null:
			star = Sprite2D.new()
			star.texture = Props.tex("star")
			add_child(star)
		star.position = Vector2(0, -float(look.get("size", 6)) * 2.2 - 6.0)
	if is_ally:
		mat.set_shader_parameter("line_col", Pal.c("green", 3))


func setup_animal(id: String, hp_mult: float, dmg_mult: float, is_alpha: bool) -> void:
	species = id
	var d := Species.get_def(id)
	role = String(d["role"])
	is_boss = bool(d.get("boss", false))
	alpha = is_alpha and not is_boss
	max_hp = float(d["hp"]) * hp_mult * (2.2 if alpha else 1.0)
	hp = max_hp
	dmg = float(d["dmg"]) * dmg_mult * (1.3 if alpha else 1.0)
	armor = float(d.get("armor", 0.0)) + (2.0 if alpha else 0.0)
	speed = float(d["speed"]) * (1.1 if alpha else 1.0)
	xp_value = float(d["xp"]) * (3.0 if alpha else 1.0)
	swim = bool(d.get("swim", false))
	fly = bool(d.get("fly", false))
	water_only = bool(d.get("water_only", false))
	wade = bool(d.get("wade", false))
	var lk := Species.look_of(id)
	if alpha:
		lk["size"] = roundi(float(lk["size"]) * 1.5)
	# duck parts spread: once an animal has webbed feet it swims
	if String(lk.get("legs", "")) == "webbed":
		swim = true
	set_look(lk)
	r = float(lk.get("size", 6)) * 1.05
	if role == "mimic":
		asleep = true


func hit_flash(col: Color = Color.WHITE) -> void:
	flash = 1.0
	mat.set_shader_parameter("flash_col", col)


func tick(dt: float) -> void:
	anim_t += dt
	morph_t = maxf(0.0, morph_t - dt)
	bite_t = maxf(0.0, bite_t - dt)
	stun = maxf(0.0, stun - dt)
	slow_t = maxf(0.0, slow_t - dt)
	angry_t = maxf(0.0, angry_t - dt)
	attack_cd = maxf(0.0, attack_cd - dt)
	invuln = maxf(0.0, invuln - dt)
	since_hurt += dt
	if flash > 0.0:
		flash = maxf(0.0, flash - dt * 6.0)
		mat.set_shader_parameter("flash", flash)
	if poison_t > 0.0:
		poison_t -= dt
		hp -= poison * dt
	if bleed_t > 0.0:
		bleed_t -= dt
		hp -= max_hp * 0.02 * dt
	if life_t > 0.0:
		life_t -= dt
		if life_t <= 0.0:
			hp = 0.0
	var sp := speed * terrain * (1.0 - slow if slow_t > 0.0 else 1.0)
	var want := Vector2.ZERO if (stun > 0.0 or asleep) else desired * sp
	if dash_t > 0.0:
		dash_t -= dt
		vel = dash_v
	else:
		var accel := 2.5 if ice else 10.0
		vel = vel.lerp(want, minf(1.0, dt * accel))
	position += vel * dt
	if air_dur > 0.0:
		air_t += dt
		air = sin(clampf(air_t / air_dur, 0.0, 1.0) * PI)
		if air_t >= air_dur:
			air_dur = 0.0
			air = 0.0
	_animate()


## Evolving: show a few in-between bodies (old genome -> new) before the new one.
var morph_frames: Array = []
var morph_t := 0.0
const MORPH_TIME := 0.6


func play_morph(old_g: Dictionary, new_g: Dictionary) -> void:
	morph_frames.clear()
	for t in [0.25, 0.5, 0.75]:
		var fr := Sculptor.single(Genome.lerp_g(old_g, new_g, t))
		morph_frames.append([fr["tex"], fr["size"], fr["foot"]])
	morph_t = MORPH_TIME


func _animate() -> void:
	if frames.is_empty():
		return
	if morph_t > 0.0 and not morph_frames.is_empty():
		var k := clampi(int((1.0 - morph_t / MORPH_TIME) * morph_frames.size()), 0, morph_frames.size() - 1)
		var mf: Array = morph_frames[k]
		sprite.texture = mf[0]
		var msz: Vector2i = mf[1]
		var mfoot: Vector2 = mf[2]
		sprite.flip_h = face < 0.0
		sprite.offset = Vector2(-(msz.x - mfoot.x) if sprite.flip_h else -mfoot.x, -mfoot.y).round()
		return
	if absf(vel.x) > 4.0 and stun <= 0.0:
		face = signf(vel.x)
	elif target and is_instance_valid(target) and state == "chase":
		face = signf(target.position.x - position.x) if absf(target.position.x - position.x) > 2.0 else face
	sprite.flip_h = face < 0.0
	var tex: Texture2D
	if bite_t > 0.0:
		tex = frames["bite"][0]
	elif vel.length() > 6.0 and stun <= 0.0:
		var walk: Array = frames["walk"]
		tex = walk[int(anim_t * (6.0 + vel.length() * 0.06)) % walk.size()]
	else:
		var idle: Array = frames["idle"]
		tex = idle[int(anim_t * 2.0) % idle.size()]
	sprite.texture = tex
	# the sprite's pivot is the feet; mirror the offset when flipped
	var foot: Vector2 = frames["foot"]
	var sz: Vector2i = frames["size"]
	sprite.offset = Vector2(-(sz.x - foot.x) if sprite.flip_h else -foot.x, -foot.y).round()
	sprite.position = Vector2(0, -round(air * 22.0))
	var fade := 1.0
	if under:
		fade = 0.25
	elif asleep:
		fade = 1.0
	mat.set_shader_parameter("fade", fade)
	shadow.visible = not under


func start_dash(v: Vector2, t: float) -> void:
	dash_v = v
	dash_t = t


func start_air(t: float) -> void:
	air_dur = t
	air_t = 0.0


func is_airborne() -> bool:
	return air_dur > 0.0


func untouchable() -> bool:
	return invuln > 0.0 or under or (is_airborne() and air > 0.3)
