class_name Genetics
extends RefCounted
## Starting modifiers (Crab's Genetics): pick one per run. Each is unlocked by a goal.

const ALL := {
	"pioneer": {"name": "Pioneer", "desc": "+1 Speed.", "goal": "Unlocked from the start."},
	"grandiose": {"name": "Grandiose", "desc": "+25% Size and +15 HP, but -1 Speed.", "goal": "Reach level 15."},
	"chosen": {"name": "Chosen", "desc": "Start the run with a Rare evolution.", "goal": "Beat a boss."},
	"webfoot": {"name": "Webfoot", "desc": "Hatch with Webbed Feet.", "goal": "Own 3 duck parts at once."},
	"expert": {"name": "Expert", "desc": "One free reroll at every level up.", "goal": "Win a run."},
	"challenger": {"name": "Challenger", "desc": "+30% XP, but animals have +30% HP.", "goal": "Reach the final boss."},
	"duckling": {"name": "Duckling", "desc": "Hatch with a Duck Bill and Down Feathers.", "goal": "Total Anatification: all 8 duck parts."},
}

const ORDER := ["pioneer", "grandiose", "chosen", "webfoot", "expert", "challenger", "duckling"]

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
	}
	for id in checks:
		if checks[id] and Game.unlock(id):
			out.append(id)
	return out
