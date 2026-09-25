class_name Run
extends RefCounted
## One run's state, no nodes: owned evolutions and ranks, what's equipped, the player's
## stats and look, XP/level, Mutagen, the clock and its boss schedule (Crab's timer bar),
## and tallies for the end screen and the Genetics goals.

const LENGTH := 15.0 * 60.0
const BOSS_TIMES := [210.0, 450.0, 690.0]
const FINAL_TIME := 840.0
const DAY_LEN := 240.0  # one full day + night

const BASE := {
	"physical": 10.0, "ability": 10.0, "max_hp": 50.0, "speed": 5.0, "social": 5.0,
	"size": 100.0, "dmg": 100.0, "cdr": 0.0, "area": 100.0, "armor": 0.0, "regen": 0.5,
	"crit": 5.0, "evasion": 0.0, "magnet": 26.0, "luck": 0.0, "xp": 0.0, "food": 0.0,
	"thorns": 0.0, "poison": 0.0, "heal_kill": 0.0, "execute": 0.0, "stealth": 0.0, "revive": 0.0,
	"ally_cap": 0.0, "ally_dmg": 0.0, "ally_regen": 0.0, "herd": 0.0, "ram": 0.0, "echo": 0.0,
	"swim": 0.0, "temper": 0.0, "all": 0.0, "vision": 0.0, "identify": 0.0,
	"meat_xp": 0.0, "fish_xp": 0.0, "fruit_xp": 0.0, "fruit_heal": 0.0, "scav_xp": 0.0,
	"vegan": 0.0, "omni": 0.0, "pollen": 0.0, "feed": 100.0, "ruminant": 0.0, "shroom_xp": 0.0,
	"lifesteal": 0.0, "terrain_res": 0.0,
}
const BASE_LOOK := {
	"body": "slime", "ramp": "slime", "accent": "gold", "size": 8, "eyes": "cute", "mouth": "none",
	"crown": "none", "back": "none", "armor": "none", "tail": "none", "legs": "none", "arms": "none", "hide": "none",
}
## Puddle hatches as goo, firms into mochi, then metamorphoses into an affinity body.
const MOCHI_AT := 4
const METAMORPHOSIS_AT := 8
const AFFINITY_BODY := {
	"predator": ["beast", "red"], "prey": ["beast", "green"], "gregarious": ["chunk", "pink"],
	"imposing": ["chunk", "orange"], "trickster": ["bug", "purple"], "duck": ["duck", "duck"],
}
## Evolution look keys that name a slot differently in the rig.
const LOOK_KEY := {"head": "crown", "pattern": "hide"}

var owned: Dictionary = {}  # id -> rank
var order: Array = []  # acquisition order, for looks
var attacks: Array = ["headbutt"]  # up to 2
var ultimate := ""
var move := "scoot"
var stats: Dictionary = {}
var look: Dictionary = {}
var level := 1
var xp := 0.0
var mutagen := 0
var time := 0.0
var kills := 0
var bosses_killed := 0
var bosses_survived := 0
var boss_order: Array = []
var won := false
var revive_used := false
var genetic := "pioneer"
var pressure := 0
var reroll_cost := 1
var upgrade_cost := 10
var free_rerolls := 0
var best_duck_parts := 0
var eaten := {}
var food_eaten := {}  # food type -> pieces eaten this run
var unlocked := {}  # evolution ids opened by what you hold (the evolution tree)
var banned := {}  # evolution ids ruled out by what you hold
var branches: Array = []  # branching evolutions taken, in order
var buffs := {}  # temporary stat buffs: key -> {v, t}
var _bonus := {}  # permanent point-of-interest bonuses


func _init(gen: String = "pioneer", press: int = 0, rng: RandomNumberGenerator = null) -> void:
	genetic = gen
	pressure = press
	owned = {"headbutt": 1, "scoot": 1}
	order = ["headbutt", "scoot"]
	var pool := Species.BOSS_POOL.duplicate()
	if rng:
		for i in range(pool.size() - 1, 0, -1):
			var j := rng.randi_range(0, i)
			var tmp = pool[i]
			pool[i] = pool[j]
			pool[j] = tmp
	boss_order = pool.slice(0, 3)
	boss_order.append("great_mallard")
	match genetic:
		"webfoot":
			_grant("webbed_feet")
		"duckling":
			_grant("duck_bill")
			_grant("down_feathers")
	recompute()


