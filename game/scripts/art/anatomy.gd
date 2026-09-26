class_name Anatomy
extends RefCounted
## The creature art facade. Puddle (a look with "darwin") is hand-drawn flat pixel art
## composed from parts (DarwinArt, Everything-is-Crab's Darwin style); animals are Genomes
## drawn by the Sculptor ("living clay"), turned into genomes here.
## frames(look) -> {"idle": [4 tex], "walk": [6 tex], "bite": [1 tex], "size": Vector2i, "foot": Vector2}


static func genome(look: Dictionary) -> Dictionary:
	if look.has("gen"):
		return look["gen"]
	if look.has("species"):
		return Genome.of_species(String(look["species"]))
	return Genome.from_look(look)


static func is_darwin(look: Dictionary) -> bool:
	return bool(look.get("darwin", false))


static func frames(look: Dictionary) -> Dictionary:
	if is_darwin(look):
		return DarwinArt.frames(look)
	return Sculptor.frames(genome(look))


## One still pose for UI: {"tex", "size", "foot"}.
static func single(look: Dictionary) -> Dictionary:
	if is_darwin(look):
		var fr := DarwinArt.frames(look)
		return {"tex": fr["idle"][0], "size": fr["size"], "foot": fr["foot"]}
	return Sculptor.single(genome(look))


static func key_of(look: Dictionary) -> String:
	if is_darwin(look):
		return "d" + JSON.stringify(DarwinArt.spec_of(look)).md5_text()
	return Genome.key(genome(look))


static func clear_cache() -> void:
	Sculptor.clear_cache()
	DarwinArt.clear_cache()


## One frame as an Image. anim: idle | move | attack.
static func render(look: Dictionary, anim: String = "idle", frame: int = 0, _spec: Dictionary = {}, _blink: bool = false) -> Image:
	var fr := frames(look)
	var arr: Array = fr["idle"]
	if anim == "move":
		arr = fr["walk"]
	elif anim == "attack":
		arr = fr["bite"]
	return (arr[frame % arr.size()] as Texture2D).get_image()
