--Control growth!

local _M = loadPrevious(...)

--local Faction = require "engine.Faction"

-- local base_levelup = _M.levelup


-- function _M:levelup()

	-- base_levelup(self)
	-- if self:attr("growth_points") then
		-- if self.level == 10 or self.level == 20 or self.level == 36 then
				-- self.unused_talents_types = self.unused_talents_types - 1
		-- end
	-- end
-- end

local base_init = _M.init

local base_useEnergy = _M.useEnergy

local base_act = _M.act

function _M:init(t, no_default)
	base_init(self, t, no_default)
	self.facing_direction = resolvers.rngtable({1, 2, 3, 4, 6, 7, 8, 9})
end

function _M:useEnergy(val)

	base_useEnergy(self,val)
	if self:isTalentActive(self.T_USE_TENTACLES) then
		local t = self:getTalentFromId(self.T_USE_TENTACLES)
		t.do_tkautoattack(self, t)
	end
end

function _M:getVisible(self, type, foes_only)
	local seen = {}
	if self:hasEffect(self.EFF_ARCANE_EYE) then
		local eff = self:hasEffect(self.EFF_ARCANE_EYE)
		local map = game.level.map

		core.fov.calc_circle(
			eff.x, eff.y, game.level.map.w, game.level.map.h, eff.radius,
			function(_, x, y) if map:checkAllEntities(x, y, "block_sight", self) then return true end end,
			function(_, x, y)
				local tg = game.level.map(x, y, type)
				if type == game.level.map.ACTOR then
					if tg and (foes_only and self:reactionToward(actor) < 0) and self:canSee(actor) and game.level.map.seens(x, y) then
						seen[#seen + 1] = {x=x,y=y,actor=actor}
					end
				else
				end
			end,
		nil)
	end
	return seen
end

-- function _M:isVisible(self, viewer)
-- 	local seens = viewer:getVisible()
-- end

function _M:getTalentCooldown(t)
	if not t.cooldown then return end
	local cd = t.cooldown
	if type(cd) == "function" then cd = cd(self, t) end
	if not cd then return end

	if t.type[1] == "inscriptions/infusions" then
		local eff = self:hasEffect(self.EFF_INFUSION_COOLDOWN)
		if eff and eff.power then cd = cd + eff.power end
	elseif t.type[1] == "inscriptions/runes" then
		local eff = self:hasEffect(self.EFF_RUNE_COOLDOWN)
		if eff and eff.power then cd = cd + eff.power end
	elseif t.type[1] == "inscriptions/taints" then
		local eff = self:hasEffect(self.EFF_TAINT_COOLDOWN)
		if eff and eff.power then cd = cd + eff.power end
	elseif self:attr("arcane_cooldown_divide") and (t.type[1] == "spell/arcane" or t.type[1] == "spell/aether") then
		cd = math.ceil(cd / self.arcane_cooldown_divide)
	end

	if self.talent_cd_reduction[t.id] then cd = cd - self.talent_cd_reduction[t.id] end
	if self.talent_cd_reduction.all then cd = cd - self.talent_cd_reduction.all end

	local eff = self:hasEffect(self.EFF_BURNING_HEX)
	if eff and not self:attr("talent_reuse") then
		cd = 1 + cd * eff.power
	end

	if t.is_spell then
		local eff = self:hasEffect(self.EFF_DRAINED_BY_THE_GAZE)
		if eff and not self:attr("talent_reuse") then
			cd = 1 + cd * eff.power
		end
	end

	if t.is_spell then
		return math.ceil(cd * (1 - (self.spell_cooldown_reduction or 0)))
	elseif t.is_summon then
		return math.ceil(cd * (1 - (self.summon_cooldown_reduction or 0)))
	else
		return math.ceil(cd)
	end
end

function _M:getGaze()
	if not self:knowTalentType("spell/central-eye") then return nil end
	if self:isTalentActive(self.T_DRAINING_GAZE) then return self.talents_def.T_DRAINING_GAZE end
	if self:isTalentActive(self.T_PARALYZING_GAZE) then return self.talents_def.T_PARALYZING_GAZE end
end


function _M:act()
	if self:hasEffect(self.EFF_DRAINED_BY_THE_GAZE) then  self:callEffect(self.EFF_DRAINED_BY_THE_GAZE, "doCheckInGaze") end
	if self:hasEffect(self.EFF_BEHELD_BY_THE_GAZE) then  self:callEffect(self.EFF_BEHELD_BY_THE_GAZE, "doCheckInGaze") end
	-- if self:hasEffect(self.EFF_THWARTED_BY_THE_GAZE) then  self:callEffect(self.EFF_THWARTED_BY_THE_GAZE, "doCheckInGaze") end
	if self:hasEffect(self.EFF_PARALYZED_BY_THE_GAZE) then  self:callEffect(self.EFF_PARALYZED_BY_THE_GAZE, "doCheckInGaze") end
	if self:hasEffect(self.EFF_PARALYZED_BY_THE_GAZE_INACTIVE) then self:callEffect(self.EFF_PARALYZED_BY_THE_GAZE_INACTIVE, "doCheckInGaze") end
	return base_act(self)
end

return _M
