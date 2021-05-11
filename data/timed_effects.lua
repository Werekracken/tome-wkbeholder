local Entity = require "engine.Entity"
local Particles = require "engine.Particles"

local checkInGaze = function(self, eff)
	local p = eff.src.sustain_talents.T_PARALYZING_GAZE or eff.src.sustain_talents.T_DRAINING_GAZE or nil
	--replace this with getGaze, but needs to return sustain table instead of talent def

	local in_gaze = false
	local eff_def = self.tempeffect_def[eff.effect_id]

	if not eff_def then
		return nil
	elseif not p then --do nothing, leaving in_gaze as false
	elseif eff_def.gaze and eff_def.gaze ~= p.name then --do nothing, leaving in_gaze as false
	else
		for px, ys in pairs((p.effect and p.effect.grids or {})) do
			if self.x == px then
				for py, _ in pairs(ys) do
					if self.y == py then in_gaze = true
					end
				end
			end
		end
	end
	if eff.effect_id == "EFF_PARALYZED_BY_THE_GAZE_INACTIVE" then
		if in_gaze and p.name == "Paralyzing Gaze" then eff.due_replacement = true
			self:removeEffect(self[eff.effect_id], false, true)
		end
		return true
	end
	if not in_gaze then
		if eff.effect_id == "EFF_PARALYZED_BY_THE_GAZE" then eff.due_replacement = true end
		self:removeEffect(self[eff.effect_id], false, true)
		return false
	else return true
	end
end

newEffect{
	name = "DRAINED_EYESTALKS", image = "effects/drained_eyestalks.png",
	desc = "Drained Eyestalks",
	long_desc = function(self, eff) return ("The more you use your eye beams, the longer they will take to recharge (+%d cooldowns)."):format(math.ceil(eff.power/2)) end,
	type = "other",
	charges = function(self, eff) return math.ceil(eff.power/2) end,
	subtype = { infusion=true },
	status = "detrimental",
	no_stop_enter_worldmap = true, no_stop_resting = true,
	parameters = { power=1 },
	on_merge = function(self, old_eff, new_eff)
		old_eff.dur = new_eff.dur
		old_eff.power = old_eff.power + new_eff.power
		return old_eff
	end,
}

newEffect{
	name = "DRAINED_CENTRAL_EYE", image = "effects/drained_central_eye.png",
	desc = "Drained Central Eye",
	long_desc = function(self, eff)
		return self:knowTalent(self.T_BEHOLDER_INVIGORATE) and ("Your central eye is drained and unusable for %d more turns.\n\nWhile drained your magical abilities are boosted, granting a spellpower increase of %d."):format(eff.dur+1,eff.spower) or ("Your central eye is drained and unusable for %d more turns."):format(eff.dur+1) end,
	type = "other",
	subtype = { infusion=true },
	status = "detrimental",
	no_stop_enter_worlmap = true, no_stop_resting = true,
	parameters = { power=1,boost=0,spower=0 },
	activate = function(self, eff)
		if self:knowTalent(self.T_BEHOLDER_INVIGORATE) then eff.spower = self:callTalent(self.T_BEHOLDER_INVIGORATE, "getSpellPowerBoost") end
		eff.tmpid2 = self:addTemporaryValue("combat_spellpower", eff.spower)
		if not self.descriptor.fake_race then
			self:removeAllMOs()
			self.image="player/human_male/base_shadow_01.png"
			if self.growth_stage>=1 and self.growth_stage<3 then
				self.add_mos = {{image="player/beholder/"..(self.closed_moddable_tile_base), display_h=.75,display_w=.75, display_y=.25, display_x=.15}}
			end
			if self.growth_stage>=3 and self.growth_stage<5 then
				self.add_mos = {{image="player/beholder/"..(self.closed_moddable_tile_base), display_h=1,display_w=1, display_y=0, display_x=0}}
			end
			if self.growth_stage>=5 then
				self.add_mos = {{image="player/beholder/"..(self.closed_moddable_tile_base),  display_h=1.5,display_w=1.5, display_y=-.5, display_x=-.25}}
			end
			game.level.map:updateMap(self.x, self.y)
		end
	end,
	deactivate = function(self, eff)
		self:removeTemporaryValue("combat_spellpower", eff.tmpid2)
		if not self.descriptor.fake_race then
			self:removeAllMOs()
			self.image="player/human_male/base_shadow_01.png"
			if self.growth_stage>=1 and self.growth_stage<3 then
				self.add_mos = {{image="player/beholder/"..(self.true_moddable_tile_base),  display_h=.75,display_w=.75, display_y=.25, display_x=.15}}
			end
			if self.growth_stage>=3 and self.growth_stage<5 then
				self.add_mos = {{image="player/beholder/"..(self.true_moddable_tile_base), display_h=1,display_w=1, display_y=0, display_x=0}}
			end
			if self.growth_stage>=5 then
				self.add_mos = {{image="player/beholder/"..(self.true_moddable_tile_base), display_h=1.5,display_w=1.5, display_y=-.5, display_x=-.25}}
			end
			game.level.map:updateMap(self.x, self.y)
		end
	end,
	on_merge = function(self, old_eff, new_eff)
		old_eff.dur = new_eff.dur
		old_eff.power = old_eff.power + new_eff.power
		return old_eff
	end,
}

