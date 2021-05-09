-- ToME - Tales of Maj'Eyal
-- Copyright (C) 2009, 2010, 2011, 2012, 2013 Nicolas Casalini
--
-- This program is free software: you can redistribute it and/or modify
-- it under the terms of the GNU General Public License as published by
-- the Free Software Foundation, either version 3 of the License, or
-- (at your option) any later version.
--
-- This program is distributed in the hope that it will be useful,
-- but WITHOUT ANY WARRANTY; without even the implied warranty of
-- MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
-- GNU General Public License for more details.
--
-- You should have received a copy of the GNU General Public License
-- along with this program.  If not, see <http://www.gnu.org/licenses/>.
--
-- Nicolas Casalini "DarkGod"
-- darkgod@te4.org

newTalent{
	name = "Lightning Laser",
	type = {"spell/lightning-eye",1},
	require =  Talents.main_env.spells_req1,
	points = 5,
	is_spell=true,
	random_ego = "attack",
	mana = 8,
	cooldown = function(self,t)
		return 6+math.floor(getEyeDelay(self))
	end,
	tactical = { ATTACK = { LIGHTNING = 2 } },
	range = function(self, t) return math.floor(combatTalentScale(self,t, 5, 9)) end,
	direct_hit = true,
	reflectable = true,
	requires_target = true,
	on_pre_use = function(self, t, silent) if self:hasEffect(self.EFF_BLINDED) then if not silent  then game.logPlayer(self, "You cannot use your eyestalks while blind!") end  return false end return true end,
	target = function(self, t)
		local tg = {type="bolt", range=self:getTalentRange(t), talent=t}

		return tg
	end,
	getDamage = function(self, t) return self:combatTalentSpellDamage(t, 20, 200) end,
	action = function(self, t)
		local tg = self:getTalentTarget(t)
		local x, y = self:getTarget(tg)
		local critboost = 0
		local nb = 1
		local dazechance = 25
		if self:knowTalent(self.T_LIGHTNING_FOCUS) then
			local r = self:getTalentFromId(self.T_LIGHTNING_FOCUS)
			critboost = r.getBonusCrit(self,r)
			nb = 1 + r.getTargetCount(self,r)
		end

		self.combat_spellcrit = self.combat_spellcrit + critboost
		local final_damage = self:spellCrit(t.getDamage(self, t))
		self.combat_spellcrit = self.combat_spellcrit - critboost

		if not x or not y then return nil end
		--local grids = nil

		--grids = self:project(tg, x, y, DamageType.LIGHTNING, final_damage)
		local _ _, x, y = self:canProject(tg, x, y)
		local a = game.level.map(x, y, Map.ACTOR)
		local current_hp=0
		if a then
			current_hp=a.life+ (-a.die_at or 0)
		end
		local realdam = DamageType:get(DamageType.LIGHTNING).projector(self, x, y, DamageType.LIGHTNING, final_damage)
		print(lightning)
		print(current_hp)
		print(realdam)
		realdam = math.min(realdam,current_hp)
		print(realdam)
		game.level.map:particleEmitter(self.x, self.y, tg.radius, "lightning_beam", {tx=x-self.x, ty=y-self.y})
		local freezeper
		local spower
		if self:knowTalent(self.T_THUNDER_RAY) then
			local z = self:getTalentFromId(self.T_THUNDER_RAY)
			freezeper = z.getFreezeper(self,z)
			spower = self:combatSpellpower() * freezeper/100
			if a and not a.dead then
				a:setEffect(a.EFF_DAZED, freezeper/15, {hp=final_damage * 1.5, apply_power=spower, min_dur=1})
				--tgts[#tgts+1] = a
			end
		end
		local fx = x
		local fy = y
		local affected = {}
		local first = nil
		local actor = game.level.map(x, y, Map.ACTOR)
		--if not fx or not fy then return nil end
		if nb > 1 and realdam>0 then
			--if self:knowTalent(self.T_THUNDER_RAY) then

			--end
			--local nb = t.getTargetCount(self, t)
			if actor then
				affected[actor] = true
			end
			--first = actor
			self:project({type="ball", selffire=false, x=x, y=y, radius=6, range=0}, x, y, function(bx, by)
						local actor2 = game.level.map(bx, by, Map.ACTOR)
						if actor2 and not affected[actor2] and self:reactionToward(actor2) < 0 then
							print("[Lightning Eye] found possible actor", actor2.name, bx, by, "distance", core.fov.distance(x, y, bx, by))
							affected[actor2] = true
						end
					end)

			local targets = {}
			if actor then
				affected[actor] = nil
			end
			--affected[first] = nil
			local possible_targets = table.listify(affected)
			print("[Lightning Eye] Found targets:", #possible_targets)
			for i = 2, nb do
				if #possible_targets == 0 then break end
				local act = rng.tableRemove(possible_targets)
				targets[#targets+1] = act[1]
			end

			local sx, sy = self.x, self.y
			for i, actor in ipairs(targets) do
				local tgr = {type="beam", range=self:getTalentRange(t), selffire=false, talent=t, x=fx, y=fy}
				print("[Lightning Eye] jumping from", fx, fy, "to", actor.x, actor.y)
				local dam = final_damage
				self:project(tgr, actor.x, actor.y, DamageType.LIGHTNING_DAZE, {dam=(dam - dam*(i/(nb+1)) ), daze=freezeper or 0, power_check = spower})
				if core.shader.active() then game.level.map:particleEmitter(fx, fy, math.max(math.abs(actor.x-fx), math.abs(actor.y-fy)), "lightning_beam", {tx=actor.x-fx, ty=actor.y-fy}, {type="lightning"})
				else game.level.map:particleEmitter(fx, fy, math.max(math.abs(actor.x-fx), math.abs(actor.y-fy)), "lightning_beam", {tx=actor.x-fx, ty=actor.y-fy})
				end

				sx, sy = actor.x, actor.y
			end
		end

--		game:playSoundNear(self, "talents/fire")
		--self:setEffect(self.EFF_DRAINED_EYESTALKS, 10, {power=1})
		return true
	end,
	info = function(self, t)
		local damage = t.getDamage(self, t)
		return ([[Launches a blast of lightning from your eyestalks, doing %0.2f lightning damage.
		The range will increase with your talent level and damage will increase with your Spellpower.]]):
		format(damDesc(self, DamageType.LIGHTNING, damage))
	end,
}

newTalent{
	short_name="LIGHTNING_FOCUS",
	name = "Lightning Burst",
	type = {"spell/lightning-eye",2},
	is_spell=true,
	require =  Talents.main_env.spells_req2,
	points = 5,
	mode = "passive",
	getTargetCount = function(self, t) return 3 + self:getTalentLevelRaw(t) end,
	getBonusCrit = function(self, t) return  math.floor(combatTalentScale(self,t, 2.5, 12.5)) end,
	info = function(self, t)
		local crit = t.getBonusCrit(self, t)
		local targets = t.getTargetCount(self, t)
		return ([[Increases your critical chance with your lightning eyestalk by %d%%.
		If your target survives, your lightning laser can hit up to %d additional targets up to 6 grids from original target, and will never hit the same one twice; nor will it hit you.
		Each jump will do slightly less damage.]]):
		format(crit,targets)
	end,
}

newTalent{
	name = "Thunder Ray",
	type = {"spell/lightning-eye",3},
	require =  Talents.main_env.spells_req3,
	points = 5,
	mode = "passive",
	getFreezeper = function(self, t) return  math.floor(combatTalentScale(self,t, 30, 100)) end,
	info = function(self, t)
		local dur = t.getFreezeper(self, t)/15
		return ([[Causes your Lightning Laser to daze enemies for up to %d turns. Daze chance increases with talent level and your Spellpower.]]):format(dur)
	end,
}

newTalent{
	name = "Lightning Mastery",
	type = {"spell/lightning-eye",4},
	require = Talents.main_env.spells_req4,
	points = 5,
	mode = "sustained",
	sustain_mana = 50,
	is_spell=true,
	cooldown = 30,
	tactical = { BUFF = 2 },
	getDarknessDamageIncrease = function(self, t) return self:getTalentLevelRaw(t) * 2 end,
	getResistPenalty = function(self, t) return combatTalentLimit(self,t, 100, 17, 50, true) end,  -- Limit to < 100%
	on_pre_use = function(self, t, silent)
		local cnt = 0
		if self:isTalentActive(self.T_FROST_MASTERY) then
		cnt = cnt+1
		end
		if self:isTalentActive(self.T_DEATH_MASTERY) then
		cnt = cnt+1
		end
		if self:isTalentActive(self.T_FIRE_MASTERY) then
		cnt = cnt+1
		end

		if cnt>=2 then
			if not silent then game.logSeen(self, "You may only sustain two masteries active at once.") end
			return false
		end
		return true
	end,
	activate = function(self, t)
		game:playSoundNear(self, "talents/spell_generic")
		return {
			dam = self:addTemporaryValue("inc_damage", {[DamageType.LIGHTNING] = t.getDarknessDamageIncrease(self, t)}),
			resist = self:addTemporaryValue("resists_pen", {[DamageType.LIGHTNING] = t.getResistPenalty(self, t)}),

			particle = self:addParticles(Particles.new("ultrashield", 1, {rm=0, rM=0, gm=0, gM=0, bm=10, bM=100, am=70, aM=180, radius=0.4, density=10, life=14, instop=20})),
		}
	end,
	deactivate = function(self, t, p)
		self:removeParticles(p.particle)
		self:removeTemporaryValue("inc_damage", p.dam)
		self:removeTemporaryValue("resists_pen", p.resist)
		return true
	end,
	info = function(self, t)
		local damageinc = t.getDarknessDamageIncrease(self, t)
		local ressistpen = t.getResistPenalty(self, t)
		return ([[Focus your lightning eyestalk, increasing all your lightning damage by %d%%, and ignoring %d%% of the lightning resistance of your targets.
		Only two masteries may be active at once.]])
		:format(damageinc, ressistpen)
	end,
}
