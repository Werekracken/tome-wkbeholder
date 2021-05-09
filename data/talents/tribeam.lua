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
	name = "Invigorate Eyestalks", short_name = "BEHOLDER_INVIGORATE",
	type = {"spell/tri-beam", 1},
	require = Talents.main_env.spells_req_high1,
	points = 5,
	mana = 0,
	cooldown = function(self, t) return math.ceil(self:combatTalentLimit(t, 10, 45, 25, true)) end,
	is_spell=true,
	getPower = function(self, t) return 5 + self:combatTalentSpellDamage(t, 5, 10) end,
	getSpellPowerBoost = function(self, t) return self:combatScale(self:combatSpellpower(), 10, 0, 16, 40)*self:combatTalentScale(t, 0.5, 1, 0.6) end,
	getCentralEyeCooldown = function(self, t) return math.max(4, 20-math.floor(self:combatScale(self:getTalentLevel(t), 0, 1.3, 12, 5))) end,
	is_heal = true,
	on_pre_use = function(self, t, silent)
	if self:hasEffect(self.EFF_DRAINED_CENTRAL_EYE) then
		if not silent  then
			game.logPlayer(self, "Your central eye is too drained to use this power!")
		end
		return false
	end
	if self.talents_cd[self.T_FLAME_LASER] or self.talents_cd[self.T_FROST_LASER] or self.talents_cd[self.T_LIGHTING_LASER] or self.talents_cd[self.T_DEATH_RAY] then
		return true
	else
		if not silent  then
			game.logPlayer(self, "You can only use this if your eyestalks are on cooldown!")
		end
		return false
	end
	return false end,
	action = function(self, t)
		-- local current_effect = self:hasEffect(self.EFF_DRAINED_EYESTALKS)

		local spower = t.getSpellPowerBoost(self, t)
		local power = t.getPower(self, t)
		-- if current_effect.power <= power then
		-- 	self:removeEffect(self.EFF_DRAINED_EYESTALKS)
		-- else
		-- 	power=current_effect.power-power
		-- 	local dur = current_effect.dur
		-- 	self:removeEffect(self.EFF_DRAINED_EYESTALKS)
		-- 	self:setEffect(self.EFF_DRAINED_EYESTALKS, dur, {power=power})
		-- end
		if self.talents_cd[self.T_FLAME_LASER] then
			self.talents_cd[self.T_FLAME_LASER]=nil
		end
		if self.talents_cd[self.T_FROST_LASER] then
			self.talents_cd[self.T_FROST_LASER]=nil
		end
		if self.talents_cd[self.T_DEATH_RAY] then
			self.talents_cd[self.T_DEATH_RAY]=nil
		end
		if self.talents_cd[self.T_LIGHTNING_LASER] then
			self.talents_cd[self.T_LIGHTNING_LASER]=nil
		end
		local boost = 0
		if self:knowTalent(self.T_BEHOLDER_FOCUS) then
			local r = self:getTalentFromId(self.T_BEHOLDER_FOCUS)
			boost = r.get_bonus_crit(self,r)
		end
		local spellpowerboost=self.level
		self:setEffect(self.EFF_DRAINED_CENTRAL_EYE, 20, {power=1,boost=boost}) --,spower=spellpowerboost})
		-- self:setEffect(self.EFF_EMPOWERED_MAGIC, 10, {power=spower})
		return true
	end,
	info = function(self, t)
		local power = t.getPower(self, t)
		local spower = t.getSpellPowerBoost(self, t)
		local central_eye_cooldown = t.getCentralEyeCooldown(self, t)
		return ([[Use the power of your central eye to restore all of your eyestalks from cooldown. Using this talent will render your central eye unusable for %d turns.

			Also, when your central eye is closed, your spellpower is now boosted by %d.

		The amount of fatigue reduced will increase with your Spellpower.]]):
		format(central_eye_cooldown, spower)
	end,
}

