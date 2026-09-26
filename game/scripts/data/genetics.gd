class_name Genetics
extends RefCounted
## Starting modifiers (Crab's Genetics): before every run you pick two, each from a
## hand of three unlocked ones. Each is unlocked by a goal.

const ALL := {
	"pioneer": {"name": "Pioneer", "desc": "+1 Speed.", "goal": "Unlocked from the start."},
	"forager": {"name": "Forager", "desc": "Bumping a tree or bush shakes loose 1 more fruit.", "goal": "Unlocked from the start."},
	"angler": {"name": "Angler", "desc": "Fish pools restock twice as fast and give 1 more fish.", "goal": "Unlocked from the start."},
	"omni_gut": {"name": "Omnivore Gut", "desc": "+10% Progress from all food.", "goal": "Unlocked from the start."},
	"purebred": {"name": "Purebred", "desc": "+10% Physical and Ability while you have no duck parts.", "goal": "Win a run with the NO DUCK verdict."},
	"grandiose": {"name": "Grandiose", "desc": "+25% Size and +15 HP, but -1 Speed.", "goal": "Reach level 15."},
	"chosen": {"name": "Chosen", "desc": "Start the run with a Rare evolution.", "goal": "Beat a boss."},
	"webfoot": {"name": "Webfoot", "desc": "Hatch with Webbed Feet.", "goal": "Own 3 duck parts at once."},
	"expert": {"name": "Expert", "desc": "One free reroll at every level up.", "goal": "Win a run."},
	"challenger": {"name": "Challenger", "desc": "+30% XP, but animals have +30% HP.", "goal": "Reach the final boss."},
	"duckling": {"name": "Duckling", "desc": "Hatch with a Duck Bill and Down Feathers.", "goal": "Total Anatification: all 8 duck parts."},
}

const ORDER := ["pioneer", "forager", "angler", "omni_gut", "grandiose", "chosen", "webfoot", "expert", "challenger", "duckling", "purebred"]
const STARTERS := ["pioneer", "forager", "angler", "omni_gut"]


## The verdict at the end of a run: a duck is 5+ duck parts, or Convergent Evolution.
static func is_duck(run: Run) -> bool:
	return run.duck_parts() >= 5 or run.has("convergent")


## A hand of up to 3 unlocked genetics, none of them already picked.
static func hand(rng: RandomNumberGenerator, picked: Array) -> Array:
	var pool: Array = []
	for id in ORDER:
		if id in Game.unlocked_genetics and not id in picked:
			pool.append(id)
	var out: Array = []
	while out.size() < 3 and not pool.is_empty():
		out.append(pool.pop_at(rng.randi() % pool.size()))
	return out

const PRESSURE := [
	"Selective Pressure 0: the pond as it is.",
	"1: Predators call their friends when they hunt you.",
	"2: Nights are longer and darker.",
	"3: Alphas show up twice as often.",
	"4: Bosses give you only 60 seconds.",
	"5: The Breadfall lasts 30% longer.",
]


## Checks a finished run against every goal. Returns the ids newly unlocked.
static func evaluate(run: Run) -> Array:
	var out: Array = []
	var checks := {
		"grandiose": run.level >= 15,
		"chosen": run.bosses_killed >= 1,
		"webfoot": run.best_duck_parts >= 3,
		"expert": run.won,
		"challenger": run.time >= Run.FINAL_TIME,
		"duckling": run.best_duck_parts >= 8,
		"purebred": run.won and not is_duck(run),
	}
	for id in checks:
		if checks[id] and Game.unlock(id):
			out.append(id)
	return out
