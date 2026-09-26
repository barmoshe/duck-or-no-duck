class_name Anatomy
extends RefCounted
## The creature art facade. Every creature is hand-drawn flat pixel art in Everything is
## Crab's Darwin style: Puddle (a look with "darwin") is composed from parts by DarwinArt;
## animals and bosses (a look with "species") are DarwinAnimals sprites.
## frames(look) -> {"idle": [4 tex], "walk": [4 tex], "bite": [1 tex], "size": Vector2i, "foot": Vector2}


static func _species(look: Dictionary) -> String:
	var id := String(look.get("species", ""))
	return id if DarwinAnimals.ALL.has(id) else ""


static func is_darwin(look: Dictionary) -> bool:
	return bool(look.get("darwin", false))


static func frames(look: Dictionary) -> Dictionary:
	var id := _species(look)
	if id != "":
		return DarwinArt.species_frames(id)
	return DarwinArt.frames(look)


## One still pose for UI: {"tex", "size", "foot"}.
static func single(look: Dictionary) -> Dictionary:
	var fr := frames(look)
	return {"tex": fr["idle"][0], "size": fr["size"], "foot": fr["foot"]}


static func key_of(look: Dictionary) -> String:
	var id := _species(look)
	if id != "":
		return "s:" + id
	return "d" + JSON.stringify(DarwinArt.spec_of(look)).md5_text()


static func clear_cache() -> void:
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
