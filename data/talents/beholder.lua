
newTalent{
	name = "Beholder",
	type = {"race/beholder", 1},
	mode = "passive",
	require = Talents.main_env.racial_req1,
	points = 5,
	on_learn = function(self, t)
		self.combat_spellpower = (self.combat_spellpower or 0) + 3
		self.mana_regen = (self.mana_regen or 0) + .15
	end,
	on_unlearn = function(self, t)
		self.mana_regen = (self.mana_regen or 0) - .15
		self.combat_spellpower = (self.combat_spellpower or 0) - 3
	end,
	getCritPower = function(self,t)
		return self:getTalentLevel(t) * 3
	end,
	getCritDuration = function(self, t)
		return math.floor(2 + self:getTalentLevel(t)*0.5)
	end,
	getEyeDuration = function(self, t)
		return math.floor(5 + self:getTalentLevel(t) * 1.5)
	end,
	info = function(self, t)
		return ([[Improves your handling of arcane forces, increasing mana regen by %0.2f and spellpower by %d]]):format(self:getTalentLevelRaw(t) * .15,3 * self:getTalentLevelRaw(t))
	end,
}

newTalent{
	short_name = "E_ORIGIN",
	name = "Extraplanar Origin",
	type = {"race/beholder", 2},
	mode = "sustained",
	is_spell=true,
	require = Talents.main_env.racial_req2,
	points = 5,
	sustain_mana = 10,
	cooldown = 30,
	tactical = { BUFF = 2 },
	getCancelDamageChance = function(self, t)
		return util.bound(10 + self:combatTalentSpellDamage(t, 5, 35), 10, 40)
	end,
	getPhaseRange = function(self, t)
		return math.floor(combatTalentScale(self,t, 1, 2.80))
	end,
	on_damage = function(self, t, damtype, dam)
		--print("test-inside")
		local cancel_damage_chance=t.getCancelDamageChance(self,t)
		local phase_range=t.getPhaseRange(self,t)
		if rng.percent(cancel_damage_chance) then
			if dam>=self.max_life*.15 then
				self.turn_procs.phase_shift = true
				self:teleportRandom(self.x, self.y, phase_range)
			end
			game.logSeen(self, "#CRIMSON#%s avoids %d damage!", self.name:capitalize(),dam/2)
			return dam/2
		end

		return dam
	end,
	on_learn = function(self, t)
		self.resist_all_on_teleport = (self.resist_all_on_teleport or 0) + 3
		self.defense_on_teleport = (self.defense_on_teleport or 0) + 3
	end,
	on_unlearn = function(self, t)
		self.defense_on_teleport = (self.defense_on_teleport or 0) - 3
		self.resist_all_on_teleport = (self.resist_all_on_teleport or 0) - 3
	end,
	activate = function(self, t)
		game:playSoundNear(self, "talents/spell_generic")
		return {
			particle = self:addParticles(Particles.new("ultrashield", 1, {rm=0, rM=0, gm=0, gM=0, bm=10, bM=200, am=70, aM=180, radius=0.4, density=10, life=14, instop=20})),
		}
	end,
	deactivate = function(self, t, p)
		self:removeParticles(p.particle)
		return true
	end,
	info = function(self, t)
		local chance = t.getCancelDamageChance(self, t)
		local range = t.getPhaseRange(self,t)
		return ([[You exist partly out of this plane, increasing resist all and defense by +%d when phased.
			While sustained, %d%% chance to phase within radius %d and prevent half the damage when you are hit.
			This phasing only occurs for hits over 15%% of your max life.
			This chance scales with your Spellpower and cannot occur more than once per turn.]]):format(self:getTalentLevelRaw(t) * 3, chance,range)
	end,
}

