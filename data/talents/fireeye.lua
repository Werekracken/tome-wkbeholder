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
	name = "Flame Laser",
	type = {"spell/fire-eye",1},
	require =  Talents.main_env.spells_req1,
	points = 5,
	random_ego = "attack",
	mana = 8,
	cooldown = function(self,t)
		return 6+math.floor(getEyeDelay(self))
	end,
	is_spell=true,
	tactical = { ATTACK = { FIRE = 2 } },
	range = function(self, t) return math.floor(combatTalentScale(self,t, 5, 9)) end,
	direct_hit = true,
	reflectable = true,
	requires_target = true,
	target = function(self, t)
		local tg = {type="bolt", range=self:getTalentRange(t), talent=t, display={particle="bolt_fire", trail="firetrail"}}
		if self:knowTalent(self.T_FIRE_FOCUS) then
		local r2 = self:getTalentFromId(self.T_FIRE_FOCUS)
		--tg.type = "ball"
		tg["radius"] = r2.getRadiusBonus(self,r2)
		end
		return tg
	end,
	getDamage = function(self, t) return self:combatTalentSpellDamage(t, 20, 200) end,
	on_pre_use = function(self, t, silent) if self:hasEffect(self.EFF_BLINDED) then if not silent  then game.logPlayer(self, "You cannot use your eyestalks while blind!") end  return false end return true end,
	action = function(self, t)
		local tg = self:getTalentTarget(t)
		local x, y = self:getTarget(tg)
		local critboost = 0
		local splash = 0
		local explode = false
		if self:knowTalent(self.T_FIRE_FOCUS) then
			local r = self:getTalentFromId(self.T_FIRE_FOCUS)
			critboost = r.getBonusCrit(self,r)
			explode = true
			--splash = r.getBonusSplash(self,r)
		end

		self.combat_spellcrit = self.combat_spellcrit + critboost
		local final_damage = self:spellCrit(t.getDamage(self, t))
		self.combat_spellcrit = self.combat_spellcrit - critboost
		if self:knowTalent(self.T_FIRE_FOCUS) then
			local r2 = self:getTalentFromId(self.T_FIRE_FOCUS)
			--critboost = r.getBonusCrit(self,r)
			splash = r2.getBonusSplash(self,r2) * final_damage/100
		end
		if not x or not y then return nil end
		local grids = nil
		local burnper  = 0
		if self:knowTalent(self.T_BLAST_BEAM) then
			local z = self:getTalentFromId(self.T_BLAST_BEAM)
			burnper = z.getBonusBurn(self,z)
			burnper = burnper/400
			-- for x, yy in pairs(grids) do
				-- for y, _ in pairs(grids[x]) do
					-- local a = game.level.map(x, y, Map.ACTOR)
					-- if a then
						-- a:setEffect(a.EFF_BURNING, 4, {src=self, power=final_damage * burnper/400, no_ct_effect=true})
						-- --tgts[#tgts+1] = a
					-- end
				-- end
			-- end
		end

		grids = self:project(tg, x, y, DamageType.FLAMELASER, {damage=final_damage,splash=splash,radius = tg.radius,friendlyfire=true,explosion=explode, burn = burnper})
		local _ _, x, y = self:canProject(tg, x, y)

		game.level.map:particleEmitter(self.x, self.y, tg.radius, "firelaser", {tx=x-self.x, ty=y-self.y})


		game:playSoundNear(self, "talents/fire")
		--self:setEffect(self.EFF_DRAINED_EYESTALKS, 10, {power=1})
		return true
	end,
	info = function(self, t)
		local damage = t.getDamage(self, t)
		return ([[Launches a bolt of fire from your eyestalks, doing %0.2f fire damage.
		The range will increase with your talent level and damage will increase with your Spellpower.]]):
		format(damDesc(self, DamageType.FIRE, damage))
	end,
}

