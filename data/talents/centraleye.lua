newTalent{
	name = "Draining Gaze",
	type = {"spell/central-eye", 1},
	require = Talents.main_env.spells_req1,
	points = 5,
	random_ego = "attack",
	is_spell=true,
	is_gaze=true,
	mode = "sustained",  no_sustain_autoreset = true,
	cooldown = function(self, t)
		local c = 5
		local gem_level = getGemLevel(self)
		return math.max(c - gem_level, 0)
	end,
	sustain_mana = 50,
	true_range = function(self, t)
		local r = 5
		local gem_level = getGemLevel(self)
		local mult = (1 + 0.2*gem_level)
		r = math.floor(r*mult)
		return math.min(r, 10)
	end,
	getDamage = function(self, t)
		return self:combatStatTalentIntervalDamage(t, "combatSpellpower", 1, 25, 0.4)
	end,
	getRetributionDamage = function (self, t)
		local gem_level_bonus = 1+getGemLevel(self)*0.3
		local raw_max = self:combatScale(self:combatSpellpower()^1.2, 10, 20, 20, 40)
		return self:combatLimit(raw_max, 100, 10, 10, 30, 50)*gem_level_bonus * (self:combatTalentScale(t, 60, 100, 0.8)/100)
	end,
	getSpellDampening = function(self, t)
		--I want to use combatLimit here, but it breaks down when the limit is very close to x_high
		local tl = self:getTalentLevelRaw(t)
		if tl > 5 then tl = 5 end
		return 100*self:combatScale(tl, 0.15, 1, 0.35, 5)
	end,
	getSpellFailure = function(self, t)
		local tl = self:getTalentLevelRaw(t)
		if tl > 5 then tl = 5 end
		return 100*self:combatScale(tl, 0.2, 1, 0.3, 5)
	end,
	getManaGain = function(self, t)
		local gem_multiplier = 1+getGemLevel(self)*0.3
		return self:combatScale(self:combatSpellpower(), 0.8, 10, 1.25, 40)*self:combatTalentScale(t, 1, 2, 0.6)
	end,
	getCooldownPenalty = function(self, t)
		return self:combatLimit(self:combatTalentSpellDamage(t, 35, 75), 150, 0, 15, 35, 35)/100
	end,
	doGetGazeGrids = function(self, tid, dir, force_radius)
		return getGazeGrids(self)
	end,
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
		return true
	end,
	on_learn = function(self, t)
		self:attr("manaburn_resist",2)
		if not self:knowTalent(self.T_DIRECT_GAZE) then self:learnTalent(self.T_DIRECT_GAZE, true, 1) end
	end,
	on_unlearn = function(self, t)
		self:attr("manaburn_resist",-2)
		if not self:knowTalent(t) then
			if self:knowTalent(self.T_DIRECT_GAZE) then self:unlearnTalentFull(self.T_DIRECT_GAZE) end
		end
	end,
	target = function(self, t) return {type="eye", range=0, radius=t.true_range(self,t), talent=t, eye_angle=55} end,
	--Main gaze functionality
	drawGaze = function(self, t, ...)
		if game.zone.wilderness then return nil end
		local args = {...}
		local ret = args[1]

		local p = self.sustain_talents[t.id]
		if not p then return nil end

		--Clear any old gaze grids
		purgeGazeGrids(self)
		if self:isTalentActive(self.T_INTENSIFY_GAZE) then purgeGazeParticles(self) end

		if self:hasEffect(self.EFF_DRAINED_CENTRAL_EYE) then return nil end

		--If Direct Gaze is active, get the target from that
		--We need to call DrawGaze the moment Direct Gaze is activated, but Direct Gaze doesn't count as "on" until it finished activating.
		--Hence, we have Direct Gaze call drawGaze when it is activated but before it becomes fully active. In this case, it passes its return values early which we receive as "ret".
		if self:isTalentActive(self.T_DIRECT_GAZE) or ret then
			handleDirectGaze(self, p, ret)
		end

		local dam = t.getDamage(self, t)
		local dam_retribution = t.getRetributionDamage(self, t)

		local grids = getGazeGrids(self, _, d)
		if not grids then return end

		--Enemy spellcasters cannot evade our gaze by trapping us in ice! This is fun.
		if self:attr("encased_in_ice") then grids = p.last_grids
		else p.last_grids = grids end

		--We don't place the beholder within its own gaze area (I just like how this looks :P)
		grids[self.x][self.y] = nil

		--Create reference table of actors caught in gaze.
		local old_actors_in_gaze = p.actors_in_gaze or self.sustain_talents[self:getGaze().id].actors_in_gaze or {} --again, may be called while not itself active, but rather during activation
		p.actors_in_gaze = {}

		--Debuffs apply instantly
		local first = true
		if self.turn_procs.is_gaze_crit and  self.turn_procs.gaze_crit_power then dam = dam * self.turn_procs.gaze_crit_power end
		for px, ys in pairs(grids) do
			for py, _ in pairs(ys) do
				local act = game.level.map(px, py, Map.ACTOR)
				if act
					then p.actors_in_gaze[act] = true

					if self:knowTalent(self.T_BEHOLDER_FOCUS) then
						act:setEffect(act.EFF_BEHELD_BY_THE_GAZE, 2, {power=self:callTalent(self.T_BEHOLDER_FOCUS, "get_bonus_crit"), src=self})
					end

					act:setEffect(act.EFF_DRAINED_BY_THE_GAZE, 2, {power=1+t.getCooldownPenalty(self, t), magic_disruption=t.getSpellFailure(self, t), dam_retribution=dam_retribution, src=self})
				end

				--We check for crits only on foes to prevent message spam when exploring
				if first and not self.turn_procs.is_gaze_crit and act and self:reactionToward(act) < 0 and not (act:getMana()==0 and act:getVim()==0 and act:getPositive()==0 and  act:getNegative()==0 and act:getParadox()==0) then
					dam = self:spellCrit(t.getDamage(self, t))
					self.turn_procs.is_gaze_crit = true
					self.turn_procs.gaze_crit_power = self.turn_procs.crit_power
					first = false
				end
			end
		end

		--Passing the direction to addEffect as a numpad number actually yields a bad draw which leaves squares the beholder can see and should be able to target being blocked by corners.
		--As the gaze is a an eye effect, we want the targeted area to be effectively commesurate with the beholder's vision (accounting for angle and range), so we access the better draw this way.
		--This is undocumented and frankly shows Map.addEffect up to be a bit buggy, but our beholder code is that much cleaner if we do it this way.
		local dx, dy = getGazeDelta(self)
		local dir = self.facing_direction or 7
		local eff_x, eff_y = self.x+dx, self.y+dy
		--NOTE: Currently addEffect's draw functions are unused but this warning is kept in for future reference.

		p.effect = game.level.map:addEffect(
			--src, x, y, duration
			self, self.x, self.y, 2,
			--damtype
			engine.DamageType.MANADRAIN_GAZE,
			--parameters passed to damage type by map effect
			{power=1+t.getCooldownPenalty(self, t),
			dam=dam,
			dur=1,
			magic_disruption=t.getSpellFailure(self,t),
			dam_retribution=dam_retribution,
			power_check=self:combatSpellpower()},
			--range, direction(as table), angle
			--In T 1.2.0, passing a table of grids overrides map.addEffect's built-in draw functions.
			--We do not need to pass anything but the grids, but let's pass them anyway as they're stored within the map effect object.
			--However in T.1.1.6, this functionality is not yet in place. Let's pass the eye angle to be safe
			-- self:getTalentRange(t), {delta_x=dx, delta_y=dy}, grids
			self:getTalentRange(t), dir, self:getTalentTarget(t).eye_angle or 55,
			--overlay
			engine.Entity.new{alpha=20, display='', back_color=colors.VIOLET},
			--update_fct, selffire, friendlyfire
			nil, 0, 0
		)

		p.effect.grids = grids

		--Check all enemies with gaze effects are actually in gaze.
		for act, _ in pairs(old_actors_in_gaze) do
				act:callEffect(act.EFF_DRAINED_BY_THE_GAZE, "doCheckInGaze")
				-- act:callEffect(act.EFF_THWARTED_BY_THE_GAZE, "doCheckInGaze")
				act:callEffect(act.EFF_BEHELD_BY_THE_GAZE, "doCheckInGaze")
				act:callEffect(act.EFF_PARALYZED_BY_THE_GAZE, "doCheckInGaze")
		end

		--Apply additional nonsense with Intensify Gaze active
		if self:isTalentActive(self.T_INTENSIFY_GAZE) then
			local p = self.sustain_talents["T_INTENSIFY_GAZE"]

			p.effect_intense = game.level.map:addEffect(self, eff_x, eff_y, 2, engine.DamageType.MANADRAIN_GAZE_PLUS, {dam=dam,dur=1,power_check=self:combatSpellpower()},1, dir, self:getTalentTarget(t).eye_angle or 55, {type="manadrain", only_one = false}, nil, 0, 0)

			p.effect_intense.grids = grids

			--Patch particle grids in, bit messy but works
			p.effect_intense.particles = {}
			for px, ys in pairs(grids) do
				for py, _ in pairs(ys) do
					p.effect_intense.particles[#p.effect_intense.particles+1] = game.level.map:particleEmitter(px, py, 1, "manadrain", {})
				end
			end
		end
	end,
	callbackOnMove = function(self, t, ...)
		local args = {...}
		local ox, oy, force, moved = args[3], args[4], args[2], args[1]
		if not ox or not oy then return nil end

		--change direction, but not for forced movement - only self-directed
		if (not force) and moved and (ox~=self.x or oy~=self.y) then
			self.facing_direction = util.getDir(self.x, self.y, ox, oy)
		end

		if moved and (ox~=self.x or oy~=self.y) then
			if self:isTalentActive(self.T_INTENSIFY_GAZE) then
				--Check this is the last action of the last turn when the beholder will have the sustain ready.
				if self.sustain_talents.T_INTENSIFY_GAZE.beholder_sustain_dur <= (self.energyBase + game.energy_to_act*self:combatMovementSpeed(self.x, self.y))/game.energy_to_act then
				 	self:forceUseTalent(self.T_INTENSIFY_GAZE, {ignore_energy=true})
				end
			end
			t.drawGaze(self, t)
		end
	end,
	callbackOnActBase = function(self, t, ...)
		t.drawGaze(self, t)
	end,
	activate = function(self, t)
		local tg = self:getTalentTarget(t)
		local raw_x, raw_y = self:getTarget(tg)
		if not raw_x or not raw_y then return nil end

		--Cancel other gazes
		local acts = {}
		for tid, p in pairs(self.sustain_talents) do
			local t = self:getTalentFromId(tid)
			if t.is_gaze then
				for act, _ in pairs(p.actors_in_gaze) do
					acts[act]=true
				end
				self:forceUseTalent(self[tid], {ignore_energy=true})
			end
		end
		game:playSoundNear(self, "talents/spell_generic2")

		local l = self:lineFOV(raw_x, raw_y, nil, nil, self.x, self.y)
		local x, y = l:step()
		if not x then x = self.x end
		if not y then y = self.y end

		self.facing_direction = util.getDir(x, y, self.x, self.y)

		return {
			last_grids = {},
			actors_in_gaze = acts
			-- msgs = {}
		}
	end,
	deactivate = function(self, t, p)
		purgeGazeGrids(self)
		return true
	end,
	info = function(self, t)
		local dam_base = t.getDamage(self, t)
		local dam_retribution = t.getRetributionDamage(self, t)
		local radius = t.true_range(self,t)
		local mana_gain = t.getManaGain(self,t)
		local cooldown_penalty = (1+t.getCooldownPenalty(self, t))*100
		local spell_failure = t.getSpellFailure(self,t)
		return ([[Project a size %d cone of anti-magic energy from your central eye that interrupts spellcasting, causing up to %d manaburn damage per turn to all enemy targets in the area as you drain mana, vim, paradox, or positive and negative energy, and an additional %d manaburn damage to any target casting a spell. Spells affected will suffer a %d%% chance to be disrupted, and they will also have their cooldown multiplied by %d%%.

		The beholder will regenerate %0.2f mana for each enemy and ability affected in this fashion.

		The gaze will persist (in the direction you are facing) only so long as your central eye remains open. When closing your central eye, the gaze will be inactive until it opens again. You can only fire this attack in one of the basic 8 directions of movement. Damage will increase with Spellpower.

		Each point in central eye talents also reduces mana lost from manaburn by 2%%.]]):
		format(radius, dam_base, dam_retribution, spell_failure, cooldown_penalty, mana_gain)
	end,
}

newTalent{
	name = "Temporal Gaze",
	type = {"spell/central-eye", 2},
	require = Talents.main_env.spells_req2,
	points = 5,
	mana = 25,
	cooldown = function(self, t) return math.ceil(self:combatTalentLimit(t, 10, 45, 25, false, 1.0)) end, -- Limit >10
	getduration = function(self) return math.floor(self:combatStatScale("wil", 5, 14)) end,
	range = 4,
	no_npc_use = true,
	requires_target = true,
	direct_hit = true,
	target = function(self, t) return {type="hit", range=self:getTalentRange(t), talent=t} end,
	allowedRank = function(self, t, rank)
		if rank <= 2 then return true end
		if rank <= 3 and self:getTalentLevel(t) >= 3 then return true end
		if rank <= 3.2 and self:getTalentLevel(t) >= 5 then return true end
		if rank <= 3.5 and self:getTalentLevel(t) >= 7 then return true end
		return false
	end,
	swapCheck = function(self, t, target)
		if target.summoner == self then game.logPlayer(self, "You cannot swap creatures you summoned.") return nil end
		if target.summoner_time or target.summoner then game.logPlayer(self, "You cannot swap a creature which has an expiration time or a master.") return nil end
		if not t.allowedRank(self, t, target.rank) then local ranktext, rankcolor = target:TextRank() game.logPlayer(self, "You cannot swap a creature of this rank (%s%s#LAST#).", rankcolor, ranktext) return nil end
		return true
	end,
	on_learn = function(self, t) self:attr("manaburn_resist",2) end,
	on_unlearn = function(self, t) self:attr("manaburn_resist",-2) end,
	action = function(self, t)
		local tg = self:getTalentTarget(t)
		local x, y, target = self:getTargetLimited(tg)
		if not x or not y then return nil end
		if not target or target.dead or target == self then return end
		if game.party:hasMember(target) then return end
		if target.instakill_immune and target.instakill_immune >= 1 then  -- We special case this instead of letting the canBe check waste the talent because instakill is at present always binary
			game.logSeen(target, "%s is immune to this effect!", target.name:capitalize())
			return
		end
		if target.rank > 3 and ((target.life / target.max_life) >= 0.8) then
			game.logSeen(target, "%s must be below 80%% of their max life to be replaced!", target.name:capitalize())
			return
		end
		self:project(tg, x, y, function(px, py)
			local target = game.level.map(px, py, Map.ACTOR)
			if target:canBe("instakill") then
				target:setEffect(target.EFF_TEMPORAL_SWAP, t.getduration(self), {src=self})
			else
				game.logSeen(target, "%s resists the temporal swap!", target.name:capitalize())
			end
		end)
		return true
	end,
	info = function(self, t)
		local fake = {rank=2}
		local rt0, rc0 = self.TextRank(fake)
		fake.rank = 3; local rt3, rc3 = self.TextRank(fake)
		fake.rank = 3.2; local rt5, rc5 = self.TextRank(fake)
		fake.rank = 3.5; local rt7, rc7 = self.TextRank(fake)
		return ([[Gaze across alternate timelines to find a version of your target that is allied to you, then swap them through to this reality for %s turns (based on your Willpower).
		When the effect ends the temporal waveform collapses, sending your ally safely back to their own timeline and returning your enemy to this timeline.
		Targets with ranks at or above rare must be below 80%% of their maximum life to be replaced.
		This effect cannot be saved against but checks instakill immunity.

		You may only swap creatures of the following rank %s%s#LAST# or lower.
		At level 3 up to rank %s%s#LAST#.
		At level 5 up to rank %s%s#LAST#.
		At level 7 up to rank %s%s#LAST#.

		Each point in central eye talents also reduces mana lost from manaburn by 2%%.]]):format(t.getduration(self), rc0, rt0, rc3, rt3, rc5, rt5, rc7, rt7)
	end,
}

newTalent{
	short_name="BEHOLDER_FOCUS",
	name = "Improved Focus",
	type = {"spell/central-eye", 3},
	mode = "passive",
	require = Talents.main_env.spells_req3,
	points = 5,
	get_bonus_crit = function(self,t)
		return self:combatTalentSpellDamage(t, 20, 60)
	end,
	on_learn = function(self, t) self:attr("manaburn_resist",2) end,
	on_unlearn = function(self, t) self:attr("manaburn_resist",-2) end,
	info = function(self, t)
		local boost =t.get_bonus_crit(self,t)
		return ([[Your central eye allows you to focus clearly on your targets. Increases your critical power by %d%% on all targets within your gaze.
		This value will increase with your Spellpower.
		Each point in central eye talents also reduces mana lost from manaburn by 2%%.]]):format(boost)
	end,
}

newTalent{
	name = "Intensify Gaze",
	type = {"spell/central-eye", 4},
	require = Talents.main_env.spells_req4,
	points = 5,
	is_spell=true,
	random_ego = "attack",
	cooldown = function(self, t)
		local c = 20
		local gem_level = getGemLevel(self)
		return math.max(c - 2*gem_level, 0)
	end,
	mode = "sustained",
	mana = 10,
	true_range = function(self, t)
		local r = 5
		local gem_level = getGemLevel(self)
		local mult = (1 + 0.2*gem_level)
		r = math.floor(r*mult)
		return math.min(r, 10)
	end,
	getDuration = function(self, t)
		local r = 2 + self:getTalentLevelRaw(t)
		local gem_level = getGemLevel(self)
		local mult = (1 + 0.2*gem_level)
		r = math.floor(r*mult)
		return math.min(r, 10)
	end,
	getSilenceDuration = function(self, t)
		return math.ceil(self:getTalentLevel(t)/3+1.6)
	end,
	getImmunityDuration = function(self, t)
		return math.floor(4-self:getTalentLevelRaw(t)/2)
	end,
	getResistPenetration = function(self, t)
		return (self:combatTalentLimit(t, 40, 15, 30)-5)/100
	end,
	getProjectileSlow = function(self, t)
		local num = self:getTalentLevel(t)
		return self:combatScale(num, 0.25, 0.7, 0.5, 3.5)*100
	end,
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
	--target = function(self, t) return {type="hit",range= 1} end,
	target = function(self, t) return {type="cone",range= 0,radius=t.true_range(self,t),selffire=false,talent=t} end,
	on_learn = function(self, t) self:attr("manaburn_resist",2) end,
	on_unlearn = function(self, t) self:attr("manaburn_resist",-2) end,
	getEyeCooldown = function(self, t)
		return math.ceil(8 - self:getTalentLevelRaw(t)/2)
	end,
	getDamage = function (self, t)
		local gem_level = getGemLevel(self)
		return combatStatTalentIntervalDamage(self,t, "combatSpellpower", 6, 20)*(1 + 0.3*gem_level)
	end,
	on_pre_use = function(self, t, silent)
		if not (self:isTalentActive(self.T_DRAINING_GAZE) or self:isTalentActive(self.T_PARALYZING_GAZE)) then
			if not silent  then
				game.logPlayer(self, "You need to be maintaining a gaze to intensify!")
			end
			return false
		end
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
	activate = function(self, t)
		return {beholder_sustain_dur=t.getDuration(self, t)}
	end,
	deactivate = function(self, t, p)
		self:setEffect(self.EFF_DRAINED_CENTRAL_EYE, t.getEyeCooldown(self, t), {power=1,boost=0,spower=0})
		purgeGazeParticles(self)
		return true
	end,
	info = function(self, t)
		local radius = t.true_range(self,t)
		local dam = t.getDamage(self, t)
		local field_duration = t.getDuration(self,t)
		local dur = t.getDuration(self, t)
		local eye_cooldown = t.getEyeCooldown(self, t)
		local silence_dur = t.getSilenceDuration(self, t)
		local immunity_dur = t.getImmunityDuration(self, t)
		local stun_resist_pen = t.getResistPenetration(self,t)*100
		local projectile_slow = t.getProjectileSlow(self, t)
		return ([[Intensify your gaze, evoking an enhanced effect according to whichever gaze is active. After %d turns, your eye will be exhausted and will close for %d turns.

		Draining Gaze: The gaze will silence targets for %d turns.

		Each point in central eye talents also reduces mana lost from manaburn by 2%%.]]):format(dur, eye_cooldown, silence_dur, stun_resist_pen, projectile_slow)
		-- Took this next line out of the description because there is no stand alone Paralyzing Gaze. WK 2021/05/08
			--Paralyzing Gaze: Targets within the gaze have their global speed as well as their stun/confusion/sleep/paralysis resistances reduced by %d%%. Also, all projectiles in the area will be slowed by %d%%.
	end,
}