func _grant(id: String) -> void:
	owned[id] = int(owned.get(id, 0)) + 1
	if not id in order:
		order.append(id)


func rank(id: String) -> int:
	return int(owned.get(id, 0))


func has(id: String) -> bool:
	return owned.has(id)


func duck_parts() -> int:
	var n := 0
	for id in Evolutions.DUCK_PARTS:
		if owned.has(id):
			n += 1
	return n


func affinity_points() -> Dictionary:
	var pts := {}
	for a in Evolutions.AFFINITIES:
		pts[a] = 0
	for id in owned:
		var d := Evolutions.get_def(id)
		if d.is_empty() or d.get("starter", false):
			continue
		pts[d["aff"]] = int(pts[d["aff"]]) + int(owned[id])
	for a in Evolutions.AFFINITIES:
		pts[a] = int(pts[a]) + int(_bonus.get("aff_" + a, 0.0))
	return pts


func minute() -> float:
	return time / 60.0


## 0 = noon, 0.5 = midnight. Night is the middle third of the cycle's second half.
func day_phase() -> float:
	return fmod(time + DAY_LEN * 0.1, DAY_LEN) / DAY_LEN


func darkness() -> float:
	var ph := day_phase()
	# day 0..0.55, dusk 0.55..0.65, night 0.65..0.92, dawn 0.92..1 (pressure 2: longer nights)
	var dusk := 0.45 if pressure >= 2 else 0.55
	if ph < dusk:
		return 0.0
	if ph < dusk + 0.1:
		return (ph - dusk) / 0.1
	if ph < 0.92:
		return 1.0
	return 1.0 - (ph - 0.92) / 0.08


func is_night() -> bool:
	return darkness() > 0.5


## Fewer, heavier level-ups than Crab: ~15 in a full run.
func xp_need() -> float:
	return 12.0 + level * 12.0 + level * level * 2.6


## Adds XP, returns how many level ups happened.
func add_xp(amount: float) -> int:
	xp += amount * (1.0 + float(stats.get("xp", 0.0)) / 100.0) * (1.3 if genetic == "challenger" else 1.0)
	var ups := 0
	while xp >= xp_need():
		xp -= xp_need()
		level += 1
		ups += 1
	return ups


## Take an evolution (new, or a rank up). Returns what it replaced ("" if nothing).
func take(id: String) -> String:
	var d := Evolutions.get_def(id)
	var replaced := ""
	match String(d.get("type", "passive")):
		"attack":
			if not id in attacks:
				if attacks.size() >= 2:
					replaced = weakest_attack()
					attacks.erase(replaced)
				attacks.append(id)
		"ultimate":
			if ultimate != id:
				replaced = ultimate
				ultimate = id
		"move":
			if move != id:
				replaced = move
				move = id
	if String(d.get("type", "")) == "branch" and not id in branches:
		branches.append(id)
	_grant(id)
	if d.has("grants") and ultimate == "":
		var g := String(d["grants"])
		ultimate = g
		_grant(g)
	best_duck_parts = maxi(best_duck_parts, duck_parts())
	recompute()
	return replaced


func weakest_attack() -> String:
	var w := ""
	var wr := 99
	for a in attacks:
		if rank(a) < wr:
			wr = rank(a)
			w = a
	return w


func would_replace(id: String) -> String:
	var d := Evolutions.get_def(id)
	match String(d.get("type", "")):
		"attack":
			if not id in attacks and attacks.size() >= 2:
				return weakest_attack()
		"ultimate":
			if ultimate != "" and ultimate != id:
				return ultimate
		"move":
			if move != id:
				return move
	return ""


## A permanent bonus from a point of interest.
func bonus(k: String, v: float) -> void:
	_bonus[k] = float(_bonus.get(k, 0.0)) + v
	recompute()


func buff(k: String, v: float, secs: float) -> void:
	buffs[k] = {"v": v, "t": secs}
	recompute()