newEffect{
	name = "EGGED", image = "talents/freeze.png",
	desc = "Eggy",
	long_desc = function(self, eff) return ("The target is in an egg and will hatch shortly!") end,
	type = "other",
	subtype = "other",
	status = "detrimental",
	parameters = {},
	on_gain = function(self, err) return "#Target# is trapped in an egg!", "+EGG" end,
	on_lose = function(self, err) return "#Target# is free from the egg.", "-EGG" end,
	activate = function(self, eff)

		if not self.add_displays then
			self.add_displays = { Entity.new{image='npc/beholder_egg.png', display=' ', display_on_seen=true } }
			eff.added_display = true
		end
		self:removeAllMOs()
		game.level.map:updateMap(self.x, self.y)

		eff.hp = eff.hp or 100
		eff.healid = self:addTemporaryValue("no_healing", 1)
		eff.moveid = self:addTemporaryValue("never_move", 1)
		eff.frozid = self:addTemporaryValue("frozen", 1)
		eff.defid = self:addTemporaryValue("combat_def", -1000)
		eff.rdefid = self:addTemporaryValue("combat_def_ranged", -1000)
		eff.sefid = self:addTemporaryValue("negative_status_effect_immune", 1)

		self:setTarget(self)
	end,
	on_timeout = function(self, eff)
		self:setTarget(self)
	end,
	deactivate = function(self, eff)
		self:removeTemporaryValue("no_healing", eff.healid)
		self:removeTemporaryValue("never_move", eff.moveid)
		self:removeTemporaryValue("frozen", eff.frozid)
		self:removeTemporaryValue("combat_def", eff.defid)
		self:removeTemporaryValue("combat_def_ranged", eff.rdefid)
		self:removeTemporaryValue("negative_status_effect_immune", eff.sefid)

		if eff.added_display then self.add_displays = nil end
		self:removeAllMOs()
		game.level.map:updateMap(self.x, self.y)
		self:setTarget(nil)
	end,
}

-- newEffect{
-- 	name = "EMPOWERED_MAGIC", image = "talents/rune__manasurge.png",
-- 	desc = "Empowered Magic",
-- 	long_desc = function(self, eff) return ("The target's spellpower has been increased by %d."):
-- 	format(eff.power) end,
-- 	type = "magical",
-- 	subtype = { arcane=true },
-- 	status = "beneficial",
-- 	parameters = { power=10 },
-- 	activate = function(self, eff)
-- 		eff.tmpid = self:addTemporaryValue("combat_spellpower", eff.power)
-- 	end,
-- 	deactivate = function(self, eff)
-- 		self:removeTemporaryValue("combat_spellpower", eff.tmpid)
-- 	end,
-- }