-- newTalent{
	-- name = "Test Laser",
	-- type = {"race/beholder",1},
	-- require =  Talents.main_env.spells_req1,
	-- points = 5,
	-- random_ego = "attack",
	-- mana = 8,
	-- cooldown = function(self,t)
		-- return 6+math.floor(getEyeDelay(self))
	-- end,
	-- tactical = { ATTACK = { FIRE = 2 } },
	-- range = 10,
	-- direct_hit = true,
	-- reflectable = true,
	-- requires_target = true,
	-- target = function(self, t)
		-- local tg = {type="beam", range=self:getTalentRange(t), talent=t, display={particle="bolt_fire", trail="firetrail"}}

		-- return tg
	-- end,
	-- getDamage = function(self, t) return self:combatTalentSpellDamage(t, 20, 200) end,
	-- on_pre_use = function(self, t, silent) if self:hasEffect(self.EFF_BLINDED) then if not silent  then game.logPlayer(self, "You cannot use your eyestalks while blind!") end  return false end return true end,
	-- action = function(self, t)
		-- local tg = self:getTalentTarget(t)
		-- local x, y = self:getTarget(tg)
		-- local critboost = 0


		-- self.combat_spellcrit = self.combat_spellcrit + critboost
		-- local final_damage = self:spellCrit(t.getDamage(self, t))
		-- self.combat_spellcrit = self.combat_spellcrit - critboost
		-- if not x or not y then return nil end
		-- local grids = nil
		-- local targetnum = 1
		-- self:project(tg, x, y, function(px, py)
			-- local target = game.level.map(px, py, Map.ACTOR)
			-- if not target then return end
			-- game.log("%s is number %d",target.name,targetnum)
			-- targetnum = targetnum+1
		-- end)
		-- return true
	-- end,
	-- info = function(self, t)
		-- local damage = t.getDamage(self, t)
		-- return ([[Launches a beam of fire from your eyestalks, doing %0.2f fire damage.
		-- The range will increase with your talent level and damage will increase with your Spellpower.]]):
		-- format(damDesc(self, DamageType.FIRE, damage))
	-- end,
-- }

newTalent{
	name = "Invoke Fear",
	type = {"race/beholder", 3},
	points = 5,
	require = Talents.main_env.racial_req3,
	cooldown = function(self, t) return 50 - self:getTalentLevel(t) * 4 end,
	mana = 20,
	is_spell=true,
	tactical = { DISABLE = {sleep = 1} },
	direct_hit = true,
	requires_target = true,
	range = 0,
	radius = function(self, t) return 6 + math.floor(self:getTalentLevel(t)/3) end,
	target = function(self, t) return {type="ball", radius=self:getTalentRadius(t),selffire=false, range=self:getTalentRange(t), talent=t} end,
	getDuration = function(self, t) return 6 + math.ceil(self:getTalentLevel(t)/3) end,
	getChance = function(self, t)
		return math.min(60, math.floor(30 + (math.sqrt(self:getTalentLevel(t)) - 1) * 22))
	end,

	action = function(self, t)
		local tg = self:getTalentTarget(t)
		--local x, y = self:getTarget(tg)
		local x = self.x
		local y = self.y
		if not x or not y then return nil end
		local chance = t.getChance(self, t)
		local duration = t.getDuration(self, t)
		--local power = self:spellCrit(t.getSleepPower(self, t))
		self:project(tg, x, y, function(tx, ty)
			local target = game.level.map(tx, ty, Map.ACTOR)
			if target then
				if target:canBe("fear") and target:checkHit(self:combatSpellpower(), target:combatMentalResist(), 0, 95) then

					target:setEffect(target.EFF_PANICKED, duration, {src=self,range=10,chance=chance})
					game.level.map:particleEmitter(target.x, target.y, 1, "generic_charge", {rm=0, rM=0, gm=180, gM=255, bm=180, bM=255, am=35, aM=90})
				else
					game.logSeen(self, "%s resists the fear!", target.name:capitalize())
				end
			end
		end)
		game:playSoundNear(self, "talents/dispel")
		return true
	end,
	info = function(self, t)
		local range = self:getTalentRadius(t)
		local duration = t.getDuration(self, t)
		local chance = t.getChance(self, t)
		return ([[Panic your enemies within range %d for %d turns.
		Anyone who fails to make a mental save against your Spellpower has a %d%% chance each turn of trying to run away from you.]]):format(range, duration, chance)
	end,
}

