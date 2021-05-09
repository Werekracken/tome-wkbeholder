newDamageType{
	name = "flamelaser", type = "FLAMELASER", text_color = "#LIGHT_RED#",
	antimagic_resolve = true,
	projector = function(src, x, y, type, dam)
		local target = game.level.map(x, y, Map.ACTOR)
		if not target then return end

		local realdam = DamageType.defaultProjector(src, x, y, DamageType.FIRE, dam.damage)
		if dam.burn>0 then
			target:setEffect(target.EFF_BURNING, 4, {src=src, power=dam.burn * dam.damage, no_ct_effect=true})
		end
		-- Explosive?
		if dam.explosion then
			src:project({type="ball", x, y, radius=dam.radius, friendlyfire=dam.friendlyfire}, x, y, function(bx, by)
						local actor2 = game.level.map(bx, by, Map.ACTOR)
						if actor2 and (actor2.x ~= x or actor2.y ~= y) then
							local dam_inst = dam.splash
							DamageType.defaultProjector(src, bx, by, DamageType.FIRE, dam_inst)
							if dam.burn>0 and src ~= actor2 then
								actor2:setEffect(actor2.EFF_BURNING, 4, {src=src, power=dam.burn * dam_inst, no_ct_effect=true})
							end
						end
					end)
			game.level.map:particleEmitter(x, y, dam.radius, "ball_fire", {radius=dam.radius, tx=x, ty=y})
		end

		return realdam
	end,
	death_message = {"burnt", "scorched", "blazed", "roasted", "flamed", "fried", "combusted", "toasted", "slowly cooked", "boiled"},
}

newDamageType{
	name = "manadrain", type = "MANADRAIN",
	projector = function(src, x, y, type, dam)
		local realdam = DamageType:get(DamageType.MANABURN).projector(src, x, y, DamageType.MANABURN, dam.dam)
		local target = game.level.map(x, y, Map.ACTOR)
		if target and target ~=src then
			DamageType:get(DamageType.SILENCE).projector(src, x, y, DamageType.SILENCE, dam)
		end
		return realdam
	end,
}

newDamageType{
	name = "manaburn", type = "ARCANE_SILENT", text_color = "#PURPLE#",
	antimagic_resolve = true,
	death_message = {"blasted", "energised", "mana-torn", "dweomered", "imploded"},
	-- hideMessage = true,
	-- hideFlyer = false
}

