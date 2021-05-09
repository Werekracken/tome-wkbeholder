--newInscription function call's Hackem_Muche's improved NewTalent code
newInscription = function(t)
	-- Warning, up that if more than 5 inscriptions are ever allowed
	for i = 1, 6 do
		local tt = table.clone(t)
		tt.short_name = tt.name:upper():gsub("[ ]", "_").."_"..i
		tt.display_name = function(self, t)
			local data = self:getInscriptionData(t.short_name)
			if data.item_name then
				local n = tstring{t.name, " ["}
				n:merge(data.item_name)
				n:add("]")
				return n
			else
				return t.name
			end
		end
		if tt.type[1] == "inscriptions/infusions" then tt.auto_use_check = function(self, t) return not self:hasEffect(self.EFF_INFUSION_COOLDOWN) end
		elseif tt.type[1] == "inscriptions/runes" then tt.auto_use_check = function(self, t) return not self:hasEffect(self.EFF_RUNE_COOLDOWN) end
		elseif tt.type[1] == "inscriptions/taints" then tt.auto_use_check = function(self, t) return not self:hasEffect(self.EFF_TAINT_COOLDOWN) end
		end
		tt.auto_use_warning = "- will only auto use when no saturation effect exists"
		tt.cooldown = function(self, t)
			local data = self:getInscriptionData(t.short_name)
			return data.cooldown
		end
		tt.old_info = tt.info
		tt.info = function(self, t)
			local ret = t.old_info(self, t)
			local data = self:getInscriptionData(t.short_name)
			if data.use_stat and data.use_stat_mod then
				ret = ret..("\nIts effects scale with your %s stat."):format(self.stats_def[data.use_stat].name)
			end
			return ret
		end
		if not tt.image then
			tt.image = "talents/"..(t.short_name or t.name):lower():gsub("[^a-z0-9_]", "_")..".png"
		end
		tt.no_unlearn_last = true
		tt.is_inscription = true
		newTalent(tt)
	end
end

newInscription{
	name = "Rune: Phase Door",
	type = {"inscriptions/runes", 1},
	points = 1,
	is_spell = true,
	is_teleport = true,
	tactical = { ESCAPE = 2 },
	action = function(self, t)
		local data = self:getInscriptionData(t.short_name)
		local power = (data.power or data.range) + data.inc_stat * 3
		game.level.map:particleEmitter(self.x, self.y, 1, "teleport")

		self.defense_on_teleport = (self.defense_on_teleport or 0) + power
		self.resist_all_on_teleport = (self.resist_all_on_teleport or 0) + power
		self.effect_reduction_on_teleport = (self.effect_reduction_on_teleport or 0) + power

		self:teleportRandom(self.x, self.y, data.range + data.inc_stat)
		game.level.map:particleEmitter(self.x, self.y, 1, "teleport")

		self.defense_on_teleport = self.defense_on_teleport - power
		self.resist_all_on_teleport = self.resist_all_on_teleport - power
		self.effect_reduction_on_teleport = self.effect_reduction_on_teleport - power
		

		-- self:setEffect(self.EFF_OUT_OF_PHASE, data.dur or 3, {
		-- 	defense=(data.power or data.range) + data.inc_stat * 3,
		-- 	resists=(data.power or data.range) + data.inc_stat * 3,
		-- 	effect_reduction=(data.power or data.range) + data.inc_stat * 3,
		--})
		return true
	end,
	info = function(self, t)
		local data = self:getInscriptionData(t.short_name)
		local power = (data.power or data.range) + data.inc_stat * 3
		return ([[Activate the rune to teleport randomly in a range of %d.
		Afterwards you stay out of phase for %d turns. In this state all new negative status effects duration is reduced by %d%%, your defense is increased by %d and all your resistances by %d%%.]]):
		format(data.range + data.inc_stat, data.dur or 3, power, power, power)
	end,
	short_info = function(self, t)
		local data = self:getInscriptionData(t.short_name)
		local power = (data.power or data.range) + data.inc_stat * 3
		return ([[range %d; power %d; dur %d]]):format(data.range + data.inc_stat, power, data.dur or 3)
	end,
}