newEffect{
	name = "THWARTED_BY_THE_GAZE",
	desc = "Thwarted by the Gaze",
	long_desc = function(self, eff) return ("The target is slowed by %d%% and also suffers a stun, sleep, and confusion resistance penalty of %d%% for %d turns"):
	format(eff.power, eff.power, eff.dur) end,
	type = "mental",
	subtype = {gaze = true},
	gaze = "Paralyzing Gaze",
	status = "detrimental",
	parameters = { power=5 },
	activate = function(self, eff)
		eff.stun = self:addTemporaryValue("stun_immune", -eff.stun_resist_pen)
		eff.confusion = self:addTemporaryValue("confusion_immune", -eff.stun_resist_pen)
		eff.slow = self:addTemporaryValue("global_speed_add", -eff.stun_resist_pen)
	end,
	deactivate = function(self, eff)
		self:removeTemporaryValue("stun_immune", eff.stun)
		self:removeTemporaryValue("confusion_immune", eff.confusion)
		self:removeTemporaryValue("global_speed_add", eff.slow)
	end,
}

newEffect{
	name = "DRAINED_BY_THE_GAZE",
	desc = "Drained by the Gaze",
	long_desc = function(self, eff) return ("The target's spellcasting is stricken for %d turns, suffering a %d%% chance of spell failure as well as being victim to a magical backlash. On activating a spell, whether succeeding or not, the target will suffer %d arcane damage and a cooldown increase of %d%% to that spell."):
	format(eff.dur, eff.magic_disruption, eff.dam_retribution, eff.power*100) end,
	type = "mental",
	subtype = {gaze = true},
	status = "detrimental",
	gaze = "Draining Gaze",
	parameters = { power=1, dam_retribution=0, magic_disruption=10 },
	doCheckInGaze = function(self, eff) checkInGaze(self, eff) end,
	activate = function(self, eff)
		eff.spellfail_id = self:addTemporaryValue("spell_failure", eff.magic_disruption)
	end,
	deactivate = function(self, eff)
		self:removeTemporaryValue("spell_failure", eff.spellfail_id)
	end,
}

newEffect{
	name = "IMMUNE_PARALYZING_GAZE",
	desc = "Immune to Paralyzing Gaze",
	long_desc = function(self, eff) return ("The target has overcome the beholder's gaze, resisting its paralysis effects for %d turns."):
	format(eff.dur) end,
	type = "other",
	subtype = {miscellaneous=true},
	status = "beneficial",
	parameters = { power=1 },
	activate = function(self, eff)
	end,
	deactivate = function(self, eff)
	end,
	-- on_merge = function(self, old_eff, new_eff)
	-- 	old_eff.dur = new_eff.dur
	-- 	old_eff.power = old_eff.power + new_eff.power
	-- 	return old_eff
	-- end,
}

newEffect{
	name = "BEHELD_BY_THE_GAZE",
	desc = "Beheld by the Gaze",
	long_desc = function(self, eff) return ("The target incurs the wrath of the beholder's central eye, granting the beholder a +%d bonus to crit damage against it"):
	format(eff.power) end,
	type = "other",
	-- no_remove = true,
	subtype = {gaze=true},
	status = "detrimental",
	parameters = { power=1 },
	activate = function(self, eff)
	end,
	deactivate = function(self, eff)
	end,
	doCheckInGaze = function(self, eff) checkInGaze(self, eff) end,
	on_timeout = function(self, eff) checkInGaze(self, eff) end,
	-- on_merge = function(self, old_eff, new_eff)
	-- 	old_eff.dur = new_eff.dur
	-- 	old_eff.power = old_eff.power + new_eff.power
	-- 	return old_eff
	-- end,
}

