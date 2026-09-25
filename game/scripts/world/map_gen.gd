class_name MapGen
extends RefCounted
## Generates one run's map: a 160x160 grid of 16 px cells in 4 biomes (Voronoi with a
## domain warp), lakes and a river, a forest border, and the spots for obstacles, decor,
## points of interest and the start. Pure data; World turns it into nodes.

const N := 160
const CELL := 16.0
const SIZE := N * CELL
const WALL := 4  # biome id of the impassable border forest

var biome := PackedByteArray()  # 0 grass, 1 lake, 2 sand, 3 snow, 4 wall
var water := PackedByteArray()  # 0 land, 1 shallow, 2 deep
var obstacles: Array = []  # {p, r, kind}
var decor: Array = []  # {p, kind}
var pois: Array = []  # {p, kind}
var burrows: Array = []  # Vector2
var start := Vector2.ZERO
var seeds: Array = []  # biome centers (px)
var rng := RandomNumberGenerator.new()


func generate(seed_value: int) -> void:
	rng.seed = seed_value
	biome.resize(N * N)
	water.resize(N * N)
	var warp := FastNoiseLite.new()
	warp.seed = seed_value
	warp.frequency = 0.035
	var lake := FastNoiseLite.new()
	lake.seed = seed_value + 11
	lake.frequency = 0.05
	lake.fractal_octaves = 3
	# four biome centers around the middle, in a shuffled order
	var order := [0, 1, 2, 3]
	for i in range(3, 0, -1):
		var j := rng.randi_range(0, i)
		var t: int = order[i]
		order[i] = order[j]
		order[j] = t
	var a0 := rng.randf() * TAU
	seeds.resize(4)
	for k in 4:
		var ang := a0 + TAU * k / 4.0 + rng.randf_range(-0.3, 0.3)
		seeds[order[k]] = Vector2(N * 0.5, N * 0.5) + Vector2.from_angle(ang) * N * rng.randf_range(0.26, 0.32)
	for y in N:
		for x in N:
			var i := y * N + x
			if x < 4 or y < 4 or x >= N - 4 or y >= N - 4 or _edge_wobble(x, y, warp):
				biome[i] = WALL
				water[i] = 0
				continue
			var p := Vector2(x, y) + Vector2(warp.get_noise_2d(x, y), warp.get_noise_2d(x + 300, y + 300)) * 14.0
			var best := 0
			var bd := INF
			for b in 4:
				var d := p.distance_squared_to(seeds[b])
				if d < bd:
					bd = d
					best = b
			biome[i] = best
			var thr: float = [0.42, -0.32, 0.4, 0.34][best]
			water[i] = 1 if lake.get_noise_2d(x, y) > thr else 0
	_river(warp)
	_deepen()
	_clear_around(seeds[0] as Vector2, 5)
	start = (seeds[0] as Vector2) * CELL + Vector2(CELL, CELL) * 0.5
	_place_things()


func _edge_wobble(x: int, y: int, warp: FastNoiseLite) -> bool:
	var d := mini(mini(x, y), mini(N - 1 - x, N - 1 - y))
	return d < 7 + int((warp.get_noise_2d(x * 2.0, y * 2.0) + 1.0) * 3.0)


func _river(warp: FastNoiseLite) -> void:
	# from the marsh center outward in two directions, meandering
	var c: Vector2 = seeds[1]
	for dir_sign: float in [-1.0, 1.0]:
		var p := c
		var heading := Vector2.from_angle(rng.randf() * TAU) * dir_sign
		for step in 140:
			heading = heading.rotated(warp.get_noise_2d(p.x * 3.0, p.y * 3.0) * 0.35)
			p += heading
			var r := 1.6 + (warp.get_noise_2d(step * 5.0, 0) + 1.0)
			for yy in range(int(p.y - r), int(p.y + r) + 1):
				for xx in range(int(p.x - r), int(p.x + r) + 1):
					if xx < 0 or yy < 0 or xx >= N or yy >= N:
						continue
					if Vector2(xx, yy).distance_to(p) <= r and biome[yy * N + xx] != WALL:
						water[yy * N + xx] = 1
			if p.x < 6 or p.y < 6 or p.x > N - 6 or p.y > N - 6:
				break


func _deepen() -> void:
	var src := water.duplicate()
	for y in range(2, N - 2):
		for x in range(2, N - 2):
			var i := y * N + x
			if src[i] == 0:
				continue
			var deep := true
			for o in [Vector2i(2, 0), Vector2i(-2, 0), Vector2i(0, 2), Vector2i(0, -2), Vector2i(1, 1), Vector2i(-1, -1)]:
				if src[(y + o.y) * N + x + o.x] == 0:
					deep = false
					break
			if deep:
				water[i] = 2


func _clear_around(c: Vector2, r: int) -> void:
	for y in range(int(c.y) - r, int(c.y) + r + 1):
		for x in range(int(c.x) - r, int(c.x) + r + 1):
			if x >= 0 and y >= 0 and x < N and y < N:
				water[y * N + x] = 0


