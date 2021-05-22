function getTentacle(self)
	local combat = {
		talented = "tentacle",
		sound = {"actions/melee", pitch=0.6, vol=1.2}, sound_miss = {"actions/melee", pitch=0.6, vol=1.2},
		name = "Tentacles",
		wil_attack = true,
		damrange = 1.5,
		physspeed = 1,
		dam = 14,
		apr = 0,
		atk = 0,
		physcrit = 0,
		dammod = {mag=.3,wil=.3},
		melee_project = {},
		burst_on_crit = {},
		burst_on_hit = {},
	}
	 if self:knowTalent(self.T_TENTACLE_MASTERY) then
		 local t = self:getTalentFromId(self.T_TENTACLE_MASTERY)
		 combat.dam = combat.dam + t.getBaseDamage(self, t)
		 combat.apr = combat.apr + t.getBaseApr(self, t)
		 combat.physcrit = combat.physcrit + t.getBaseCrit(self, t)
		 combat.atk = combat.atk + t.getBaseAtk(self, t)
	 end
	if self:knowTalent(self.T_GRASPING_TENTACLE) then
		local t = self:getTalentFromId(self.T_GRASPING_TENTACLE)
		combat.atk = combat.atk+ t.getAttack(self, t)
	end
	if self:knowTalent(self.T_SPIKED_TENTACLES) then
		local t = self:getTalentFromId(self.T_SPIKED_TENTACLES)
		combat.melee_project = { [DamageType.PHYSICAL] = t.getProject(self, t) }
	end
	if self:knowTalent(self.T_CHANNEL_MASTERY) then
		local t = self:getTalentFromId(self.T_CHANNEL_MASTERY)
		local possible_types = {}
		local cnt =0
		table.insert(possible_types,DamageType.PHYSICAL)
		cnt=cnt+1

		if self:isTalentActive(self.T_FROST_MASTERY) then
			table.insert(possible_types,DamageType.COLD)
			cnt=cnt+1
		end
		if self:isTalentActive(self.T_DEATH_MASTERY) then
			table.insert(possible_types,DamageType.DARKNESS)
			cnt=cnt+1
		end
		if self:isTalentActive(self.T_FIRE_MASTERY) then
			table.insert(possible_types,DamageType.FIRE)
			cnt=cnt+1
		end
		if self:isTalentActive(self.T_LIGHTNING_MASTERY) then
			table.insert(possible_types,DamageType.LIGHTNING)
			cnt=cnt+1
		end

		if cnt>0 then
			combat.burst_on_hit = { [rng.table(possible_types)] = t.getDamage(self, t) }
			combat.burst_on_crit = { [rng.table(possible_types)] = t.getDamageCrit(self, t) }
		end
	end
	return combat
end

