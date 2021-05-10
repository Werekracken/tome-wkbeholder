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
	name = "Frost Laser",
	type = {"spell/frost-eye",1},
	require =  Talents.main_env.spells_req1,
	points = 5,
	random_ego = "attack",
	mana = 8,
	is_spell=true,
	cooldown = function(self,t)
		return 6+math.floor(getEyeDelay(self))
	end,
	tactical = { ATTACK = { COLD = 2 } },
	range = function(self, t) return math.floor(combatTalentScale(self,t, 5, 9)) end,
	direct_hit = true,
	reflectable = true,
	requires_target = true,
	on_pre_use = function(self, t, silent) if self:hasEffect(self.EFF_BLINDED) then if not silent  then game.logPlayer(self, "You cannot use your eyestalks while blind!") end  return false end return true end,
	target = function(self, t)
		local tg = {type="bolt", range=self:getTalentRange(t), talent=t}
		if self:knowTalent(self.T_FROST_FOCUS) then tg.type = "beam" end
		return tg
	end,
	getDamage = function(self, t) return self:combatTalentSpellDamage(t, 20, 200) end,
	action = function(self, t)
		local tg = self:getTalentTarget(t)
		local x, y = self:getTarget(tg)
		local critboost = 0
		local extra_hits = 0
		if self:knowTalent(self.T_FROST_FOCUS) then
			local r = self:getTalentFromId(self.T_FROST_FOCUS)
			critboost = r.getBonusCrit(self,r)
			extra_hits = r.getTargetCount(self,r)
		end

		self.combat_spellcrit = self.combat_spellcrit + critboost
		local final_damage = self:spellCrit(t.getDamage(self, t))
		self.combat_spellcrit = self.combat_spellcrit - critboost

		local freezeper =0
		local spower =0

		if self:knowTalent(self.T_FREEZE_RAY) then
			local z = self:getTalentFromId(self.T_FREEZE_RAY)
			freezeper = z.getFreezeper(self,z)
			spower = self:combatSpellpower() * freezeper/100
		end
		if not x or not y then return nil end
		local grids = nil
		if extra_hits == 0 then
		grids = self:project(tg, x, y, DamageType.COLD, final_damage)
		else
		local targets = {}
		self:project(tg, x, y, function(bx, by)
						local actor2 = game.level.map(bx, by, Map.ACTOR)
						if actor2 then
							print(actor2.name)
							local dist =math.sqrt((bx-self.x)^2 +(by-self.y)^2)
							print(dist)
							table.insert(targets,dist,{x=bx,y=by})
						end
					end)
		local hit_count = 1
		print("start")
		print(extra_hits+1)
		--table.sort(targets)

		table.foreach(targets,function (index, value)
				print(hit_count)
				local bx=value.x
				local by=value.y
				local actor2 = game.level.map(bx, by, Map.ACTOR)
				print(actor2)
					if actor2 and hit_count<=extra_hits+1 then
						print(actor2.name)
						print(hit_count)
						local dam_inst = final_damage * (1+extra_hits-hit_count)/(extra_hits) * .75 + .25*final_damage
						print (dam_inst)
						DamageType.defaultProjector(self, bx, by, DamageType.COLD, dam_inst)
						hit_count=hit_count+1

						if freezeper>0 then
							actor2:setEffect(actor2.EFF_FROZEN, freezeper/15, {hp=dam_inst * 1.5, apply_power=spower, min_dur=1})
						end
					end
			end)

			-- for i, v in ipairs(targets) do
				-- print(hit_count)
				-- local bx=v.x
				-- local by=v.y
				-- local actor2 = game.level.map(bx, by, Map.ACTOR)
				-- print(actor2)
					-- if actor2 and hit_count<=extra_hits+1 then
						-- print(actor2.name)
						-- print(hit_count)
						-- local dam_inst = final_damage * (1+extra_hits-hit_count)/(extra_hits) * .75 + .25*final_damage
						-- print (dam_inst)
						-- DamageType.defaultProjector(self, bx, by, DamageType.COLD, dam_inst)
						-- hit_count=hit_count+1

						-- if freezeper>0 then
							-- actor2:setEffect(actor2.EFF_FROZEN, freezeper/15, {hp=dam_inst * 1.5, apply_power=spower, min_dur=1})
						-- end
					-- end
			-- end

		end
		local _ _, x, y = self:canProject(tg, x, y)

		game.level.map:particleEmitter(self.x, self.y, tg.radius, "frostlaser", {tx=x-self.x, ty=y-self.y})

		-- if self:knowTalent(self.T_FREEZE_RAY) then
			-- local z = self:getTalentFromId(self.T_FREEZE_RAY)
			-- local freezeper = z.getFreezeper(self,z)
			-- local spower = self:combatSpellpower() * freezeper/100
			-- for x, yy in pairs(grids) do
				-- for y, _ in pairs(grids[x]) do
					-- local a = game.level.map(x, y, Map.ACTOR)
					-- if a then
						-- a:setEffect(a.EFF_FROZEN, freezeper/15, {hp=final_damage * 1.5, apply_power=spower, min_dur=1})
						-- --tgts[#tgts+1] = a
					-- end
				-- end
			-- end
		-- end

		game:playSoundNear(self, "talents/ice")
		--self:setEffect(self.EFF_DRAINED_EYESTALKS, 10, {power=1})
		return true
	end,
	info = function(self, t)
		local damage = t.getDamage(self, t)
		return ([[Launches a bolt of frost from your eyestalks, doing %0.2f cold damage.
		The range will increase with your talent level and damage will increase with your Spellpower.]]):
		format(damDesc(self, DamageType.COLD, damage))
	end,
}

