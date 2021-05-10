long_name = "Werekracken's Beholder Fork"
short_name = "wkbeholder"
for_module = "tome"
version = { 1, 7, 2 }
addon_version = {1,0,4}
weight = 100
author = {"Werekracken"}
tags = {"Beholder", "Class", "Race", "Monster", "Eyes", "Lasers", "Tentacles"}
homepage = "https://te4.org/user/102798/addons"
description = [[This addon is a fork of the Beholder (Eye Fix) (https://te4.org/games/addons/tome/beholder-efix), which was a fork of Beholder (Continuation) (https://te4.org/games/addons/tome/beholder-cont), which was a fork of Beholder race/classes (https://te4.org/games/addons/tome/beholder-raceclasses). It's been over a year since Beholder (Eye Fix) was updated last and it's been broken for a while, so here is the third fork.

Adds Beholders as a playable race and the Mage Eye as a Beholder only class and the only class they have access to.

https://github.com/Werekracken/tome-wkbeholder

---
Beholder race

Beholders resemble floating orbs of flesh with large mouths, a single central eye, and lots of smaller eyestalks on top with deadly magical powers. Instead of gaining category points as they level, they must absorb energy to grow. They have access to special eye beam abilities, but cannot wear most equipment.

-2 Strength, +2 Dexterity, +0 Constitution, +3 Magic, +4 Willpower, +2 Cunning
+10% Lightning, Fire, and Cold resist
-20% movement speed

Race tree

- race/beholder: Basic abilities common to all Beholders.

---
Mage Eye class

Mage eyes focus on harnessing the powers of their eyestalks. This caste of beholder can absorb power from arcane objects.

+6 Magic, +3 Willpower

Generic trees

- spell/aegis
- spell/divination
- technique/tentacle-combat: Strike nearby foes with your tentacles

Class trees

- spell/fire-eye: Flame eye abilities
- spell/frost-eye: Frost eye abilities
- spell/lightning-eye: Lightning eye abilities
- spell/central-eye: Central eye anti-magic abilities
- spell/tri-beam (locked): Refocus your central eye's energies. You must reach the 3rd beholder growth stage to be able to learn this talent tree.
- spell/death-eye (locked): Death eye abilities. You must reach the 5th beholder growth stage to be able to learn this talent tree.

---
Changelog
- v1.0.0 Took out some logic around redefining some AI rules for talent usage because it was breaking this from loading and breaking other add ons as well. Made Temporal Gaze thralls so that you can't switch and control them because that was causing errors too.
- v1.0.1 Fixed an issue that caused bump attacks to error in conjunction with other addons.
- v1.0.2 Fix Channel Mastery to correctly randomly use known masteries. Add sounds for Frost Laser and Lightning Laser.
- v1.0.3 Make Beholder playable in Embers of Rage.
- v1.0.4 Make all classes (except wilders) available to the Beholder race. Make beholders levitate by default instead of at stage 5 growth. Changed them from starting with 10 infravision to getting +2 infravision for each growth stage.
]]
overload = true
superload = true
hooks = true
data = true