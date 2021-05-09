local class = require "engine.class"
local ActorTalents = require "engine.interface.ActorTalents"
local ActorTemporaryEffects = require "engine.interface.ActorTemporaryEffects"
local Birther = require "engine.Birther"
local DamageType = require "engine.DamageType"
local Combat = require "mod.class.interface.Combat"
local Map = require "engine.Map"

class:bindHook("ToME:load", function(self, data)
	ActorTemporaryEffects:loadDefinition("/data-wkbeholder/timed_effects.lua")
	ActorTalents:loadDefinition("/data-wkbeholder/talents/spells.lua")
	Birther:loadDefinition("/data-wkbeholder/birth/races/beholder.lua")
	Birther:loadDefinition("/data-wkbeholder/birth/classes/eyes.lua")

	--ActorTalents:loadDefinition("/data-wkbeholder/talents-redefine.lua")--Nifty little way to reconfigure a few talents here and there courtesy of Hackem_Muche

	DamageType:loadDefinition("data-wkbeholder/damage_types.lua")
	Combat.weapon_talents.tentacle = ActorTalents.T_TENTACLE_MASTERY

	--SUPER NAUGHTY MANABURN DAMAGE RESIST!!!
	DamageType.dam_def[DamageType.MANABURN].projector = function(src, x, y, type, dam)
		local target = game.level.map(x, y, Map.ACTOR)
		if target then
			local protect = math.min((target:attr("manaburn_resist") or 0 )/100,1)

			local mana = dam *(1-protect)
			local vim = dam*(1-protect) / 2
			local positive = dam*(1-protect) / 4
			local negative = dam*(1-protect) / 4

			mana = math.min(target:getMana(), mana)
			vim = math.min(target:getVim(), vim)
			positive = math.min(target:getPositive(), positive)
			negative = math.min(target:getNegative(), negative)

			target:incMana(-mana)
			target:incVim(-vim)
			target:incPositive(-positive)
			target:incNegative(-negative)

			local dam = math.max(mana, vim * 2, positive * 4, negative * 4)
			if protect>0 and protect<1 and dam>0 then
				game.logSeen(target, "#PURPLE#%s is protected from %d manaburn damage!", target.name:capitalize(),dam /(1-protect)-dam)
			end
			return DamageType:get(DamageType.ARCANE).projector(src, x, y, DamageType.ARCANE, dam)
		end
		return 0
	end

	--Add parameters to particular talents for Gaze Mastery (Paralyzing Gaze)
	ActorTalents.talents_def.T_RUSH.is_stamina_based_movement = true
	ActorTalents.talents_def.T_DISENGAGE.is_stamina_based_movement = true
	ActorTalents.talents_def.T_HACK_N_BACK.is_stamina_based_movement = true
	ActorTalents.talents_def.T_SWITCH_PLACE.is_stamina_based_movement = true
end)

class:bindHook("Entity:loadList", function(self, data)
	if data.file == "/data/general/objects/objects.lua" then
		self:loadList("/data-wkbeholder/general/objects/beholder_rings.lua", data.no_default, data.res, data.mod, data.loaded)
	end
end)

class:bindHook("DamageProjector:final", function(self, data)
	local target = game.level.map(data.x,data.y,engine.Map.ACTOR)

	if target then
		if target:isTalentActive(game.player.T_E_ORIGIN) then
			local t = target:getTalentFromId(game.player.T_E_ORIGIN)
			data.dam = t.on_damage(target, t, data.type, data.dam)
		end

	end
	return true
end)

class:bindHook("Actor:postUseTalent", function(self, data)
	if self:hasEffect(self.EFF_THWARTED_BY_THE_GAZE) and data.t.is_stamina_based_movement then
		return nil
	end
end)