func tick_buffs(dt: float) -> void:
	var changed := false
	for k in buffs.keys():
		buffs[k]["t"] = float(buffs[k]["t"]) - dt
		if float(buffs[k]["t"]) <= 0.0:
			buffs.erase(k)
			changed = true
	if changed:
		recompute()


func recompute() -> void:
	stats = BASE.duplicate()
	match genetic:
		"pioneer":
			stats["speed"] += 1.0
		"grandiose":
			stats["size"] += 25.0
			stats["max_hp"] += 15.0
			stats["speed"] -= 1.0
	for id in owned:
		var d := Evolutions.get_def(id)
		var st: Dictionary = d.get("stats", {})
		for k in st:
			stats[k] = float(stats.get(k, 0.0)) + float(st[k]) * int(owned[id])
	for k in _bonus:
		stats[k] = float(stats.get(k, 0.0)) + float(_bonus[k])
	for k in buffs:
		stats[k] = float(stats.get(k, 0.0)) + float(buffs[k]["v"])
	stats["max_hp"] += (level - 1) * 3.0
	stats["size"] += minf(50.0, (level - 1) * 2.0)
	var all := float(stats["all"])
	if all > 0.0:
		for k in ["physical", "ability", "max_hp", "speed", "social", "armor"]:
			stats[k] = float(stats[k]) * (1.0 + all / 100.0)
	stats["duck_taken"] = 4.0 * duck_parts()
	stats["cd_mult"] = 1.0 / (1.0 + float(stats["cdr"]) / 100.0)
	stats["ally_max"] = mini(12, 1 + int(float(stats["social"]) / 5.0) + int(stats["ally_cap"]))
	_tree()
	_look()


## The evolution tree: what your evolutions (at their levels) unlock and ban.
func _tree() -> void:
	unlocked.clear()
	banned.clear()
	for id in owned:
		var d := Evolutions.get_def(id)
		var u: Dictionary = d.get("unlocks", {})
		for lvl in u:
			if int(owned[id]) >= int(lvl):
				for x in u[lvl]:
					unlocked[String(x)] = id
		for b in Evolutions.bans_of(id):
			banned[String(b)] = id


func bodily_mutations() -> int:
	var n := 0
	for id in owned:
		var d := Evolutions.get_def(id)
		if not d.get("starter", false) and d.has("look"):
			n += int(owned[id])
	return n


func is_slime() -> bool:
	return look.get("body", "slime") in ["slime", "mochi"]


func dominant_affinity() -> String:
	var pts := affinity_points()
	var best := "prey"
	var bv := -1
	for a in Evolutions.AFFINITIES:
		if int(pts[a]) > bv:
			bv = int(pts[a])
			best = a
	return best


func _look() -> void:
	look = BASE_LOOK.duplicate()
	var forced := ""
	for id in order:
		var d := Evolutions.get_def(id)
		var lk: Dictionary = d.get("look", {})
		for k in lk:
			if k == "shape":
				forced = {"duck": "duck", "tall": "bird"}.get(String(lk[k]), "")
			else:
				look[LOOK_KEY.get(k, k)] = lk[k]
	look["size"] = clampi(roundi(8.0 * float(stats["size"]) / 100.0), 6, 18)
	var n := bodily_mutations()
	if forced != "":
		look["body"] = forced
		look["ramp"] = "duck" if forced == "duck" else String(AFFINITY_BODY[dominant_affinity()][1])
	elif n >= METAMORPHOSIS_AT:
		var body: Array = AFFINITY_BODY[dominant_affinity()]
		look["body"] = body[0]
		look["ramp"] = body[1]
		if look["legs"] == "none":
			look["legs"] = "stubby"
	elif n >= MOCHI_AT:
		look["body"] = "mochi"


## Walking speed in px/s.
func move_speed() -> float:
	return 30.0 + 5.0 * maxf(1.0, float(stats["speed"]))


func radius() -> float:
	return float(look["size"]) * 1.1


## Vision radius at night, in px.
func vision() -> float:
	return 70.0 + float(stats["vision"]) + radius() * 2.0