newTalent{
	name = "Spawn Beholderkin",
	type = {"race/beholder", 4},
	require = Talents.main_env.racial_req4,
	points = 5,
	is_spell=true,
--	no_energy = true,
--	requires_target = true,
	cooldown = function(self, t) return 50 - self:getTalentLevel(t) * 3 end,
	range = 0,
	radius = 2,
	no_npc_use = true,
	getSummonCount = function(self, t)
		return math.floor(combatTalentScale(self,t, 2, 4.70))
	end,
	getSummonDuration = function(self, t)
		return math.floor(combatTalentScale(self,t, 6, 10.40)) + 1
	end,
	target = function(self, t)
		return {type="ball", range=self:getTalentRange(t), selffire=false, radius=self:getTalentRadius(t), talent=t}
	end,
	action = function(self, t)
		--local tg = {type="ball", range=self:getTalentRange(t), selffire=false, radius=self:getTalentRadius(t)}
		local tg = self:getTalentTarget(t)
		--local tx, ty, target = self:getTarget(tg)
		local tx = self.x
		local ty = self.y
		if not tx or not ty then return nil end
		local _ _, _, _, tx, ty = self:canProject(tg, tx, ty)
		-- target = game.level.map(tx, ty, Map.ACTOR)
		-- if target == self then target = nil end
		local count = t.getSummonCount(self, t)
		local dur = t.getSummonDuration(self,t)
		-- Find space
		for i = 1, count do
			local x, y = util.findFreeGrid(tx, ty, 2, true, {[Map.ACTOR]=true})
			if not x then
				game.logPlayer(self, "Not enough space to summon!")
				return
			end

			local NPC = require "mod.class.NPC"
			local m = NPC.new{
				type = "beholder", subtype = "beholder",
				display = "y",
				name = "Summoned Beholderkin", color=colors.YELLOW,
				--resolvers.nice_tile{image="invis.png", add_mos = {{image="npc/beholder_summon.png", display_h=1, display_y=-1}}},
				image="npc/beholder_summon.png",
				desc = "Conjured minions of the beholders.",

				body = { INVEN = 10, MAINHAND=1, OFFHAND=1, BODY=1 },

				rank = 3,
				life_rating = 8,
				--life_rating = 1,
				max_life = resolvers.rngavg(30,50),
				--max_life = resolvers.rngavg(1,1),
				max_mana = 100,
				infravision = 10,

				autolevel = "none",
				ai = "summoned", ai_real = "tactical", ai_state = { talent_in=1, },
				ai_tactic = resolvers.tactic"tank",
				stats = {str=0, dex=0, con=0, cun=0, wil=0, mag=0},
				inc_stats = { str=0 + self:getStr() * self:getTalentLevel(t) / 5, mag=0 + self:getMag() * self:getTalentLevel(t) / 5, cun=0 + self:getCun() * self:getTalentLevel(t) / 5, wil=0 + self:getWil() * self:getTalentLevel(t) / 5, dex=0 + self:getDex() * self:getTalentLevel(t) / 5, con=0 + self:getCon() * self:getTalentLevel(t) / 5, },

				resolvers.equip{
					{type="weapon", subtype="longsword", autoreq=true},
					{type="weapon", subtype="dagger", autoreq=true},
				},

				level_range = {1, nil}, exp_worth = 0,
				silent_levelup = true,

				combat_armor = 13, combat_def = 8,
				resolvers.talents{
					[Talents.T_GOLEM_BEAM]={base=1, every=15, max=5},
					[Talents.T_MANA_POOL]={base=1, every=5, max=1},
					--[Talents.T_KINETIC_AURA]={base=1, every=5, max=5},
					--[Talents.T_CHARGED_AURA]={base=1, every=5, max=5},
				},
				on_die = function(self)
					if self.life<=0 then
						local tg = {type="ball", range=0, selffire=false, friendlyfire=false, radius=2}
						local tx, ty, target = self:getTarget(tg)
						self:project(tg, self.x, self.y, DamageType.SLIME, self:spellCrit(self:combatTalentSpellDamage("T_GOLEM_BEAM", 1, 20)))
						--print("test")
						--print(self.life)
						game.level.map:particleEmitter(self.x, self.y, 1, "slime")
						game.log("The beholderkin explodes!")
					end
				end,
				faction = self.faction,
				summoner = self, summoner_gain_exp=true,
				summon_time = dur,
				--ai_target = {actor=target}
			}
			if self:knowTalent(self.T_BLIGHTED_SUMMONING) then m:learnTalent(m.T_SOUL_ROT, true, 3) end
			m:setEffect(m.EFF_EGGED,1,{hp=1000,apply_power=100,min_dur=1})
			setupSummon(self, m, x, y)
		end

		game:playSoundNear(self, "talents/spell_generic")
		return true
	end,
	info = function(self, t)
		local count = t.getSummonCount(self, t)
		local dur = t.getSummonDuration(self,t)
		return ([[Call on your beholderkin pets to fight by your side.
		Summons up to %d beholderkin to your side for %d turns.]]):format(count,dur)
	end,
}