newDamageType{
	name = "pure manadrain", type = "PURE_MANADRAIN",
	projector = function(src, x, y, type, dam)
		local target = game.level.map(x, y, Map.ACTOR)
		if target then

			local mana = dam.dam
			local vim = dam.dam / 2
			local positive = dam.dam / 4
			local negative = dam.dam / 4
			local paradox = dam.dam / 2

			mana = math.min(target:getMana(), mana)
			vim = math.min(target:getVim(), vim)
			positive = math.min(target:getPositive(), positive)
			negative = math.min(target:getNegative(), negative)
			paradox = target:getParadox()>0 and paradox or 0

			local fulldam = dam.dam
			if not dam.always_full_damage then fulldam = math.max(mana, vim * 2, positive * 4, negative * 4, paradox * 2) end

			if fulldam == 0 and (target:getMana()==0 and target:getVim()==0 and target:getPositive()==0 and  target:getNegative()==0 and target:getParadox()==0) then
				return nil
			end

			target:incMana(-mana)
			target:incVim(-vim)
			target:incPositive(-positive)
			target:incNegative(-negative)
			target:incParadox(paradox)

			-- local realdam = DamageType.defaultProjector(src, x, y, DamageType.ARCANE, fulldam)

			-- local draineds = {}
			-- if mana>0 then draineds[#draineds+1] = ("#PURPLE# %0.2f#WHITE# mana"):format(mana) end
			-- if vim>0 then draineds[#draineds+1] = ("#904010# %0.2f#WHITE# vim"):format(vim) end
			-- if positive>0 then draineds[#draineds+1] = ("#YELLOW# %0.2f#WHITE# positive energy"):format(positive) end
			-- if negative>0 then draineds[#draineds+1] = ("#GREY# %0.2f#WHITE# negative energy"):format(negative) end
			-- if paradox>0 then draineds[#draineds+1] = ("#LIGHT_STEEL_BLUE# %0.2f#WHITE# paradox"):format(paradox) end
			-- local str = table.concatNice(draineds, "#WHITE#, ", "#WHITE# and ")

			-- local p = src.sustain_talents.T_DRAINING_GAZE

			-- p.msgs[#p.msgs+1] = ("%s's manadrain gaze drains %s #WHITE#from %s!"):format(string.capitalize(src.name), str, target.name)

			-- return realdam
			return DamageType:get(DamageType.ARCANE).projector(src, x, y, DamageType.ARCANE, fulldam)
		end
		return 0
	end,
	-- hideMessage = true,
	-- hideFlyer = false
}

newDamageType{
	name = "manadrain_gaze", type = "MANADRAIN_GAZE",
	projector = function(src, x, y, type, dam)
		local target = game.level.map(x, y, Map.ACTOR)

		if target then
			if src:knowTalent(src.T_BEHOLDER_FOCUS) then
				target:setEffect(target.EFF_BEHELD_BY_THE_GAZE, 2, {power=src:callTalent(src.T_BEHOLDER_FOCUS, "get_bonus_crit"), src=src})
			end

			target:setEffect(target.EFF_DRAINED_BY_THE_GAZE, 2, {power=dam.power, magic_disruption=dam.magic_disruption, dam_retribution=dam.dam_retribution, src=src})

			local realdam = DamageType:get(DamageType.PURE_MANADRAIN).projector(src, x, y, DamageType.PURE_MANADRAIN, dam) or 0

			if realdam == 0 then return nil end

			local mod = realdam / dam.dam

			local mana_gained = mod*src:callTalent(src.T_DRAINING_GAZE, "getManaGain")

			src:incMana(mana_gained)
			-- if game.delayed_log_messages[src] and game.delayed_log_messages[src]["manadrain_gaze_mana_gain"] then
			-- 	local msg = game.delayed_log_messages[src]["manadrain_gaze_mana_gain"]
			-- 	local old_mana_gained = tonumber(msg:match("%d+.%d+")) or tonumber(msg:match("%d+"))
			-- 	mana_gained = mana_gained + old_mana_gained
			-- end
			-- local message = ("Your draining gaze restores #VIOLET#%0.2f mana."):format(mana_gained)

			--game.logSeen(src, message)
			-- game:delayedLogMessage(src, nil, "manadrain_gaze_mana_gain", message)

		end
	end,
	hideMessage = true
}

-- newDamageType{
-- 	name = "manadrain_gaze", type = "MANADRAIN_GAZE",
-- 	projector = function(src, x, y, type, dam)
-- 		local target = game.level.map(x, y, Map.ACTOR)
-- 		if target then
-- 			if src:knowTalent(src.T_BEHOLDER_FOCUS) then
-- 				target:setEffect(target.EFF_BEHELD_BY_THE_GAZE, 1, {power=src:callTalent(src.T_BEHOLDER_FOCUS, "get_bonus_crit"), src=src})
-- 			end

-- 			local mana = dam.dam
-- 			local vim = dam.dam / 2
-- 			local positive = dam.dam / 4
-- 			local negative = dam.dam / 4
-- 			local paradox = dam.dam / 2

-- 			mana = math.min(target:getMana(), mana)
-- 			vim = math.min(target:getVim(), vim)
-- 			positive = math.min(target:getPositive(), positive)
-- 			negative = math.min(target:getNegative(), negative)
-- 			paradox = target:getParadox()>0 and paradox or 0

-- 			local dam = math.max(mana, vim * 2, positive * 4, negative * 4, paradox * 2)
-- 			if dam == 0 and (target:getMana()==0 and target:getVim()==0 and target:getPositive()==0 and  target:getNegative()==0 and target:getParadox()==0) then--and not (target.paradox or target.sustain_paradox) then
-- 				return nil
-- 			end

-- 			target:incMana(-mana)
-- 			target:incVim(-vim)
-- 			target:incPositive(-positive)
-- 			target:incNegative(-negative)
-- 			target:incParadox(paradox)

-- 			local realdam = DamageType:get(DamageType.ARCANE).projector(src, x, y, DamageType.ARCANE, dam)

-- 			local mana_gained = src:callTalent(src.T_DRAINING_GAZE, "getManaGain")

-- 			src:incMana(mana_gained)
-- 			if game.delayed_log_messages[src] and game.delayed_log_messages[src]["manadrain_gaze_mana_gain"] then
-- 				local msg = game.delayed_log_messages[src]["manadrain_gaze_mana_gain"]
-- 				local old_mana_gained = tonumber(msg:match("%d+.%d+")) or tonumber(msg:match("%d+"))
-- 				mana_gained = mana_gained + old_mana_gained
-- 			end
-- 			local message = ("Your draining gaze restores #VIOLET#%0.2f mana."):format(mana_gained)
-- 			--game.logSeen(src, message)
-- 			game:delayedLogMessage(src, nil, "manadrain_gaze_mana_gain", message)

-- 			return realdam
-- 		end
-- 		return 0
-- 	end
-- }

-- newDamageType{
-- 	name = "manadrain_gaze", type = "MANADRAIN_GAZE",
-- 	projector = function(src, x, y, type, dam)
-- 		local target = game.level.map(x, y, Map.ACTOR)
-- 		if target then
-- 			if src:knowTalent(src.T_BEHOLDER_FOCUS) then
-- 				target:setEffect(target.EFF_BEHELD_BY_THE_GAZE, 1, {power=src:callTalent(src.T_BEHOLDER_FOCUS, "get_bonus_crit"), src=src})
-- 			end

-- 			local mana = dam.dam
-- 			local vim = dam.dam / 2
-- 			local positive = dam.dam / 4
-- 			local negative = dam.dam / 4
-- 			local paradox = dam.dam / 2

-- 			mana = math.min(target:getMana(), mana)
-- 			vim = math.min(target:getVim(), vim)
-- 			positive = math.min(target:getPositive(), positive)
-- 			negative = math.min(target:getNegative(), negative)
-- 			paradox = target:getParadox()>0 and paradox or 0

-- 			local dam = math.max(mana, vim * 2, positive * 4, negative * 4, paradox * 2)
-- 			if dam == 0 and (target:getMana()==0 and target:getVim()==0 and target:getPositive()==0 and  target:getNegative()==0 and target:getParadox()==0) then--and not (target.paradox or target.sustain_paradox) then
-- 				return nil
-- 			end

-- 			target:incMana(-mana)
-- 			target:incVim(-vim)
-- 			target:incPositive(-positive)
-- 			target:incNegative(-negative)
-- 			target:incParadox(paradox)

-- 			local realdam = DamageType:get(DamageType.ARCANE).projector(src, x, y, DamageType.ARCANE, dam)

-- 			local mana_gained = src:callTalent(src.T_DRAINING_GAZE, "getManaGain")

-- 			src:incMana(mana_gained)
-- 			if game.delayed_log_messages[src] and game.delayed_log_messages[src]["manadrain_gaze_mana_gain"] then
-- 				local msg = game.delayed_log_messages[src]["manadrain_gaze_mana_gain"]
-- 				game.log(self, "message is:  "..msg)
-- 				local old_mana_gained = tonumber(msg:match("%d+.%d+")) or tonumber(msg:match("%d+"))
-- 				mana_gained = mana_gained + old_mana_gained
-- 			end
-- 			local message = ("Your draining gaze restores #VIOLET#%0.2f mana."):format(mana_gained)
-- 			--game.logSeen(src, message)
-- 			game:delayedLogMessage(src, nil, "manadrain_gaze_mana_gain", message)

-- 			return realdam
-- 		end
-- 		return 0
-- 	end
-- }

newDamageType{
	name = "manadrain_gaze_plus", type = "MANADRAIN_GAZE_PLUS",
	projector = function(src, x, y, type, dam)
		local target = game.level.map(x, y, Map.ACTOR)
		if target and target ~=src and not target:hasEffect(target.EFF_MASTERED_THE_GAZE) then
			DamageType:get(DamageType.SILENCE).projector(src, x, y, DamageType.SILENCE, dam)
		end
	end
}

newDamageType{
	name = "dam type dummy",
	type = "DAM_TYPE_DUMMY",
	text_color = "#F53CBE#",
	hideMessage=true,
	hideFlyer=true
}

newDamageType{
	name = "paralyzing_gaze", type = "PARALYZING_GAZE",
	projector = function(src, x, y, type, dam)
		local target = game.level.map(x, y, Map.ACTOR)
		if not target then return nil end

		-- local realdam
		-- if target:hasEffect(target.EFF_PARALYZED_BY_THE_GAZE) then
		-- 	realdam = DamageType:get(DamageType.MIND).projector(src, x, y, DamageType.MIND, dam.dam)
		-- end
		if rng.percent(dam.chance) and target and not target.dead and target:canBe("sleep") and not target:hasEffect(target.EFF_PARALYZED_BY_THE_GAZE) and not target:hasEffect(target.EFF_IMMUNE_PARALYZING_GAZE)  then
			--t2:setEffect(t2.EFF_SLEEP, p.dur, {src=self, power=p.power, waking=p.waking, insomnia=p.insomnia, no_ct_effect=true, apply_power=self:combatMindpower()})
			target:setEffect(target.EFF_PARALYZED_BY_THE_GAZE,dam.dur,{src=src, power=dam.power or 20, waking=0,insomnia=0,no_ct_effect=true,apply_power=dam.apply_power or src:combatMindpower(), immunity_dur=dam.immunity_dur})
		end
		-- return realdam
	end,
}

newDamageType{
	name = "paralyzing_gaze_plus", type = "PARALYZING_GAZE_PLUS",
	projector = function(src, x, y, type, dam)
		local target = game.level.map(x, y, Map.PROJECTILE)
		if target then target.energy.mod = target.energy.mod * (100-dam.projectile_slow) / 100 end
		local tar = game.level.map(x, y, Map.ACTOR)
		if tar then tar:setEffect(tar.EFF_THWARTED_BY_THE_GAZE, 2, {stun_resist_pen=dam.stun_resist_pen}) end
	end
}

newDamageType{
	name = "manadrain_gaze_plus", type = "MANADRAIN_GAZE_PLUS",
	projector = function(src, x, y, type, dam)
		local target = game.level.map(x, y, Map.ACTOR)
		if target and target ~=src and not target:hasEffect(target.EFF_MASTERED_THE_GAZE) then
			DamageType:get(DamageType.SILENCE).projector(src, x, y, DamageType.SILENCE, dam)
		end
	end
}

newDamageType{
	name = "paralysis", type = "PARALYSIS",
	projector = function(src, x, y, type, dam)
		local realdam = DamageType:get(DamageType.MIND).projector(src, x, y, DamageType.MIND, dam.dam)
		local target = game.level.map(x, y, Map.ACTOR)
		if target and not target.dead and target:canBe("sleep") and not target:hasEffect(target.EFF_SLEEP) then
			--t2:setEffect(t2.EFF_SLEEP, p.dur, {src=self, power=p.power, waking=p.waking, insomnia=p.insomnia, no_ct_effect=true, apply_power=self:combatMindpower()})
			target:setEffect(target.EFF_SLEEP,dam.dur,{src=src, power=dam.power or 20, waking=0,insomnia=20,no_ct_effect=true,apply_power=dam.apply_power or src:combatMindpower()})
		end
		return realdam
	end,
}