newTalent{
	name = "Frost Focus",
	type = {"spell/frost-eye",2},
	require =  Talents.main_env.spells_req2,
	points = 5,
	mode = "passive",
	getTargetCount = function(self, t) return 1 + self:getTalentLevelRaw(t) end,
	getBonusCrit = function(self, t) return  math.floor(combatTalentScale(self,t, 2.5, 12.5)) end,
	info = function(self, t)
		local crit = t.getBonusCrit(self, t)
		local tar = t.getTargetCount(self, t)
		return ([[Increases your critical chance with your frost eyestalk by %d%%.
		Causes your Frost Laser to fire a beam which will penetrate up to %d additional targets, but will decrease in power as it does so.]]):
		format(crit,tar)
	end,
}

newTalent{
	name = "Freeze Ray",
	type = {"spell/frost-eye",3},
	require =  Talents.main_env.spells_req3,
	points = 5,
	mode = "passive",
	getFreezeper = function(self, t) return  math.floor(combatTalentScale(self,t, 30, 100)) end,
	info = function(self, t)
		local dur = t.getFreezeper(self, t)/15
		return ([[Causes your Frost Laser to freeze enemies for up to %d turns. Freeze chance increases with talent level and your Spellpower.]]):format(dur)
	end,
}

newTalent{
	name = "Frost Mastery",
	type = {"spell/frost-eye",4},
	require = Talents.main_env.spells_req4,
	points = 5,
	is_spell=true,
	mode = "sustained",
	sustain_mana = 50,
	cooldown = 30,
	tactical = { BUFF = 2 },
	getDarknessDamageIncrease = function(self, t) return self:getTalentLevelRaw(t) * 2 end,
	getResistPenalty = function(self, t) return combatTalentLimit(self,t, 100, 17, 50, true) end,  -- Limit to < 100%
	on_pre_use = function(self, t, silent)
		local cnt = 0
		if self:isTalentActive(self.T_FIRE_MASTERY) then
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
			dam = self:addTemporaryValue("inc_damage", {[DamageType.COLD] = t.getDarknessDamageIncrease(self, t)}),
			resist = self:addTemporaryValue("resists_pen", {[DamageType.COLD] = t.getResistPenalty(self, t)}),

			particle = self:addParticles(Particles.new("ultrashield", 1, {rm=10, rM=100, gm=0, gM=0, bm=0, bM=0, am=70, aM=180, radius=0.4, density=10, life=14, instop=20})),
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
		return ([[Focus your frost eyestalk, increasing all your cold damage by %d%%, and ignoring %d%% of the cold resistance of your targets.
		Only two masteries may be active at once.]])
		:format(damageinc, ressistpen)
	end,
}