class:bindHook("Actor:postUseTalent", function(self, data)
	if data.t.is_spell and self:hasEffect(self.EFF_DRAINED_BY_THE_GAZE) and not self:attr("talent_reuse") and not (data.t.mode == "sustained" and self:isTalentActive(data.t.id)) then
		local p = self:hasEffect(self.EFF_DRAINED_BY_THE_GAZE)

			p.src.__project_source = p.src.sustain_talents.T_DRAINING_GAZE.effect
			local dam_crit = p.src:spellCrit(p.dam_retribution)
			local realdam = DamageType:get(DamageType.PURE_MANADRAIN).projector(p.src, self.x, self.y, DamageType.PURE_MANADRAIN, {dam=dam_crit})
			p.src.__project_source = nil

			local mana_gained = p.src:callTalent(p.src.T_DRAINING_GAZE, "getManaGain")

			p.src:incMana(mana_gained)
	end

	return true
end)

local checkInGazeAll = function(self)
	--do this as a series of checks rather than an interation over all "gaze" types for speed
	if self:hasEffect(self.EFF_DRAINED_BY_THE_GAZE) then self:callEffect(self.EFF_DRAINED_BY_THE_GAZE, "doCheckInGaze") end
	if self:hasEffect(self.EFF_THWARTED_BY_THE_GAZE) then self:callEffect(self.EFF_THWARTED_BY_THE_GAZE, "doCheckInGaze") end
	if self:hasEffect(self.EFF_BEHELD_BY_THE_GAZE) then self:callEffect(self.EFF_BEHELD_BY_THE_GAZE, "doCheckInGaze") end
end

class:bindHook("Actor:move", function(self, data)
	checkInGazeAll(self)
	if not data.force and data.moved and (data.ox~=self.x or data.oy~=self.y) then
		--note to self: util.getDir will check the difference between the passed coords. it converts them to either 1, 0, or -1, then passes them to another function.
		--2nd function translates 1, 0, or -1 into one of the 8 directions. Whole thing returns a table with the coords turned into their respective directions, plus the respective 1/0/-1.
		--the upshot is that self.facing_direction should always contain a table with 2 values, plus 2 additional values.
		self.facing_direction = util.getDir(self.x, self.y, data.ox, data.oy)
	end
	return true
end)

class:bindHook("Actor:actBase:Effects", function(self, data)
	local todel = {}
	for tid, p in pairs(self.sustain_talents) do
		if p.beholder_sustain_dur then p.beholder_sustain_dur = p.beholder_sustain_dur - 1 end
		if p.beholder_sustain_dur and p.beholder_sustain_dur <= 0 then
			todel[#todel+1] = tid
		end
	end
	while #todel > 0 do
		self:forceUseTalent(table.remove(todel), {ignore_energy=true})
	end

	checkInGazeAll(self)
	return true
end)

class:bindHook("DamageProjector:base", function(self, data)
	local target = game.level.map(data.x, data.y, Map.ACTOR)
	local src = data.src

	--Lower duration of Paralyzed By The Gaze with  non-mind damage
	if target and target:hasEffect(target.EFF_PARALYZED_BY_THE_GAZE) then
		if (data.dam and data.dam > 0) and data.type ~= DamageType.MIND then
			target:callEffect("EFF_PARALYZED_BY_THE_GAZE", "handleDamage", data.dam)
		end
	end
	--Handle Beholder Focus damage bonuses
	if target and src and src.getGaze and src:getGaze() then
		if src:knowTalent(src.T_BEHOLDER_FOCUS) and src.turn_procs and src.turn_procs.is_crit then
			local grids = src:callTalent(src[src:getGaze().id], "doGetGazeGrids", src)
			for px, ys in pairs(grids) do
				for py, _ in pairs(ys) do
					if px == data.x and py == data.y then
						local mult = (src:callTalent(src.T_BEHOLDER_FOCUS, "get_bonus_crit")/100 + src.turn_procs.crit_power ) / src.turn_procs.crit_power
						data.dam = data.dam * mult
					end
				end
			end
		end
	end
	return true
end)
