local DamageType = require "engine.DamageType"
local ActorInventory = require "engine.interface.ActorInventory"
newBirthDescriptor{
	type = "race",
	name = "Beholder",
	desc = {
		"Beholders resemble floating orbs of flesh with large mouths, a single central eye, and lots of smaller eyestalks on top with deadly magical powers.",
	},
	descriptor_choices =
	{
		subrace =
		{
			__ALL__ = "disallow",
			Beholder = "allow",
		},
		class =
		{
			Wilder = "disallow",
			Eyes = "allow",
		},
		subclass =
		{
			["Mage Eye"] = "allow",
		},
	},
}

newBirthDescriptor{
	type = "subrace",
	name = "Beholder",
	desc = {
		"Beholders resemble floating orbs of flesh with large mouths, a single central eye, and lots of smaller eyestalks on top with deadly magical powers.",
		"Instead of gaining category points as they level, they must absorb energy to grow.",
		"They have access to special eye abilities, but cannot wear most equipment.",
		"#GOLD#Stat modifiers:",
		"#LIGHT_BLUE# * -2 Strength, +2 Dexterity, +0 Constitution",
		"#LIGHT_BLUE# * +3 Magic, +4 Willpower, +2 Cunning",
		"#LIGHT_BLUE# * +10% Lightning, Fire, and Cold resist",
		"#LIGHT_BLUE# * -20% movement speed",
		"#LIGHT_BLUE# * levitation",
		"#GOLD#Life per level:#LIGHT_BLUE# 13",
	},
	inc_stats = {str =-2, cun = 2, dex = 2, mag = 3, wil =4,},
	power_source = {arcane=true},
	talents_types = {
		["race/beholder"] ={true, 0.1},
	},
	copy = {
		life_rating = 13,
		growth_points = 0,
		has_central_eye = true, --can check this to fix some lua errors
	 --you always get some as a flag!
		growth_stage = 1,
		growth_curve ={3, 6, 12, 20},
		mana_rating = 7,
		movement_speed=.8,
		random_name_def = "beholder",
		resolvers.inventory{ id=true,
			{type="gem",},
			{type="gem",},
			{type="gem",},
			{defined="ORB_SCRYING"},
		},
		resists = { [DamageType.LIGHTNING] = 10, [DamageType.FIRE] = 10, [DamageType.COLD] = 10, },
		equipdoll = "beholder",
		moddable_tile = "beholder",
		moddable_tile_base = "beholder_nymph.png",
		true_moddable_tile_base = "beholder_nymph.png",
		closed_moddable_tile_base = "beholder_nymph_closedeye.png",
		image = "player/beholder/beholder_nymph.png",
		moddable_tile_nude = true,
		resolvers.genericlast(function(e) e.faction = "undead" end), --yeah I know lazy
		default_wilderness = {"playerpop", "shaloren"},
		starting_zone = "scintillating-caves",
		levitation = 1,

		resolvers.equip{ id=true,
			{defined="BEHOLDER_SOCKET_RING"},
			{type="jewelry", subtype="ring",  autoreq=true, ego_chance=100},
			{type="jewelry", subtype="ring",  autoreq=true, ego_chance=100},
		},
		resolvers.inscription("RUNE:_SHIELDING", {cooldown=14, dur=5, power=130}, 1),
		resolvers.inscription("RUNE:_SHATTER_AFFLICTIONS", {cooldown=18, shield=50}, 2),
		resolvers.inscription("RUNE:_BLINK", {cooldown=18, power=10, range=4,}, 3),

		starting_quest = "starter-zones",
		starting_intro = "beholder",
	},
	talents = {
		T_MAGEEYE_DEVOUR = 1,
		T_BEHOLDER_CLOAKING = 1,
		T_USE_TENTACLES = 1,
		T_TENTACLE_MASTERY = 1,
	},
	random_escort_possibilities = { {"tier1.1", 1, 2}, {"tier1.2", 1, 2}, {"daikara", 1, 2}, {"old-forest", 1, 4}, {"dreadfell", 1, 8}, {"reknor", 1, 2}, },
	body = {FINGER = 8,LITE=1,HEAD=1,NECK=1,TOOL=1,MAINHAND=1,OFFHAND=1,FEET="0",BODY="0",QUIVER="0",BELT="0",HANDS="0",CLOAK="0"},
}