newTalent{
	short_name = "BEHOLDER_CLOAKING",
	name = "Cloak of Deception",
	type = {"race/beholder-other", 1},
	points = 5,
	--image = "shockbolt/object/artifact/black_cloak.png",
	mode = "sustained", no_sustain_autoreset = true,
	no_energy = true,
	cooldown = 0,
	is_spell=true,
	activate = function(self, t)
		--self:setEffect(self.EFF_CLOAK_OF_DECEPTION, 1, {})
			self.old_faction_cloak = self.faction
			self.faction = "allied-kingdoms"
			self.descriptor.fake_race = "Human"
			self.descriptor.fake_subrace = "Cornac"
			self.moddable_tile = "human_male"
			self.moddable_tile_base = "base_higher_01.png"
			self.moddable_tile_nude = false
			self.moddable_tile_ornament={}
			--self.moddable_tile_ornament["male"]="upper_body_13"
			self.moddable_tile_ornament["male"]="beholder_lower_body_01"
			self.moddable_tile_ornament["male"]="beholder_upper_body_01"
			self:updateModdableTile()
			engine.Map:setViewerFaction(self.faction)
			return {}
	end,
	deactivate = function(self, t, p)
		-- Reset the terrain tile
		--self:removeEffect(self.EFF_CLOAK_OF_DECEPTION, true, true)
		self.faction = self.old_faction_cloak
		self.descriptor.fake_race = nil
		self.descriptor.fake_subrace = nil
		self.moddable_tile = nil--"beholder"
		self.moddable_tile_base = nil--self.true_moddable_tile_base
		self.moddable_tile_nude = true
		self.moddable_tile_ornament=nil
		--self:updateModdableTile()
		self:removeAllMOs()
		self.image="player/human_male/base_shadow_01.png"
		local tile_to_use =self.true_moddable_tile_base
		if self:hasEffect(self.EFF_DRAINED_CENTRAL_EYE) then
			tile_to_use=self.closed_moddable_tile_base
		end

		if self.growth_stage>=1 and self.growth_stage<3 then
			self.add_mos = {{image="player/beholder/"..(tile_to_use), display_h=.75,display_w=.75, display_y=.25, display_x=.15}}
		end
		if self.growth_stage>=3 and self.growth_stage<5 then
			self.add_mos = {{image="player/beholder/"..(tile_to_use), display_h=1,display_w=1, display_y=0, display_x=0}}
		end
		if self.growth_stage>=5 then
			self.add_mos = {{image="player/beholder/"..(tile_to_use), display_h=1.5,display_w=1.5, display_y=-.5, display_x=-.25}}
		end
		game.level.map:updateMap(self.x, self.y)
		self:updateModdableTile()
		if self.player then engine.Map:setViewerFaction(self.faction) end

		return true
	end,
	info = function(self, t)
		return ([[Wrap your tentacles around yourself and cloak yourself as a human.]])
	end,
}