func _place_things() -> void:
	obstacles.clear()
	decor.clear()
	pois.clear()
	var tries := 0
	while obstacles.size() < 150 and tries < 4000:
		tries += 1
		var cx := rng.randi_range(8, N - 9)
		var cy := rng.randi_range(8, N - 9)
		var i := cy * N + cx
		if biome[i] == WALL or water[i] != 0:
			continue
		var p := Vector2(cx, cy) * CELL + Vector2(rng.randf_range(2, 14), rng.randf_range(2, 14))
		if p.distance_to(start) < 90.0:
			continue
		var kind: String = ["tree", "tree", "rock", "pine"][biome[i]]
		if rng.randf() < 0.3:
			kind = ["bush", "bush", "cactus", "ice_rock"][biome[i]]
		elif biome[i] == 2 and rng.randf() < 0.3:
			kind = "cactus"
		var r: float = {"tree": 7.0, "rock": 8.0, "pine": 7.0, "bush": 5.0, "cactus": 5.0, "ice_rock": 7.0}[kind]
		var ok := true
		for o in obstacles:
			if (o["p"] as Vector2).distance_to(p) < 34.0:
				ok = false
				break
		if ok:
			obstacles.append({"p": p, "r": r, "kind": kind})
	for k in 900:
		var cx2 := rng.randi_range(6, N - 7)
		var cy2 := rng.randi_range(6, N - 7)
		var i2 := cy2 * N + cx2
		if biome[i2] == WALL:
			continue
		var p2 := Vector2(cx2, cy2) * CELL + Vector2(rng.randf_range(0, 16), rng.randf_range(0, 16))
		var kinds: Array
		if water[i2] != 0:
			kinds = ["lily", "lily", "ripple"] if biome[i2] != 3 else ["ice_crack"]
		else:
			kinds = [["flowers", "grass", "grass", "flowers", "tall_grass"], ["reeds", "grass", "cattail", "tall_grass"], ["shell", "pebbles", "grass_dry", "bones"], ["snow_tuft", "pebbles", "icicle", "snow_tuft"]][biome[i2]]
		decor.append({"p": p2, "kind": kinds[rng.randi() % kinds.size()]})
	# points of interest: four per terrain, spread out, each kind fitting its terrain
	var used_kinds := {}
	for k in 16:
		var b := k % 4
		var kinds_poi: Array = Pois.kinds_for(Species.BIOMES[b])
		kinds_poi.shuffle()
		var kind_p: String = kinds_poi[0]
		for kp in kinds_poi:
			if not used_kinds.has(kp):
				kind_p = kp
				break
		for attempt in 300:
			var cx3 := rng.randi_range(10, N - 11)
			var cy3 := rng.randi_range(10, N - 11)
			var i3 := cy3 * N + cx3
			if biome[i3] != b or water[i3] != 0:
				continue
			var p3 := Vector2(cx3, cy3) * CELL + Vector2(8, 8)
			var ok3 := p3.distance_to(start) > 200.0
			for o in pois:
				if (o["p"] as Vector2).distance_to(p3) < 260.0:
					ok3 = false
			for o in obstacles:
				if (o["p"] as Vector2).distance_to(p3) < 26.0:
					ok3 = false
			if ok3:
				pois.append({"p": p3, "kind": kind_p})
				used_kinds[kind_p] = int(used_kinds.get(kind_p, 0)) + 1
				break
	# burrows: holes to hide in
	burrows.clear()
	for attempt2 in 2000:
		if burrows.size() >= 30:
			break
		var cx4 := rng.randi_range(9, N - 10)
		var cy4 := rng.randi_range(9, N - 10)
		var i4 := cy4 * N + cx4
		if biome[i4] == WALL or water[i4] != 0 or biome[i4] == 1:
			continue
		var p4 := Vector2(cx4, cy4) * CELL + Vector2(8, 8)
		var ok4 := true
		for bp in burrows:
			if (bp as Vector2).distance_to(p4) < 180.0:
				ok4 = false
		for o in obstacles:
			if (o["p"] as Vector2).distance_to(p4) < 22.0:
				ok4 = false
		if ok4:
			burrows.append(p4)


func cell_at(p: Vector2) -> int:
	var x := clampi(int(p.x / CELL), 0, N - 1)
	var y := clampi(int(p.y / CELL), 0, N - 1)
	return y * N + x


func biome_at(p: Vector2) -> int:
	return biome[cell_at(p)]


func water_at(p: Vector2) -> int:
	return water[cell_at(p)]


func biome_name_at(p: Vector2) -> String:
	var b := biome_at(p)
	return "wall" if b == WALL else String(Species.BIOMES[b])


func is_wall(p: Vector2) -> bool:
	return biome[cell_at(p)] == WALL


## A random land (or any) point in a biome, near a center, for spawning.
func random_point(rng2: RandomNumberGenerator, near: Vector2, rmin: float, rmax: float, allow_water: bool) -> Vector2:
	for k in 12:
		var p := near + Vector2.from_angle(rng2.randf() * TAU) * rng2.randf_range(rmin, rmax)
		if p.x < 80 or p.y < 80 or p.x > SIZE - 80 or p.y > SIZE - 80:
			continue
		if is_wall(p):
			continue
		if not allow_water and water_at(p) != 0:
			continue
		return p
	return Vector2(-1, -1)


func map_image() -> Image:
	var img := Image.create_empty(N, N, false, Image.FORMAT_RGBA8)
	for y in N:
		for x in N:
			var i := y * N + x
			img.set_pixel(x, y, Color8(biome[i] * 50, water[i] * 100, (x * 7 + y * 13) % 255, 255))
	return img
