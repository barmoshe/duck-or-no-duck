class_name Anatomy
extends RefCounted
## The creature art facade. Every creature is a Genome drawn by the Sculptor ("living
## clay"): the player's look carries its genome in look["gen"] (built by Run from its
## evolutions); animals' looks are turned into genomes here.
## frames(look) -> {"idle": [4 tex], "walk": [6 tex], "bite": [1 tex], "size": Vector2i, "foot": Vector2}


static func genome(look: Dictionary) -> Dictionary:
	if look.has("gen"):
		return look["gen"]
	if look.has("species"):
		return Genome.of_species(String(look["species"]))
	return Genome.from_look(look)


static func frames(look: Dictionary) -> Dictionary:
	return Sculptor.frames(genome(look))


static func key_of(look: Dictionary) -> String:
	return Genome.key(genome(look))


static func clear_cache() -> void:
	Sculptor.clear_cache()


## One frame as an Image. anim: idle | move | attack.
static func render(look: Dictionary, anim: String = "idle", frame: int = 0, _spec: Dictionary = {}, _blink: bool = false) -> Image:
	var fr := frames(look)
	var arr: Array = fr["idle"]
	if anim == "move":
		arr = fr["walk"]
	elif anim == "attack":
		arr = fr["bite"]
	return (arr[frame % arr.size()] as Texture2D).get_image()