newEffect{
	name = "PARALYZED_BY_THE_GAZE_INACTIVE", image = "talents/sleep.png",
	desc = "Paralyzed by the Gaze (inactive)",
	long_desc = function(self, eff) return ("The target is paralyzed and unable to act. Every %d damage it takes will reduce the duration of the effect by one turn. However, as the target is outside the gaze, the target is able to act this turn."):format(eff.power) end,
	type = "mental",
	subtype = {gaze = true, sleep = true}, --{sleep=true},
	status = "detrimental",
	gaze = "Paralyzing Gaze",
	parameters = { power=1, insomnia=1, waking=0, contagious=0, temp_power = nil, due_replacement=false },
	on_gain = function(self, eff) return end,
	on_lose = function(self, eff) return end,
	on_timeout = function(self, eff)
		-- local dream_prison = false
		-- if eff.src and eff.src.isTalentActive and eff.src:isTalentActive(eff.src.T_DREAM_PRISON) then
		-- 	local t = eff.src:getTalentFromId(eff.src.T_DREAM_PRISON)
		-- 	if core.fov.distance(self.x, self.y, eff.src.x, eff.src.y) <= eff.src:getTalentRange(t) then
		-- 		dream_prison = true
		-- 	end
		-- end
		-- if dream_prison then
		-- 	eff.dur = eff.dur + 1
		-- 	if not eff.particle then
		-- 		if core.shader.active(4) then
		-- 			eff.particle = self:addParticles(Particles.new("shader_shield", 1, {img="shield2", size_factor=1.25}, {type="shield", time_factor=6000, aadjust=5, color={0, 1, 1}}))
		-- 		else
		-- 			eff.particle = self:addParticles(Particles.new("generic_shield", 1, {r=0, g=1, b=1, a=1}))
		-- 		end
		-- 	end
		-- elseif eff.contagious > 0 and eff.dur > 1 then
		-- 	local t = eff.src:getTalentFromId(eff.src.T_SLEEP)
		-- 	t.doContagiousSleep(eff.src, self, eff, t)
		-- end
		-- if eff.particle and not dream_prison then
		-- 	self:removeParticles(eff.particle)
		-- end
		-- -- Incriment Insomnia Duration
		-- if not self:attr("lucid_dreamer") then
		-- 	self:setEffect(self.EFF_INSOMNIA, 1, {power=eff.insomnia})
		-- end
	end,
	handleDamage = function(self, eff, ...)
		local args = {...}
		local dam = args[1]
		eff.temp_power = (eff.temp_power or eff.power) - dam
			while eff.temp_power <= 0 do
				eff.dur = eff.dur - 1
				eff.temp_power = eff.temp_power + eff.power
				if eff.dur <=0 then
					game:onTickEnd(function() self:removeEffect(eff) end) -- Happens on tick end so Night Terror can work properly
					break
				end
			end
	end,
	doCheckInGaze = function(self, eff) checkInGaze(self, eff) end,
	activate = function(self, eff) end,
	deactivate = function(self, eff)
		if eff.due_replacement then
			eff.due_replacement = false
				self:setEffect(self.EFF_PARALYZED_BY_THE_GAZE, eff.dur,
				{immunity_dur = eff.immunity_dur,
				power = eff.power,
				total_dur = eff.total_dur,
				src = eff.src
				})
			return
		end
		if eff.src and not eff.src.dead then self:setEffect(self.EFF_IMMUNE_PARALYZING_GAZE, eff.src:callTalent(eff.src.T_PARALYZING_GAZE, "getImmunityDuration"), {src=eff.src}) end
	end,
}