newTalent{
	short_name = "MAGEEYE_DEVOUR",
	name = "Absorb Magic",
	type = {"race/beholder-other", 1},
	cooldown = 10,
	no_npc_use = true,
	--get_growth_points = function(self, t, mlevel,unique)
	--	return math.max((.5 * (mlevel - self.growth_stage)+ 1) * unique,.5)
	--end,
	is_spell=true,
	action = function(self, t)
		local d d = self:showInventory("Drain which item?", self:getInven("INVEN"), function(o) return o.power_source and o.power_source.arcane and o.material_level and (o.material_level>=self.growth_stage or o.unique or o.rare) end, function(o, item)

			local amt = 1 	--t.get_growth_points(self, t,o.material_level,unique)
			if o.material_level==self.growth_stage then
				amt=0.5
			end
			local amts_by_tier = {3, 3, 4, 5, 7} --I'll be adjusting this as I tune up the difficulty of evolving
			if o.unique then
				if o.godslayer then amt = 500
				elseif o.legendary then amt = math.ceil(amts_by_tier[o.material_level]/5 * 8)
				else amt = amts_by_tier[o.material_level]
				end
			elseif o.rare
				and not o.subtype == "taint" then --Quick compatibility fix for HousePet's taints addon
				amt = amt*({3, 3, 4, 4, 5})[o.material_level]
			end
			self:removeObject(self:getInven("INVEN"), item)
			--local amt = t.energy_per_turn(self, t)
			self:attr("growth_points",amt)
			if self.growth_stage == 1 and self.growth_points>=self.growth_curve[1] then
				mage_stage_2(self)
			end
			if self.growth_stage == 2 and self.growth_points>=self.growth_curve[2] then
				mage_stage_3(self)
			end
			if self.growth_stage == 3 and self.growth_points>=self.growth_curve[3] then
				mage_stage_4(self)
			end
			if self.growth_stage == 4 and self.growth_points>=self.growth_curve[4] then
				mage_stage_5(self)
			end
			local text = ("\nYou gain #LIGHT_GREEN#%0.2f#WHITE# growth points."):format(amt)
			game.log(text)
			self.changed = true
			d.used_talent = true
		end)

		return true
	end,
	info = function(self, t)
		return ([[You can draw the arcane energy out of arcane powered items and use it to hasten your development.
		You can only drain items whose material level is at least your growth stage.]])
	end,
}

newTalent{
	name = "Direct Gaze",
	type = {"race/beholder-other", 1},
	mode = "sustained",
	no_energy = true,
	cooldown = function(self, t) return 6 - math.floor(self:getTalentTypeLevelRaw("spell/central-eye") / 5) end,
	target = function(self, t) return {type="hit", range=10, talent=t} end,
	sustain_mana = 0,
	getDuration = function(self, t)
		return 5 + math.floor(self:getTalentTypeLevelRaw("spell/central-eye") / 5)
	end,
	on_pre_use = function(self, t)
		if not self:getGaze() then return false end
		return true
	end,
	activate = function(self, t)
		-- local p = self.sustain_talents[t.id]
		local tg = {type="hit", range=10, talent=t} --self:getTalentTarget(t)
		local x, y, act = self:getTarget(tg)
		if not (x and y) or not act then return nil end
		--if act then p.tg = act else p.tg = {x, y} end

		--The sustain is considered as active until this data has been returned, so we draw the gaze once with the sustain technically inactive.
		local ret = {tg = act or {x=x, y=y}, beholder_sustain_dur=t.getDuration(self, t)}
		local tid = self:getGaze().id
		self:callTalent(self[tid], "drawGaze", ret)
		return ret
	end,
	deactivate = function(self, t, p) return true end,
	callbackOnActBase = function(self, t, ...)
		if not self:isTalentActive("T_DIRECT_GAZE") then
			return
		end

		local p = self.sustain_talents[t.id]
		if p.tg.dead or not (self:isTalentActive(self.T_DRAINING_GAZE) or self:isTalentActive(self.T_PARALYZING_GAZE)) then
			self:forceUseTalent(self.T_DIRECT_GAZE, {ignore_energy=true})
			self:startTalentCooldown(self.T_DIRECT_GAZE)
		end
	end,
	info = function(self, t)
		return ([[For up to %d turns, direct your gaze upon a target. The beholder's gaze abilities, if active, will be centred on the chosen target.

			For every 5 points in Central Eye and gaze talents, the cooldown will be reduced, and the maximum duration increased by 1.
			]])
		:format(t.getDuration(self, t))
	end,
}