-- Allow it in Maj'Eyal campaign
getBirthDescriptor("world", "Maj'Eyal").descriptor_choices.race.Beholder = "allow"
getBirthDescriptor("world", "Infinite").descriptor_choices.race.Beholder = "allow"
getBirthDescriptor("world", "Arena").descriptor_choices.race.Beholder = "allow"

ActorInventory.equipdolls.beholder = { w=48, h=48, itemframe="ui/equipdoll/itemframe48.png", itemframe_sel="ui/equipdoll/itemframe-sel48.png", ix=3, iy=3, iw=42, ih=42, doll_x=116, doll_y=168+64, list={
		PSIONIC_FOCUS = {{weight=1, x=48, y=48}},
		MAINHAND = {{weight=2, x=48, y=120}},
		OFFHAND = {{weight=3, x=48, y=192}},
		FINGER = {{weight=12, x=264, y=192},{weight=4, x=48, y=264},{weight=11, x=264, y=264},{weight=10, x=264, y=336},{weight=5, x=48, y=336},{weight=6, x=48, y=408}, {weight=7, x=120, y=408, text="bottom"},{weight=13, x=264, y=120}},
		TOOL = {{weight=9, x=264, y=408, text="bottom"}},
		LITE = {{weight=8, x=192, y=408}},
		NECK = {{weight=14, x=192, y=48, text="topright"}},
		HEAD = {{weight=15, x=120, y=48, text="topleft"}},
}}

---------------------------------------------------------
--                    All Campaigns                    --
---------------------------------------------------------
-- Shamelessly copied everything in this section from Frog's Barachi race. Thank you Frogge!
-- Add beholder to all campaigns
for i, bdata in ipairs(Birther.birth_descriptor_def.world) do
	if bdata.descriptor_choices and bdata.descriptor_choices.race then
		bdata.descriptor_choices.race.Beholder = "allow"
	end
end

--superload beholder into special starting scenarios
local demo_def = getBirthDescriptor("subclass", "Demonologist")
local doom_def = getBirthDescriptor("subclass", "Doombringer")

if demo_def then
	local old_start = demo_def.copy.class_start_check

	--quietly masquerades us as a human so we can slip through the (awful and stupid) starting zone checks
	local function new_start(self)
		local real_race = self.descriptor.race
		if real_race == "Beholder" then
			self.descriptor.race = "Human"
		end
		old_start(self)
		self.descriptor.race = real_race
	end

	demo_def.copy.class_start_check = new_start
	doom_def.copy.class_start_check = new_start
end

local writhe_def = getBirthDescriptor("subclass", "Writhing One")
local coe_def = getBirthDescriptor("subclass", "Cultist of Entropy")

if writhe_def then
	local old_start = writhe_def.copy.class_start_check

	--quietly masquerades us as a human so we can slip through the (awful and stupid) starting zone checks
	local function new_start(self)
		local real_race = self.descriptor.race
		if real_race == "Beholder" then
			self.descriptor.race = "Human"
		end
		old_start(self)
		self.descriptor.race = real_race
	end

	writhe_def.copy.class_start_check = new_start
	coe_def.copy.class_start_check = new_start
end

--retrofits beholder support into EoR by (non-destructively) popping in a before_start check
local orcs_def = getBirthDescriptor("world", "Orcs")
if orcs_def then
	local old_start = orcs_def.copy.before_starting_zone

	--are we a beholder? yes? then mess with our start stuff
	local function new_start(self)
		if self.descriptor.race == "Beholder" then
			self.faction = 'kruk-pride'
			self.default_wilderness = {"playerpop", "orc"}
			self.starting_zone = "orcs+town-kruk"
			self.starting_quest = "orcs+kruk-invasion"
		end
		if old_start then old_start(self) end
	end

	orcs_def.copy.before_starting_zone = new_start
end