newTalent{
	name = "Fire Focus",
	type = {"spell/fire-eye",2},
	require =  Talents.main_env.spells_req2,
	points = 5,
	mode = "passive",
	getRadiusBonus = function(self, t)
		return math.floor(combatTalentScale(self,t, 1, 2.80))
	end,
	getBonusSplash = function(self, t) return  math.floor(combatTalentScale(self,t, 15, 75)) end,
	getBonusCrit = function(self, t) return  math.floor(combatTalentScale(self,t, 2.5, 12.5)) end,
	info = function(self, t)
		local crit = t.getBonusCrit(self, t)
		local splash = t.getBonusSplash(self, t)
		local radius = t.getRadiusBonus(self, t)
		return ([[Increases your critical chance with your fire eyestalk by %d%%.
		Your flame laser will cause %d%% percent splash damage within %d radius of your target.]]):
		format(crit,splash,radius)
	end,
}

newTalent{
	name = "Blast Beam",
	type = {"spell/fire-eye",3},
	require =  Talents.main_env.spells_req3,
	points = 5,
	mode = "passive",
	on_learn = function(self, t)
		self.resists_self[DamageType.FIRE] = (self.resists_self[DamageType.FIRE] or 0) + 18
	end,
	on_unlearn = function(self, t)
		self.resists_self[DamageType.FIRE] = (self.resists_self[DamageType.FIRE] or 0) - 18
	end,
	getBonusBurn = function(self, t) return  math.floor(combatTalentScale(self,t, 15, 75)) end,
	info = function(self, t)
		local burn = t.getBonusBurn(self, t)
		return ([[Causes your Flame Laser to burn victims for %d%% of the original damage over 4 turns.
		Reduces self inflicted fire damage by %d%%]]):
		format(burn,self:getTalentLevelRaw(t) * 18)
	end,
}

--resists_self
newTalent{
	name = "Fire Mastery",
	type = {"spell/fire-eye",4},
	require = Talents.main_env.spells_req4,
	points = 5,
	is_spell=true,
	mode = "sustained",
	sustain_mana = 50,
	cooldown = 30,
	tactical = { BUFF = 2 },
	getDarknessDamageIncrease = function(self, t) return self:getTalentLevelRaw(t) * 2 end,
	getResistPenalty = function(self, t) return combatTalentLimit(self,t, 100, 17, 50, true) end,  -- Limit to < 100%
	--getAffinity = function(self, t) return self:combatTalentLimit(t, 100, 10, 50) end, -- Limit < 100%
	on_pre_use = function(self, t, silent)
		local cnt = 0
		if self:isTalentActive(self.T_FROST_MASTERY) then
		cnt = cnt+1
		end
		if self:isTalentActive(self.T_DEATH_MASTERY) then
		cnt = cnt+1
		end
		if self:isTalentActive(self.T_LIGHTNING_MASTERY) then
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
			dam = self:addTemporaryValue("inc_damage", {[DamageType.FIRE] = t.getDarknessDamageIncrease(self, t)}),
			resist = self:addTemporaryValue("resists_pen", {[DamageType.FIRE] = t.getResistPenalty(self, t)}),
			--affinity = self:addTemporaryValue("damage_affinity", {[DamageType.FIRE] = t.getAffinity(self, t)}),
			particle = self:addParticles(Particles.new("ultrashield", 1, {rm=10, rM=100, gm=0, gM=0, bm=0, bM=0, am=70, aM=180, radius=0.4, density=10, life=14, instop=20})),
		}
	end,
	deactivate = function(self, t, p)
		self:removeParticles(p.particle)
		self:removeTemporaryValue("inc_damage", p.dam)
		self:removeTemporaryValue("resists_pen", p.resist)
		--self:removeTemporaryValue("damage_affinity", p.affinity)
		return true
	end,
	info = function(self, t)
		local damageinc = t.getDarknessDamageIncrease(self, t)
		local ressistpen = t.getResistPenalty(self, t)
		--local affinity = t.getAffinity(self, t)
		return ([[Focus your fire eyestalk, increasing all your fire damage by %d%%, and ignoring %d%% of the fire resistance of your targets.
		Only two masteries may be active at once.]])
		:format(damageinc, ressistpen)
	end,
}