newTalent{
	name = "Restore", short_name = "BEHOLDER_HEAL",
	type = {"spell/tri-beam", 2},
	require = Talents.main_env.spells_req_high2,
	points = 5,
	mana = 25,
	is_spell=true,
	cooldown = 16,
	tactical = { HEAL = 2 },
	getHeal = function(self, t) return 40 + self:combatTalentSpellDamage(t, 10, 520) end,
	is_heal = true,
	on_pre_use = function(self, t, silent)
	if self:hasEffect(self.EFF_DRAINED_CENTRAL_EYE) then
		if not silent  then
			game.logPlayer(self, "Your central eye is too drained to use this power!")
		end
		return false
	end
	if self:hasEffect(self.EFF_BLINDED) then
		if not silent  then
			game.logPlayer(self, "You cannot use your central eye while blind!")
		end
		return false
	end
	return true end,
	action = function(self, t)
		self:attr("allow_on_heal", 1)
		self:heal(self:spellCrit(t.getHeal(self, t)), self)
		self:attr("allow_on_heal", -1)
		game:playSoundNear(self, "talents/heal")
		self:setEffect(self.EFF_REGENERATION, 5, {power=5 + self:getMag() * 0.5})
		local boost = 0
		if self:knowTalent(self.T_BEHOLDER_FOCUS) then
			local r = self:getTalentFromId(self.T_BEHOLDER_FOCUS)
			boost = r.get_bonus_crit(self,r)
		end
		local spellpowerboost=self.level
		self:setEffect(self.EFF_DRAINED_CENTRAL_EYE, 5, {power=1,boost=boost,spower=spellpowerboost})
		return true
	end,
	info = function(self, t)
		local heal = t.getHeal(self, t)
		return ([[Uses the power of your central eye to heal you for %d life.
		Also grants a regeneration effect for %d life every turn for 5 turns as you focus your central eye's healing energies inward.
		The life healed will increase with your Spellpower.]]):
		format(heal,5 + self:getMag() * 0.5)
	end,
}

newTalent{
	name = "Magical Permeation",
	type = {"spell/tri-beam", 3},
	require = Talents.main_env.spells_req_high3,
	points = 5,
	mode = "passive",
	on_learn = function(self, t)
		self:attr("stun_immune", 0.05)
		self:attr("pin_immune", 0.05)
		self:attr("knockback_immune", 0.05)
		self:attr("combat_crit_reduction", 4)
	end,
	on_unlearn = function(self, t)
		self:attr("stun_immune", -0.05)
		self:attr("pin_immune", -0.05)
		self:attr("knockback_immune", -0.05)
		self:attr("combat_crit_reduction", -4)
	end,
	info = function(self, t)
		return ([[The magical forces flowing through your body make you more resistant to physical effects.
		Increase stun immunity by %d%%, pin immunity by %d%%, knockback immunity by %d%%, and reduces chance to be critically hit by %d%%.]]):
		format(self:getTalentLevelRaw(t) * 5,self:getTalentLevelRaw(t) * 5,self:getTalentLevelRaw(t) * 5,self:getTalentLevelRaw(t) * 4)
	end,
}

