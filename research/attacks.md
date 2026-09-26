# Attacks: shapes, reach, speed and one signature each (v7.3)

Goal: every attack plays differently, and you can see what it reaches. Attacks fire when
you press them; the aim is automatic (see STATUS).

## What Crab does (research/crab-ref/evolutions.md)

Crab's 15 attacks differ in shape and feel, not only numbers: Beak is a long narrow peck,
Claws are fast swipes (0.3-0.5 s), Horns a dashing headbutt, Trunk a slow wide swipe with
extra reach, Jaws do double damage to stunned targets, Pincer pinches twice, Stinger is a
slow hit with 5 s of poison, Spit is short-ranged (10-20 u), Stoner is thrown ammo, Toe
Beans can charm. Cooldowns run 0.8 s (Jaws, Pincer) to 3 s (Stinger).

## Ours

Range in u (10 px), windup = seconds from the press to the hit ("speed" on the card).

| Attack | Role | Shape | Range | Windup | Cooldown | Signature |
|---|---|---|---|---|---|---|
| Gulp | starter | bite (1 target) | 2.0 | instant | 0.75 | small lunge; a kill heals |
| Headbutt | bonk | narrow line | 1.8 | 0.12 | 1.0 | knockback + 0.4 s stun (dizzy stars) |
| Jaws | heavy bite | 70° swipe | 1.8 | 0.08 | 0.85 | double damage to stunned ("CRUNCH") |
| Tail Whip | crowd push | all around | 3.0 | 0.1 | 1.6 | knocks back everything around you |
| Spit | ranged poke | shot 170 px/s | 12 | instant | 0.9 | splashes what's next to the target (50%) |
| Charge | gap closer | lunge | 7.0 | 0.15 | 2.2 | invulnerable while charging; hits all in the path |
| Stinger | poison sniper | shot 240 px/s | 14 | instant | 2.0 | 5 s of poison |
| Peck Flurry | rapid | long narrow line | 2.6 | instant | 1.2 | 3 pecks, each +10% crit |
| Egg Toss | artillery | lob, 2.8 u blast | 11 | 0.5 flight | 2.6 | the landing spot shows before it lands |
| Mud Splash | zone | all around | 3.6 | 0.05 | 2.6 | leaves a mud pool that slows for 2.5 s |
| Pincer Snap | bleed | 50° swipe | 2.0 | 0.1 | 1.3 | snips twice; bleed |
| Charm Song | convert | 1 target | 8.0 | 0.3 | 4.5 | a weakened animal joins you |
| Quack | stun | 70° cone | 6.4 | 0.1 | 2.6 | stuns the cone |
| Tentacle Lash | pull | line | 4.0 | 0.08 | 1.2 | two lashes; slow and pull to you |
| Kick | bowling | 100° swipe | 1.6 | 0.06 | 1.0 | the target flies into others (50% to them) |
| Constrict | hold | 1 target | 1.8 | 0.1 | 1.6 | holds it 1.2 s, squeezes 4 times, bleed |
| Feather Darts | spread | 3 shots 230 px/s | 13 | instant | 1.5 | each feather goes through one animal |

Shots now stop at their range (they used to fly 1.2 s whatever the attack).

## Seeing it

- Hold an attack's button (or a moment after a tap): its reach is drawn around you in its
  shape and color (dotted circle, wedge, strip, shot line with an end tick, lob line with the
  blast circle), and the animal it would hit gets blinking corner brackets.
- A windup of more than 0.05 s shows a gathering arc in front of you first (the tell).
- Each attack has its own animation (Fx._anim): jaws snapping (Gulp), an impact star and
  dizzy stars (Headbutt), rows of teeth (Jaws), a sweeping band (Tail Whip), a glob splat
  (Spit), speed lines (Charge), rising poison bubbles for the whole poison (Stinger), three
  beak jabs and sparks (Peck Flurry), a yolk burst (Egg Toss), a mud pool (Mud Splash), claws
  closing (Pincer Snap), music notes and hearts (Charm Song), sound waves (Quack), a wavy
  tentacle with a sucker (Tentacle Lash), a low swoosh (Kick), tightening coils (Constrict).
- Review them all: `tools/shot.sh`-style `--scene=attack --attack=<id>` freezes one attack's
  animation a third of the way in, with its range marker up.