newEffect{
	name = "PARALYZED_BY_THE_GAZE", image = "talents/sleep.png",
	desc = "Paralyzed by the Gaze",
	long_desc = function(self, eff) return ("The target is paralyzed and unable to act. Every %d damage it takes will reduce the duration of the effect by one turn."):format(eff.power) end,
	type = "mental",
	subtype = {gaze = true, sleep = true}, --{sleep=true },
	gaze = "Paralyzing Gaze",
	status = "detrimental",
	parameters = { power=1, insomnia=1, waking=0, contagious=0, temp_power = nil, due_replacement=false },
	on_gain = function(self, err) return "#Target# has been put to sleep.", "+Sleep" end,
	on_lose = function(self, err) return "#Target# is no longer sleeping.", "-Sleep" end,
	on_timeout = function(self, eff)
		-- local dream_prison = false
		-- if eff.src and eff.src.isTalentActive and eff.src:isTalentActive(eff.src.T_DREAM_PRISON) then
		-- 	local t = eff.src:getTalentFromId(eff.src.T_DREAM_PRISON)
		-- 	if core.fov.distance(self.x, self.y, eff.src.x, eff.src.y) <= eff.src:getTalentRange(t) then
		-- 		dream_prison = true
		-- 	end
		-- end
		-- if dream_prison then
		-- 	eff.dur = eff.dur + 1
		-- 	if not eff.particle then
		-- 		if core.shader.active(4) then
		-- 			eff.particle = self:addParticles(Particles.new("shader_shield", 1, {img="shield2", size_factor=1.25}, {type="shield", time_factor=6000, aadjust=5, color={0, 1, 1}}))
		-- 		else
		-- 			eff.particle = self:addParticles(Particles.new("generic_shield", 1, {r=0, g=1, b=1, a=1}))
		-- 		end
		-- 	end
		-- elseif eff.contagious > 0 and eff.dur > 1 then
		-- 	local t = eff.src:getTalentFromId(eff.src.T_SLEEP)
		-- 	t.doContagiousSleep(eff.src, self, eff, t)
		-- end
		-- if eff.particle and not dream_prison then
		-- 	self:removeParticles(eff.particle)
		-- end
		-- -- Incriment Insomnia Duration
		-- if not self:attr("lucid_dreamer") then
		-- 	self:setEffect(self.EFF_INSOMNIA, 1, {power=eff.insomnia})
		-- end
	end,
	handleDamage = function(self, eff, ...)
		local args = {...}
		local dam = args[1]
		eff.temp_power = (eff.temp_power or eff.power) - dam
			while eff.temp_power <= 0 do
				eff.dur = eff.dur - 1
				eff.temp_power = eff.temp_power + eff.power
				if eff.dur <=0 then
					game:onTickEnd(function() self:removeEffect(eff) end) -- Happens on tick end so Night Terror can work properly
					break
				end
			end
	end,
	doCheckInGaze = function(self, eff) checkInGaze(self, eff) end,
	activate = function(self, eff)
		eff.paralysis_id = self:addTemporaryValue("paralyzed_by_the_gaze", 1)
		eff.sleep_id = self:addTemporaryValue("sleep", 1)
	end,
	deactivate = function(self, eff)
		self:removeTemporaryValue("paralyzed_by_the_gaze", eff.paralysis_id)
		self:removeTemporaryValue("sleep", eff.sleep_id)
		if eff.due_replacement then
			eff.due_replacement = false
			self:setEffect(self.EFF_PARALYZED_BY_THE_GAZE_INACTIVE, eff.dur,
				{immunity_dur = eff.immunity_dur,
				power = eff.power,
				total_dur = eff.total_dur,
				src = eff.src
				})
			return
		end
		if eff.src and not eff.src.dead then self:setEffect(self.EFF_IMMUNE_PARALYZING_GAZE, eff.src:callTalent(eff.src.T_PARALYZING_GAZE, "getImmunityDuration"), {src=eff.src}) end
	end,
}

newEffect{
	name = "TEMPORAL_SWAP", image = "talents/yeek_will.png",
	desc = "Temporal Swap",
	long_desc = function(self, eff) return ("The target has been swapped for a temporal alternate who is allied to %s."):format(eff.src.name:capitalize()) end,
	type = "mental",
	subtype = { dominate=true },
	status = "detrimental",
	parameters = { },
	on_gain = function(self, err) return "#Target# is swapped for a temporal alternate.", _t"+Temporal Swap" end,
	on_lose = function(self, err) return _t"#Target# is free from the domination.", _t"-Temporal Swap" end,
	activate = function(self, eff)
		self:setTarget() -- clear ai target
		eff.old_faction = self.faction
		self.faction = eff.src.faction
		self:effectTemporaryValue(eff, "never_anger", 1)
		self:effectTemporaryValue(eff, "hostile_for_level_change", 1)
	end,
	deactivate = function(self, eff)
		if eff.particle then self:removeParticles(eff.particle) end
		self.faction = eff.old_faction
		self:setTarget(eff.src)
	end,
}