newTalent{
	name = "Tri Laser",
	type = {"spell/tri-beam",4},
	require =  Talents.main_env.spells_req_high4,
	points = 5,
	is_spell=true,
	random_ego = "attack",
	mana = 50,
	cooldown = function(self,t)
		return 30 - self:getTalentLevel(t) * 3
	end,
	tactical = { ATTACK = { FIRE = 2,COLD = 2,LIGHTNING = 2 } },
	range = function(self, t) return math.floor(combatTalentScale(self,t, 5, 9)) end,
	arcane_radius = function(self, t) return 2 + math.floor(self:getTalentLevel(t)/3) end,
	direct_hit = true,
	reflectable = true,
	requires_target = true,
	target = function(self, t)
		local tg = {type="beam", range=self:getTalentRange(t), talent=t}
		return tg
	end,
	getDamage = function(self, t) return self:combatTalentSpellDamage(t, 40, 400) end,
	on_pre_use = function(self, t, silent)
	if self:hasEffect(self.EFF_DRAINED_CENTRAL_EYE) then
		if not silent  then
			game.logPlayer(self, "Your central eye is too drained to use this power!")
		end
		return false
	end
	if self:hasEffect(self.EFF_BLINDED) then
		if not silent  then
			game.logPlayer(self, "You cannot use your central eye while blind!")
		end
		return false
	end
	return true end,
	action = function(self, t)
		local tg = self:getTalentTarget(t)
		local x, y = self:getTarget(tg)
		local critboostfire = 0
		local critboostfrost = 0
		local critboostlightning = 0
		local damagefire =1
		local damagefrost =1
		local damagelightning =1
		local splash = t.getDamage(self,t)

		if self:knowTalent(self.T_FIRE_FOCUS) then
			local r = self:getTalentFromId(self.T_FIRE_FOCUS)
			critboostfire = r.getBonusCrit(self,r)
		end
		if self:knowTalent(self.T_FROST_FOCUS) then
			local r = self:getTalentFromId(self.T_FROST_FOCUS)
			critboostfrost = r.getBonusCrit(self,r)
		end
		if self:knowTalent(self.T_LIGHTNING_FOCUS) then
			local r = self:getTalentFromId(self.T_LIGHTNING_FOCUS)
			critboostlightning = r.getBonusCrit(self,r)
		end

		if self:knowTalent(self.T_FLAME_LASER) then
			local r = self:getTalentFromId(self.T_FLAME_LASER)
			damagefire = r.getDamage(self,r)*3/4
			self.combat_spellcrit = self.combat_spellcrit + critboostfire
			damagefire = self:spellCrit(damagefire)
			self.combat_spellcrit = self.combat_spellcrit - critboostfire
		end

		if self:knowTalent(self.T_FROST_LASER) then
			local r = self:getTalentFromId(self.T_FROST_LASER)
			damagefrost = r.getDamage(self,r)*3/4
			self.combat_spellcrit = self.combat_spellcrit + critboostfrost
			damagefrost = self:spellCrit(damagefrost)
			self.combat_spellcrit = self.combat_spellcrit - critboostfrost
		end

		if self:knowTalent(self.T_LIGHTNING_LASER) then
			local r = self:getTalentFromId(self.T_LIGHTNING_LASER)
			damagelightning = r.getDamage(self,r)*3/4
			self.combat_spellcrit = self.combat_spellcrit + critboostlightning
			damagelightning = self:spellCrit(damagelightning)
			self.combat_spellcrit = self.combat_spellcrit - critboostlightning
		end

		if not x or not y then return nil end
		local primary_target = game.level.map(x, y, Map.ACTOR)
		local grids = nil
		--print(primary_target.name)
		--print(primary_target.dead)
		self:project(tg, x, y, DamageType.FIRE, damagefire)
		self:project(tg, x, y, DamageType.COLD, damagefrost)
		self:project(tg, x, y, DamageType.LIGHTNING, damagelightning)
		--print(primary_target.dead)
		if primary_target and primary_target.dead then
			--print("test")
			local tgball = {type="ball", range=0, selffire=false, friendlyfire=0, radius=t.arcane_radius(self,t), talent=t}
			self:project(tgball, primary_target.x, primary_target.y, DamageType.ARCANE, self:spellCrit(splash))
			game.level.map:particleEmitter(primary_target.x, primary_target.y, tgball.radius, "ball_arcane", {radius=tgball.radius, tx=primary_target.x, ty=primary_target.y})
		end

		game.level.map:particleEmitter(self.x, self.y, tg.radius, "tribeam", {tx=x-self.x, ty=y-self.y})


		game:playSoundNear(self, "talents/fire")
		local boost = 0
		if self:knowTalent(self.T_BEHOLDER_FOCUS) then
			local r = self:getTalentFromId(self.T_BEHOLDER_FOCUS)
			boost = r.get_bonus_crit(self,r)
		end
		local spellpowerboost=self.level
		self:setEffect(self.EFF_DRAINED_CENTRAL_EYE, 8, {power=1,boost=boost,spower=spellpowerboost})
		return true
	end,
	info = function(self, t)
		local damagefire =1
		local damagefrost =1
		local damagelightning =1
		if self:knowTalent(self.T_FLAME_LASER) then
			local r = self:getTalentFromId(self.T_FLAME_LASER)
			damagefire = r.getDamage(self,r)*3/4

		end

		if self:knowTalent(self.T_FROST_LASER) then
			local r = self:getTalentFromId(self.T_FROST_LASER)
			damagefrost = r.getDamage(self,r)*3/4

		end

		if self:knowTalent(self.T_LIGHTNING_LASER) then
			local r = self:getTalentFromId(self.T_LIGHTNING_LASER)
			damagelightning = r.getDamage(self,r)*3/4

		end
		local damage = t.getDamage(self, t)
		local radius = t.arcane_radius(self, t)
		return ([[Using your central eye's power reserves, fires all three of your elemental eyestalks at your target.
		This talent will cause %d fire, %d cold, and %d lightning damage in a beam and if the primary target is killed will cause an explosion of %d arcane damage within radius %d.
		Using this talent will render your central eye unusable for 8 turns.
		The range will increase with your talent level and the explosion will increase in radius and power with your Spellpower.]]):
		format(damDesc(self, DamageType.FIRE, damagefire),damDesc(self, DamageType.COLD, damagefrost),damDesc(self, DamageType.LIGHTNING, damagelightning),damDesc(self, DamageType.ARCANE, damage),radius)
	end,
}
