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
	name = "Death Ray",
	type = {"spell/death-eye",1},
	require =  Talents.main_env.spells_req_high1,
	points = 5,
	random_ego = "attack",
	mana = 50,
	is_spell=true,
	cooldown = function(self,t)
		return 13+math.floor(getEyeDelay(self))
	end,
	tactical = { ATTACK = { DARK = 2 } },
	range = function(self, t) return math.floor(combatTalentScale(self,t, 5, 9)) end,
	direct_hit = true,
	reflectable = true,
	requires_target = true,
	target = function(self, t)
		local tg = {type="beam", range=self:getTalentRange(t), talent=t}

		return tg
	end,
	getDamage = function(self, t) return self:combatTalentSpellDamage(t, 40, 350) end,
	on_pre_use = function(self, t, silent) if self:hasEffect(self.EFF_BLINDED) then if not silent  then game.logPlayer(self, "You cannot use your eyestalks while blind!") end  return false end return true end,
	action = function(self, t)
		local tg = self:getTalentTarget(t)
		local x, y = self:getTarget(tg)
		local critboost = 0
		if self:knowTalent(self.T_DARKNESS_FOCUS) then
			local r = self:getTalentFromId(self.T_DARKNESS_FOCUS)
			critboost = r.getBonusCrit(self,r)
		end

		self.combat_spellcrit = self.combat_spellcrit + critboost
		local final_damage = self:spellCrit(t.getDamage(self, t))
		self.combat_spellcrit = self.combat_spellcrit - critboost
		if not x or not y then return nil end
		local grids = nil

		grids = self:project(tg, x, y, DamageType.DARKNESS, final_damage/4)
		self:project(tg, x, y, DamageType.ARCANE, final_damage*3/4)
		local _ _, x, y = self:canProject(tg, x, y)

		game.level.map:particleEmitter(self.x, self.y, tg.radius, "dark_torrent", {tx=x-self.x, ty=y-self.y})

		if self:knowTalent(self.T_BEHOLDER_DISINTEGRATE) then
			local z = self:getTalentFromId(self.T_BEHOLDER_DISINTEGRATE)
			local killper = z.getKillChance(self,z)
			for x, yy in pairs(grids) do
				for y, _ in pairs(grids[x]) do
					local a = game.level.map(x, y, Map.ACTOR)
					if a and a:canBe("instakill") then
						if rng.percent(killper) then
							if not a.dead then a:die(self) end
						end
						--a:setEffect(a.EFF_BURNING, 4, {src=self, power=final_damage * burnper/400, no_ct_effect=true})
						--tgts[#tgts+1] = a
					end
				end
			end
		end
		game:playSoundNear(self, "talents/fire")
		--self:setEffect(self.EFF_DRAINED_EYESTALKS, 10, {power=1})
		return true
	end,
	info = function(self, t)
		local damage = t.getDamage(self, t)
		return ([[Launches a beam of darkness from your eyestalks, doing %0.2f darkness damage and %0.2f arcane damage.
		The range will increase with your talent level and damage will increase with your Spellpower.]]):
		format(damDesc(self, DamageType.DARKNESS, damage/4),damDesc(self, DamageType.ARCANE, damage*3/4))
	end,
}

newTalent{
	name = "Darkness Focus",
	type = {"spell/death-eye",2},
	require =  Talents.main_env.spells_req_high2,
	points = 5,
	mode = "passive",
	getBonusCrit = function(self, t) return  math.floor(combatTalentScale(self,t, 2.5, 12.5)) end,
	info = function(self, t)
		local crit = t.getBonusCrit(self, t)
		return ([[Increases your critical chance with your death ray eyestalk by %d%%.]]):
		format(crit)
	end,
}

newTalent{
	short_name="BEHOLDER_DISINTEGRATE",
	name = "Disintegrate",
	type = {"spell/death-eye",3},
	require =  Talents.main_env.spells_req_high3,
	points = 5,
	mode = "passive",
	getKillChance = function(self, t) return  math.floor(combatTalentScale(self,t, 10, 50)) end,
	info = function(self, t)
		local kill = t.getKillChance(self, t)
		return ([[Causes your Death Ray to have a %d%% percent chance of killing targets outright, if they are susceptible to instant death spells.]]):
		format(kill)
	end,
}

newTalent{
	name = "Death Mastery",
	type = {"spell/death-eye",4},
	require = Talents.main_env.spells_req_high4,
	points = 5,
	mode = "sustained",
	sustain_mana = 50,
	cooldown = 30,
	is_spell=true,
	tactical = { BUFF = 2 },
	getDarknessDamageIncrease = function(self, t) return self:getTalentLevelRaw(t) * 2 end,
	getResistPenalty = function(self, t) return combatTalentLimit(self,t, 100, 17, 50, true) end,  -- Limit to < 100%
	--getAffinity = function(self, t) return self:combatTalentLimit(t, 100, 10, 50) end, -- Limit < 100%
	on_pre_use = function(self, t, silent)
		local cnt = 0
		if self:isTalentActive(self.T_FROST_MASTERY) then
		cnt = cnt+1
		end
		if self:isTalentActive(self.T_FIRE_MASTERY) then
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
			dam = self:addTemporaryValue("inc_damage", {[DamageType.DARKNESS] = t.getDarknessDamageIncrease(self, t)}),
			resist = self:addTemporaryValue("resists_pen", {[DamageType.DARKNESS] = t.getResistPenalty(self, t)}),
			dam2 = self:addTemporaryValue("inc_damage", {[DamageType.ARCANE] = t.getDarknessDamageIncrease(self, t)}),
			resist2 = self:addTemporaryValue("resists_pen", {[DamageType.ARCANE] = t.getResistPenalty(self, t)}),
			--affinity = self:addTemporaryValue("damage_affinity", {[DamageType.FIRE] = t.getAffinity(self, t)}),
			particle = self:addParticles(Particles.new("ultrashield", 1, {rm=10, rM=100, gm=0, gM=0, bm=0, bM=0, am=70, aM=180, radius=0.4, density=10, life=14, instop=20})),
		}
	end,
	deactivate = function(self, t, p)
		self:removeTemporaryValue("inc_damage", p.dam)
		self:removeTemporaryValue("resists_pen", p.resist)
		self:removeTemporaryValue("inc_damage", p.dam2)
		self:removeTemporaryValue("resists_pen", p.resist2)
		self:removeParticles(p.particle)--self:removeTemporaryValue("damage_affinity", p.affinity)
		return true
	end,
	info = function(self, t)
		local damageinc = t.getDarknessDamageIncrease(self, t)
		local ressistpen = t.getResistPenalty(self, t)
		--local affinity = t.getAffinity(self, t)
		return ([[Focus your death eyestalk, increasing all your darkness/arcane damage by %d%%, and ignoring %d%% of the darkness/arcane resistance of your targets.
		Only two masteries may be active at once.]])
		:format(damageinc, ressistpen)
	end,
}
