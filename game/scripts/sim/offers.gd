class_name Offers
extends RefCounted
## Builds evolution hands. Weights: rarity (shifting rarer with level), x(1 + 0.1 per
## affinity point you hold), duck parts (the hidden affinity) x(0.55 + 0.3 per duck part), rank-ups x1.3.
## source: "level" | "boss" (boss fruits only) | "poi" (any).

const RARITY_W := [60.0, 28.0, 10.0, 2.0]


static func weight(run: Run, id: String, min_rarity: int) -> float:
	var d := Evolutions.get_def(id)
	var r := int(d["rarity"])
	if r < min_rarity:
		return 0.0
	var w: float = RARITY_W[r] * (1.0 + run.level * 0.03 * r)
	var pts := run.affinity_points()
	w *= 1.0 + 0.1 * int(pts.get(d["aff"], 0))
	# duck is the hidden affinity: rarer, but it snowballs once you start
	if d.get("duck_part", false) or d["aff"] == "duck":
		w *= 0.55 + 0.3 * run.duck_parts()
	if run.has(id):
		w *= 1.3
	return w


static func eligible(run: Run, id: String, source: String) -> bool:
	var d := Evolutions.get_def(id)
	if d.get("starter", false) and not run.has(id):
		return false
	var t := String(d["type"])
	if (t == "fruit") != (source == "boss"):
		return false
	if run.rank(id) >= int(d.get("max", 1)):
		return false
	if d.has("needs_ducks") and run.duck_parts() < int(d["needs_ducks"]):
		return false
	# movement and ultimates are one-slot: rank ups only for the equipped one
	if t == "move" and run.has(id) and run.move != id:
		return false
	if t == "ultimate" and run.has(id) and run.ultimate != id:
		return false
	return true


static func roll(run: Run, rng: RandomNumberGenerator, source: String = "level", n: int = 3, min_rarity: int = 0) -> Array:
	var pool: Array = []
	var weights: Array = []
	for id in Evolutions.ALL:
		if not eligible(run, id, source):
			continue
		var w := weight(run, id, min_rarity)
		if source == "boss":
			w = 1.0
		if w > 0.0:
			pool.append(id)
			weights.append(w)
	if pool.is_empty() and min_rarity > 0:
		return roll(run, rng, source, n, min_rarity - 1)
	var out: Array = []
	var types := {}
	while out.size() < n and not pool.is_empty():
		var total := 0.0
		for w in weights:
			total += float(w)
		var x := rng.randf() * total
		var idx := pool.size() - 1
		for i in weights.size():
			x -= float(weights[i])
			if x <= 0.0:
				idx = i
				break
		var id: String = pool[idx]
		pool.remove_at(idx)
		weights.remove_at(idx)
		# at most two of one type per hand, so a hand isn't three attacks
		var t := String(Evolutions.get_def(id)["type"])
		if int(types.get(t, 0)) >= 2 and _other_type_left(pool, types):
			continue
		types[t] = int(types.get(t, 0)) + 1
		out.append(id)
	return out


static func _other_type_left(pool: Array, types: Dictionary) -> bool:
	for id in pool:
		if int(types.get(String(Evolutions.get_def(id)["type"]), 0)) < 2:
			return true
	return false


static func min_rarity_of(hand: Array) -> int:
	var m := 3
	for id in hand:
		m = mini(m, int(Evolutions.get_def(id)["rarity"]))
	return m
