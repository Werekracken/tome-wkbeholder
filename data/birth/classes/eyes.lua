
newBirthDescriptor{
	type = "class",
	name = "Eyes",
	desc = {
		"Beholders follow a caste system.",
	},
	descriptor_choices =
	{
		subclass =
		{
			__ALL__ = "disallow",
			["Mage Eye"] = "allow",
			-- ["Gauth"] = "allow",
		},
	},
}

newBirthDescriptor{
	type = "subclass",
	name = "Mage Eye",
	desc = {
		"Mage eyes focus on harnessing the powers of their eyestalks.",
		"This caste of beholder can absorb power from arcane objects.",
		"#GOLD#Stat modifiers:",
		"#LIGHT_BLUE# * +0 Strength, +0 Dexterity, +0 Constitution",
		"#LIGHT_BLUE# * +6 Magic, +3 Willpower, +0 Cunning",
		"#GOLD#Life per level:#LIGHT_BLUE# -4",
	},
	inc_stats = { mag=6, wil=3,},
	not_on_random_boss = true,
	power_source = {arcane=true},
	talents_types = {
		["spell/central-eye"] = {true, 0.3},
		["spell/fire-eye"] = {true, 0.3},
		["spell/frost-eye"] = {true, 0.3},
		["spell/lightning-eye"] = {true, 0.3},
		["spell/death-eye"] = {false, 0.3},
		["spell/tri-beam"] = {false, 0.3},
		["spell/aegis"]={true, 0.3},
		["spell/divination"]={true, 0.3},
		["technique/tentacle-combat"]={true, 0.3},
	},
	copy_add = {
		life_rating = -4,
		mana_regen = 0.1,
		mana_rating = 2,
	},
	talents = {
		T_FLAME_LASER = 1,
		T_FROST_LASER = 1,
		T_LIGHTNING_LASER = 1,
		T_ARMOUR_TRAINING = 2,
	},
	resolvers.inscription("RUNE:_MANASURGE", {cooldown=25, dur=10, mana=620}),
}

--Gauth, Gouger, Armored
newBirthDescriptor{
	type = "subclass",
	name = "Gauth",
	desc = {
		"Gauth focus on harnessing the powers of their central eye.",
		"This caste of beholder can absorb power from psionic objects.",
		"#GOLD#Stat modifiers:",
		"#LIGHT_BLUE# * +4 Strength, +0 Dexterity, +0 Constitution",
		"#LIGHT_BLUE# * +2 Magic, +3 Willpower, +0 Cunning",
		"#GOLD#Life per level:#LIGHT_BLUE# +1",
	},
	inc_stats = { mag = 2, wil =3,str=4},
	not_on_random_boss = true,
	power_source = {arcane=true},
	talents_types = {
		["spell/central-eye"] = {true, .3},
		["spell/fire-eye"] = {true, -.3},
		["spell/frost-eye"] = {true, -.3},
		["spell/lightning-eye"] = {true, -.3},
		["spell/aegis"]={true, 0},
		["spell/divination"]={true, 0},
		["technique/tentacle-combat"]={true, .2},
		["technique/combat-techniques-active"] = {true,0},
		-- ["technique/ravenous-maw"] = {true,.3},
		["psionic/absorption"] = {true,.3},
		["psionic/psi-fighting"] = {true,.1},
		["psionic/augmented-mobility"] = {true,0},

	},
	copy_add = {
		life_rating = 1,
		mana_regen = 0.1,
		mana_rating = 2,
	},
	talents = {
		T_FLAME_LASER = 1,
		T_FROST_LASER = 1,
		T_LIGHTNING_LASER = 1,
		T_ARMOUR_TRAINING = 2,
	},
}