newTalent{
	name = "Use Tentacles",
	type = {"race/beholder-other", 1},
	points = 1,
	mode = "sustained",
	cooldown = 0,
	--sustain_psi = 0,
	range = 1,
	direct_hit = true,
	no_energy = true,
	no_unlearn_last = true,
	tactical = { BUFF = 3 },
	do_tkautoattack = function(self, t)
		if game.zone.wilderness then return end

		local targnum = 1
		if self:hasEffect(self.EFF_PSIFRENZY) then targnum = 1 + math.ceil(0.2*self:getTalentLevel(self.T_FRENZIED_PSIFIGHTING)) end
		local speed, hit = nil, false
		local sound, sound_miss = nil, nil
		--dam = self:getTalentLevel(t)
		local tgts = {}
		local grids = core.fov.circle_grids(self.x, self.y, 1, true)
		for x, yy in pairs(grids) do for y, _ in pairs(grids[x]) do
			local a = game.level.map(x, y, Map.ACTOR)
			if a and self:reactionToward(a) < 0 and not a:hasEffect(a.EFF_DAZED)and not a:hasEffect(a.EFF_SLEEP) then
				tgts[#tgts+1] = a
			end
		end end

		-- Randomly pick a target
		local tg = {type="hit", range=1, talent=t}
		for i = 1, targnum do
			if #tgts <= 0 then break end
			local a, id = rng.table(tgts)
			table.remove(tgts, id)
			local weapon = getTentacle(self)

			print("[TENTACLE ATTACK] attacking with Tentacle Slap")
			--self.use_psi_combat = true
			local s, h = self:attackTargetWith(a, weapon, nil, 1)
			--self.use_psi_combat = false
			speed = math.max(speed or 0, s)
			hit = hit or h
			if hit and not sound then sound = weapon.sound
			elseif not hit and not sound_miss then sound_miss = weapon.sound_miss end
			if not weapon.no_stealth_break then break_stealth = true end
			self:breakStepUp()

		end
		return hit
	end,
	activate = function (self, t)
		return true
	end,
	deactivate =  function (self, t)
		return true
	end,
	info = function(self, t)
		local weapon_damage = getTentacle(self).dam
		local weapon_range = getTentacle(self).dam * getTentacle(self).damrange
		local weapon_atk = getTentacle(self).atk
		local weapon_apr = getTentacle(self).apr
		local weapon_crit = getTentacle(self).physcrit
		return ([[You passively strike a foe each turn if able. This attack will avoid hitting dazed or sleeping targets.]]):format()
	end,
}

newTalent{
	name = "Tentacle Mastery",
	type = {"technique/tentacle-combat", 1},
	points = 5,
	require = { stat = { wil=function(level) return 12 + level * 6 end,mag=function(level) return 12 + level * 6 end }, },
	mode = "passive",
--	no_unlearn_last = true,
	getBaseDamage = function(self, t) return self:combatTalentSpellDamage(t, 0, 40) end,
	getBaseAtk = function(self, t) return self:combatTalentSpellDamage(t, 0, 15) end,
	getBaseApr = function(self, t) return self:combatTalentSpellDamage(t, 0, 15) end,
	getBaseCrit = function(self, t) return self:combatTalentSpellDamage(t, 0, 15) end,
	getDamage = function(self, t) return self:getTalentLevel(t) * 10 end,
	getPercentInc = function(self, t) return math.sqrt(self:getTalentLevel(t) / 5) / 2 end,
	on_learn = function(self, t)
		self:learnTalent(self.T_USE_TENTACLES, true, nil, {no_unlearn=true})
	end,
	on_unlearn = function(self, t)
		self:unlearnTalent(self.T_USE_TENTACLES)
	end,
	info = function(self, t)
		local damage = t.getDamage(self, t)
		local inc = t.getPercentInc(self, t)
		local weapon_damage = getTentacle(self).dam
		local weapon_range = getTentacle(self).dam * getTentacle(self).damrange
		local weapon_atk = getTentacle(self).atk
		local weapon_apr = getTentacle(self).apr
		local weapon_crit = getTentacle(self).physcrit
		return ([[You passively use a tentacle to strike a foe each turn if able. This attack will avoid hitting dazed or sleeping targets.
		Increases Physical Power by %d, and increases weapon damage by %d%% when using your tentacles.
		The base power, Accuracy, Armour penetration, and critical strike chance of the weapon will scale with your Spellpower.

		Current Tentacle Slap Stats
		Base Power: %0.2f - %0.2f
		Uses Stats: 30%% Mag, 30%% Wil
		Damage Type: Physical
		Accuracy is based on willpower for this weapon.
		Accuracy Bonus: +%d
		Armour Penetration: +%d
		Physical Crit. Chance: +%d]]):
		format(damage, 100*inc, weapon_damage, weapon_range, weapon_atk, weapon_apr, weapon_crit)
	end,
}

newTalent{
	name = "Grasping Tentacle",
	type = {"technique/tentacle-combat", 2},
	points = 5,
	range = function(self, t) return math.ceil(1.5+self:getTalentLevel(t)*0.5) end,
	stamina = 20,
	cooldown = 20,
	requires_target = true,
	tactical = { ATTACK = { weapon = 2 }, DISABLE = { disarm = 2 } },
	require = { stat = { wil=function(level) return 18 + level * 2 end,mag=function(level) return 18 + level * 2 end }, },
	getDamage = function(self, t) return self:combatTalentWeaponDamage(t, .7, 1.5) end,
	getDuration = function(self, t) return math.floor(combatTalentScale(self,t, 2, 6)) end,
	getAttack = function(self, t) return self:getTalentLevel(t) * 10 end,
	action = function(self, t)
		local tg = {type="hit", range=self:getTalentRange(t)}
		local x, y, target = self:getTarget(tg)
		if not x or not target then return nil end
		if core.fov.distance(self.x, self.y, x, y) > self:getTalentRange(t) then return nil end
		--local speed, hit = self:attackTargetWith(target, getTentacle(self), nil, t.getDamage(self, t))
		--precheck for polish (to allow pull animations on slain enemies)
		local hit = true
		if not self:checkHit(getTentacle(self).atk, target:combatDefense()) or target:checkEvasion(self) then
			hit = false
		end
		if hit then
			if target:canBe("disarm") then
				target:setEffect(target.EFF_DISARMED, t.getDuration(self, t), {apply_power=getTentacle(self).atk})
			else
				game.logSeen(target, "%s resists the disarm!", target.name:capitalize())
			end
			target:pull(self.x, self.y, tg.range)
			local acc_id = self:addTemporaryValue("combat_atk", 100)
			local speed, hit = self:attackTargetWith(target, getTentacle(self), nil, t.getDamage(self, t))
			self:removeTemporaryValue("combat_atk", acc_id)
		end
		return true
	end,
	info = function(self, t)
		local duration = t.getDuration(self, t)
		local damage = t.getDamage(self, t)
		local attack = t.getAttack(self, t)
		local range = self:getTalentRange(t)
		return ([[Strike and disarm your target from up to %d squares away for %d%% tentacle damage and a disarm duration of %d turns. If the attack hits, you attempt to drag your neutralized target next to you.

		Disarm chance increases with your accuracy.
		Learning this talent increases your accuracy with your tentacles by %d.]]):format(range, damage* 100,duration,attack)
	end,
}

newTalent{
	name = "Spiny Tentacle",
	short_name = "SPIKED_TENTACLES",
	type = {"technique/tentacle-combat", 3},
	points = 5,
	range = function(self, t) return math.ceil(1.5+self:getTalentLevel(t)*0.5) end,
	stamina = 20,
	cooldown = 15,
	requires_target = true,
	tactical = { ATTACK = { weapon = 2 }, DISABLE = { poison = 2 } },
	require = { stat = { wil=function(level) return 24 + level * 2 end,mag=function(level) return 24 + level * 2 end }, },
	getDamage = function(self, t) return self:combatTalentWeaponDamage(t, .7, 1.5) end,
	getProject = function(self, t) return self:combatTalentSpellDamage(t, 10, 50) end,
	getPosionDamage = function(self,t) return self:spellCrit(self:combatTalentSpellDamage(t, 10, 150)) end,
	getPosionEffect = function(self,t) return combatTalentLimit(self,t, 100, 24, 40) end,
	action = function(self, t)
		local tg = {type="hit", range=self:getTalentRange(t)}
		local x, y, target = self:getTarget(tg)
		if not x or not target then return nil end
		if core.fov.distance(self.x, self.y, x, y) > self:getTalentRange(t) then return nil end

		local block_actor = function(_, bx, by) return game.level.map:checkEntity(bx, by, Map.TERRAIN, "block_move", self) end
		local linestep = self:lineFOV(x, y, block_actor)

		local lx, ly, tx, ty, is_corner_blocked = self.x, self.y
		repeat  -- make sure each tile is passable
			tx, ty = lx, ly
			lx, ly, is_corner_blocked = linestep:step()
		until is_corner_blocked or not lx or not ly or game.level.map:checkAllEntities(lx, ly, "block_move", self)
		if not tx or not ty or core.fov.distance(x, y, tx, ty) >= 2 then return nil end

		local speed, hit = self:attackTargetWith(target, getTentacle(self), nil, t.getDamage(self, t))
		if hit then
			local ox, oy = self.x, self.y
			self:move(tx, ty, true)
			if config.settings.tome.smooth_move > 0 then
				self:resetMoveAnim()
				self:setMoveAnim(ox, oy, 8, 5)
			end
			if target:canBe("poison") then
				target:setEffect(target.EFF_INSIDIOUS_POISON,6, {src=self,power=t.getPosionDamage(self, t)/6,heal_factor =t.getPosionEffect(self, t) })
			else
				game.logSeen(target, "%s resists the poison!", target.name:capitalize())
			end
		end

		return true
	end,
	info = function(self, t)
		local project = t.getProject(self, t)
		local damage =t.getDamage(self, t)
		local pdamage =t.getPosionDamage(self, t)
		local peffect = t.getPosionEffect(self, t)
		local range = self:getTalentRange(t)
		return ([[Assail your foe with a terrible, spiny tentacle. Attack for %d%% tentacle damage and infect your target with a toxin that deals %0.2f nature damage each turn for 6 turns while reducing healing by %d%%. With a successful hit, you also pull yourself into close combat range with your foe, cutting off escape routes.
		The poison damage and bonus physical damage scale with your Spellpower.

		Spiny Tentacles also produce a second tentacle attack from your Use Tentacles skill for %d physical damage.]]):format(damage* 100,range,pdamage/6,peffect,project)
	end,
}

newTalent{
	name = "Channel Mastery",
	type = {"technique/tentacle-combat", 4},
	points = 5,
	mode="passive",
	require = {
		stat = {
			wil=function(level) return 30 + level * 2 end,
			mag=function(level) return 30 + level * 2 end,
		},
	},
	getDamage = function(self, t) return self:combatTalentSpellDamage(t, 20, 60) end,
	getDamageCrit = function(self, t) return self:combatTalentSpellDamage(t, 100, 200) end,
	info = function(self, t)
		local damage =t.getDamage(self, t)
		local damagecrit =t.getDamageCrit(self, t)
		return ([[Give your tentacle strikes %d burst damage on hit (radius 1) and %d burst damage on crit (radius 2).
		The type of damage done is randomly chosen between physical and the element type for each eye mastery that is active.
		The bonus damage scales with your Spellpower.]]):format(damage,damagecrit)
	end,
}
