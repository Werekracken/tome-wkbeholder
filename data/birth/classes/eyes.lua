
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
	inc_stats = { mag = 6, wil =3,},
	not_on_random_boss = true,
	power_source = {arcane=true},
	talents_types = {
		["spell/central-eye"] = {true, -0.3},
		["spell/fire-eye"] = {true, 0.3},
		["spell/frost-eye"] = {true, 0.3},
		["spell/lightning-eye"] = {true, 0.3},
		["spell/death-eye"] = {false, 0.3},
		["spell/tri-beam"] = {false, 0.3},
		["spell/aegis"]={true, 0.2},
		["spell/divination"]={true, 0},
		["technique/tentacle-combat"]={true, -.2},
	},
	copy_add = {
	life_rating = -4,
	mana_regen = 0.1,
	mana_rating = 2,},
	copy = {
		lite = 1,
		resolvers.equip{ id=true, {type="jewelry", subtype="ring",  autoreq=true, ego_chance=100}, },
		resolvers.equip{ id=true, {type="jewelry", subtype="ring",  autoreq=true, ego_chance=100}, },
		resolvers.inscription("RUNE:_MANASURGE", {cooldown=25, dur=10, mana=620}),
		resolvers.inscription("RUNE:_SHIELDING", {cooldown=14, dur=5, power=100}),
		--resolvers.inscription("INFUSION:_WILD", {cooldown=12, what={physical=true}, dur=4, power=14}),
		resolvers.inscription("RUNE:_PHASE_DOOR", {cooldown=7, range=10, dur=5, power=15}),
		starting_quest = "starter-zones",
		starting_intro = "beholder",
	},
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
	mana_rating = 2,},
	copy = {
		resolvers.equip{ id=true, {type="jewelry", subtype="ring",  autoreq=true, ego_chance=100}, },
		resolvers.equip{ id=true, {type="jewelry", subtype="ring",  autoreq=true, ego_chance=100}, },
		resolvers.inscription("RUNE:_MANASURGE", {cooldown=25, dur=10, mana=620}),
		resolvers.inscription("RUNE:_SHIELDING", {cooldown=14, dur=5, power=100}),
		resolvers.inscription("INFUSION:_WILD", {cooldown=12, what={physical=true}, dur=4, power=14}),
		starting_quest = "mage-eye-beholder-start",
		starting_intro = "beholder",
	},
	 talents = {
		T_MAGEEYE_DEVOUR = 1,
	 },
}
