function setupSummon(self, m, x, y, no_control)
	m.unused_stats = 0
	m.unused_talents = 0
	m.unused_generics = 0
	m.unused_talents_types = 0
	m.no_inventory_access = true
	m.no_points_on_levelup = true
	m.save_hotkeys = true
	m.ai_state = m.ai_state or {}
	m.ai_state.tactic_leash = 100
	-- Try to use stored AI talents to preserve tweaking over multiple summons
	m.ai_talents = self.stored_ai_talents and self.stored_ai_talents[m.name] or {}
	local main_weapon = self:getInven("MAINHAND") and self:getInven("MAINHAND")[1]
	m.life_regen = m.life_regen + (self:attr("nature_summon_regen") or 0)
	m:attr("combat_apr", self:combatAPR(main_weapon))
	m.inc_damage = table.clone(self.inc_damage, true)
	m.resists_pen = table.clone(self.resists_pen, true)
	m:attr("stun_immune", self:attr("stun_immune"))
	m:attr("blind_immune", self:attr("blind_immune"))
	m:attr("pin_immune", self:attr("pin_immune"))
	m:attr("confusion_immune", self:attr("confusion_immune"))
	m:attr("numbed", self:attr("numbed"))
	if game.party:hasMember(self) then
		local can_control = not no_control and self:knowTalent(self.T_SUMMON_CONTROL)

		m.remove_from_party_on_death = true
		game.party:addMember(m, {
			control=can_control and "full" or "no",
			type="summon",
			title="Summon",
			orders = {target=true, leash=true, anchor=true, talents=true},
			on_control = function(self)
				local summoner = self.summoner
				self:setEffect(self.EFF_SUMMON_CONTROL, 1000, {incdur=summoner:callTalent(summoner.T_SUMMON_CONTROL, "lifetime"), res=summoner:callTalent(summoner.T_SUMMON_CONTROL, "DamReduc")})
				self:hotkeyAutoTalents()
			end,
			on_uncontrol = function(self)
				self:removeEffect(self.EFF_SUMMON_CONTROL)
			end,
		})
	end
	m:resolve() m:resolve(nil, true)
	m:forceLevelup(self.level)
	game.zone:addEntity(game.level, m, "actor", x, y)
	game.level.map:particleEmitter(x, y, 1, "summon")

	-- Summons never flee
	m.ai_tactic = m.ai_tactic or {}
	m.ai_tactic.escape = 0

	local p = self:hasEffect(self.EFF_FRANTIC_SUMMONING)
	if p then
		p.dur = p.dur - 1
		if p.dur <= 0 then self:removeEffect(self.EFF_FRANTIC_SUMMONING) end
	end

	if m.wild_gift_detonate and self:isTalentActive(self.T_MASTER_SUMMONER) and self:knowTalent(self.T_GRAND_ARRIVAL) then
		local dt = self:getTalentFromId(m.wild_gift_detonate)
		if dt.on_arrival then
			dt.on_arrival(self, self:getTalentFromId(self.T_GRAND_ARRIVAL), m)
		end
	end

	if m.wild_gift_detonate and self:isTalentActive(self.T_MASTER_SUMMONER) and self:knowTalent(self.T_NATURE_CYCLE) then
		local t = self:getTalentFromId(self.T_NATURE_CYCLE)
		for _, tid in ipairs{self.T_RAGE, self.T_DETONATE, self.T_WILD_SUMMON} do
			if self.talents_cd[tid] and rng.percent(t.getChance(self, t)) then
				self.talents_cd[tid] = self.talents_cd[tid] - t.getReduction(self, t)
				if self.talents_cd[tid] <= 0 then self.talents_cd[tid] = nil end
				self.changed = true
			end
		end
	end

	if self:knowTalent(self.T_BLIGHTED_SUMMONING) then m:incIncStat("mag", self:getMag()) end

	self:attr("summoned_times", 1)
end

getEyeDelay = function(self)
	local delay = -1
	local p = self:hasEffect(self.EFF_DRAINED_EYESTALKS)
	if p then
		delay = delay + math.ceil(p.power/2)
	end
		return delay
end
damDesc = function(self, type, dam)
	-- Increases damage
	if self.inc_damage then
		local inc = (self.inc_damage.all or 0) + (self.inc_damage[type] or 0)
		dam = dam + (dam * inc / 100)
	end
	return dam
end
function combatStatTalentIntervalDamage(self,t, stat, min, max, stat_weight)
	local stat_weight = stat_weight or 0.5
	scaled_stat = self[stat](self)
	return self:rescaleDamage(min + (max - min)*((stat_weight * self[stat](self)/100) + (1 - stat_weight) * self:getTalentLevel(t)/6.5))
end
function combatTalentScale(self,t, low, high, power, add, shift, raw)
	local tl = type(t) == "table" and (raw and self:getTalentLevelRaw(t) or self:getTalentLevel(t)) or t
	power, add, shift = power or 0.5, add or 0, shift or 0
	local x_low, x_high = 1, 5 -- Implied talent levels to fit
	local x_low_adj, x_high_adj
	if power == "log" then
		x_low_adj, x_high_adj = math.log10(x_low+shift), math.log10(x_high+shift)
		tl = math.max(1, tl)
	else
		x_low_adj, x_high_adj = (x_low+shift)^power, (x_high+shift)^power
	end
	local m = (high - low)/(x_high_adj - x_low_adj)
	local b = low - m*x_low_adj
	if power == "log" then -- always >= 0
		return math.max(0, m * math.log10(tl + shift) + b + add)
	else
		return math.max(0, m * (tl + shift)^power + b + add)
	end
end

function combatTalentLimit(self,t, limit, low, high, raw)
	local x_low, x_high = 1,5 -- Implied talent levels for low and high values respectively
	local tl = type(t) == "table" and (raw and self:getTalentLevelRaw(t) or self:getTalentLevel(t)) or t
	if low then
		local p = limit*(x_high-x_low)
		local m = x_high*high - x_low*low
		local halfpoint = (p-m)/(high - low)
		local add = (limit*(x_high*low-x_low*high) + high*low*(x_low-x_high))/(p-m)
		return (limit-add)*tl/(tl + halfpoint) + add
	else
		local add = 0
		local halfpoint = limit*x_high/(high-add)-x_high
		return (limit-add)*tl/(tl + halfpoint) + add
	end
end

mage_stage_2 = function(self)
	self:attr("blind_immune",.2)
	self:attr("infravision",2)
	self:attr("movement_speed",.1)
	self:attr("max_air",50)
	self.air = self.air+50
	self:attr("combat_armor",3)
	self:attr("life_rating",1)
	self:attr("growth_stage",1)
	self:attr("combat_armor_hardiness",10)
	self.max_life = self.max_life + self.level
	self.true_moddable_tile_base = "beholder_phase_2.png"
	self.closed_moddable_tile_base = "beholder_phase_2_closedeye.png"
	if not self:isTalentActive(self.T_BEHOLDER_CLOAKING) then
		self.moddable_tile_base = self.true_moddable_tile_base
	end
	self:updateModdableTile()
	if not game:hasDialogUp(1) then require("engine.ui.Dialog"):simplePopup("Beholder Growth", "#GOLD#You feel a rush of power as your magical energy increases") end  --checks if dialogs open total >1, 1 will be open but on the player's turn we do not see that.
	game.level.map:particleEmitter(self.x, self.y, 1, "demon_teleport")
end

mage_stage_3 = function(self)
	self:attr("blind_immune",.2)
	self:attr("infravision",2)
	self:attr("movement_speed",.1)
	self:attr("max_air",50)
	self.air = self.air+50
	self:attr("combat_armor",3)
	self:attr("life_rating",1)
	self:attr("growth_stage",1)
	self:attr("combat_armor_hardiness",10)
	self.max_life = self.max_life + self.level
	self:attr("size_category",1)
	self:attr("unused_talents",1)
	self.true_moddable_tile_base = "beholder_phase_3.png"
	self.closed_moddable_tile_base = "beholder_phase_3_closedeye.png"
	if not self:isTalentActive(self.T_BEHOLDER_CLOAKING) then
		self.moddable_tile_base = self.true_moddable_tile_base
	end
	self:updateModdableTile()
	if not game:hasDialogUp(1) then require("engine.ui.Dialog"):simplePopup("Beholder Growth", "#GOLD#You feel a rush of power as your magical energy increases") end
	game.level.map:particleEmitter(self.x, self.y, 1, "demon_teleport")
end

mage_stage_4 = function(self)
	self:attr("blind_immune",.2)
	self:attr("infravision",2)
	self:attr("movement_speed",.1)
	self:attr("max_air",50)
	self.air = self.air+50
	self:attr("combat_armor",3)
	self:attr("life_rating",1)
	self:attr("growth_stage",1)
	self:attr("combat_armor_hardiness",10)
	self.max_life = self.max_life + self.level
	self:attr("size_category",1)
	self.true_moddable_tile_base = "beholder_phase_4.png"
	self.closed_moddable_tile_base = "beholder_phase_4_closedeye.png"
	if not self:isTalentActive(self.T_BEHOLDER_CLOAKING) then
		self.moddable_tile_base = self.true_moddable_tile_base
	end
	self:updateModdableTile()
	if not game:hasDialogUp(1) then require("engine.ui.Dialog"):simplePopup("Beholder Growth", "#GOLD#You feel a rush of power as your magical energy increases") end
	game.level.map:particleEmitter(self.x, self.y, 1, "demon_teleport")
end

mage_stage_5 = function(self)
	self:attr("blind_immune",.2)
	self:attr("infravision",2)
	self:attr("movement_speed",.05)
	self:attr("no_breath",1)
	self.air = self.max_air
	self:attr("combat_armor",3)
	self:attr("life_rating",1)
	self:attr("growth_stage",1)
	self:attr("combat_armor_hardiness",10)
	self.max_life = self.max_life + self.level
	self:attr("size_category",1)
	self:attr("avoid_pressure_traps",1)
	self:attr("unused_talents",1)
	self.max_life = self.max_life + self.level
	self.true_moddable_tile_base = "beholder_phase_5.png"
	self.closed_moddable_tile_base = "beholder_phase_5_closedeye.png"
	if not self:isTalentActive(self.T_BEHOLDER_CLOAKING) then
		self.moddable_tile_base = self.true_moddable_tile_base
	end
	self:updateModdableTile()
	if not game:hasDialogUp(1) then require("engine.ui.Dialog"):simplePopup("Beholder Growth", "#GOLD#You feel a rush of power as your magical energy increases") end
	game.level.map:particleEmitter(self.x, self.y, 1, "demon_teleport")
end

newTalentType{ allow_random=false, type="spell/fire-eye", name = "fire-eye", description = "Flame eye abilities" }
newTalentType{ allow_random=false, type="spell/frost-eye", name = "frost-eye", description = "Frost eye abilities" }
newTalentType{ allow_random=false, type="spell/lightning-eye", name = "lightning-eye", description = "Lightning eye abilities" }
newTalentType{ allow_random=false, type="spell/death-eye", name = "death-eye", description = "Death eye abilities\n\n#GOLD##BOLD#You must reach the 5th beholder growth stage to be able to learn this talent tree", beholder_growth_req = 5}
newTalentType{ allow_random=false, type="spell/tri-beam", name = "tri-beam", description = "Refocus your central eye's energies\n\n#GOLD##BOLD#You must reach the 3rd beholder growth stage to be able to learn this talent tree.", beholder_growth_req = 3 }
newTalentType{ allow_random=false, type="spell/central-eye", name = "central-eye", description = "Central eye anti-magic abilities" }
newTalentType{ allow_random=false, type="race/beholder-other", name = "beholder-other", generic = true, description = "Special beholder talents." }
newTalentType{ allow_random=false, type="race/beholder", name = "beholder", generic = true, description = "Basic abilities common to all Beholders." }
newTalentType{ allow_random=false, type="technique/tentacle-combat", name = "tentacle-combat", generic = true, description = "Strike nearby foes with your tentacles." }
-- newTalentType{ type="technique/ravenous-maw", name = "ravenous-maw", description = "Assail foes with your enormous maw and devour them whole, arcane energies and all." }

spells_req1 = {
	stat = { mag=function(level) return 12 + (level-1) * 2 end },
	level = function(level) return 0 + (level-1)  end,
}
spells_req2 = {
	stat = { mag=function(level) return 20 + (level-1) * 2 end },
	level = function(level) return 4 + (level-1)  end,
}
spells_req3 = {
	stat = { mag=function(level) return 28 + (level-1) * 2 end },
	level = function(level) return 8 + (level-1)  end,
}
spells_req4 = {
	stat = { mag=function(level) return 36 + (level-1) * 2 end },
	level = function(level) return 12 + (level-1)  end,
}
wil_req1 = {
	stat = { wil=function(level) return 12 + (level-1) * 2 end },
	level = function(level) return 0 + (level-1)  end,
}
wil_req2 = {
	stat = { wil=function(level) return 20 + (level-1) * 2 end },
	level = function(level) return 4 + (level-1)  end,
}
wil_req3 = {
	stat = { wil=function(level) return 28 + (level-1) * 2 end },
	level = function(level) return 8 + (level-1)  end,
}
wil_req4 = {
	stat = { wil=function(level) return 36 + (level-1) * 2 end },
	level = function(level) return 12 + (level-1)  end,
}

-- Useful definitions for psionic talents
function getGemLevel(self)
	local gem_level = 0
	if self:getInven("PSIONIC_FOCUS") then
		local tk_item = self:getInven("PSIONIC_FOCUS")[1]
		if tk_item and ((tk_item.type == "gem") or (tk_item.subtype == "mindstar") or tk_item.combat.is_psionic_focus == true) then
			gem_level = tk_item.material_level or 5
		end
	end
	if self:knowTalent(self.T_GREATER_TELEKINETIC_GRASP) and gem_level > 0 then
		if self:getTalentLevelRaw(self.T_GREATER_TELEKINETIC_GRASP) >= 5 then
			gem_level = gem_level + 1
		end
	end
	return gem_level
end

Talents = require "engine.interface.ActorTalents"

--Gaze helper function
--@param self source actor
--@param tid force to check a non-active gaze, or tid=nil retrieves current active gaze
--@param dir force a (numpad) direction, or dir=nil retreives current direction actor is facing
--@param force_radius force a radius, or force_radius=nil retrieves true radius
function getGazeGrids(self, tid, dir, force_radius)
	if not tid or not self.talents[tid] or not self.talents_def[tid].is_gaze then
		tid = self:getGaze() and self:getGaze().id
	end
	if not tid or not self.has_central_eye then
		--game.logPlayer(self, "Not a valid gaze!")
		return nil
	end
	local t = Talents.talents_def[tid]
	local tg = self:getTalentTarget(t)
	if force_radius then tg.radius=force_radius end
	if not dir then dir, _, _ = getGazeDirection(self) end
	local x, y = util.dirToCoord(dir, self.x, self.y)
	local grids = self:project(tg, self.x+x, self.y+y, function(px, py) return true end)
	return grids
end

--Gaze helper function
--Returns both the (numpad) direction and the square targeted
--@param self source actor
function getGazeDirection(self)
	-- local tid
	-- for t, _ in pairs(self.sustain_talents) do
	-- 	if t == "T_DRAINING_GAZE" then tid = "T_DRAINING_GAZE" end
	-- 	if t == "T_PARALYZING_GAZE" then tid = "T_PARALYZING_GAZE" end
	local t = self:getGaze()
	if not t.id then game.logPlayer(self, "Gaze not active!") return nil end
	if not self.has_central_eye then game.logPlayer(self, "No central eye.") return nil end
	local dir = self.facing_direction

	--WIP: this is where we get an error for passing an invalid parameter.
	--
	local dx, dy = util.dirToCoord(dir, self.x, self.y)
	local tx, ty = self.x+dx, self.y+dy
	return dir, tx, ty
end

--Gaze helper function
--Returns delta x, delta y for nicer Map.addEffect option
function getGazeDelta(self)
	local t = self:getGaze()
	if not t.id then game.logPlayer(self, "Gaze not active!") return nil end
	if not self.has_central_eye then game.logPlayer(self, "No central eye.") return nil end
	local dir = self.facing_direction
	local dx, dy = util.dirToCoord(dir, self.x, self.y)
	return dx, dy
end

--Gaze helper function
--Clears all gaze grids on current level for a given source actor
--@param self source actor
function purgeGazeGrids(self, type)
		--set up a list of effect grids we want to purge
		local kill_list_gs = {}
		--if type ~= "manadrain" or type ~= "paralyzing" then print("Bad gaze type sent to purgeGazeGrids!") end

		for i, eff in ipairs(game.level.map.effects) do
			if (string.find(eff:getName(), "MANADRAIN_GAZE") or string.find(eff:getName(), "PARALYZING_GAZE")) and eff.src == self then
				kill_list_gs[#kill_list_gs+1]=i
			end
			if string.find(eff:getName(), "LIFE_LEECH") and eff.src == self then
				kill_list_ps[#kill_list_ps+1]=i
			end
		end

		for i = #kill_list_gs, 1, -1 do --Run through the list in reverse as list order will be altered
			table.remove(game.level.map.effects, kill_list_gs[i])
		end
end
		--table.removeFromList(game.level.map.effects, unpack(kill_list_gs))

--Gaze helper function
--Clears all gaze grids on current level for a given source actor
--@param self source actor
function purgeGazeParticles(self, type)
		--set up a list of effect grids we want to purge
	local kill_list_gs = {}
	--if type ~= "manadrain" or type ~= "paralyzing" then print("Bad gaze type sent to purgeGazeGrids!") end
	for i, eff in ipairs(game.level.map.particles) do
		if eff.def=="manadrain" or eff.def == "paralyzing_gaze+" then
			eff.ps:die()
		end
	end
end

function handleDirectGaze(self, p, ret)
	--Recover the target coordinated from an active Direct Gaze's data
	if not ret and not self:isTalentActive(self.T_DIRECT_GAZE) then return nil end
	local ret = ret or self.sustain_talents.T_DIRECT_GAZE
	local tx, ty = ret.tg.x, ret.tg.y
	local x, y = self.x, self.y
	local dir = util.getDir(tx, ty, self.x, self.y)
	--Now we run a failsafe, because sometimes the aimed cone doesn't actually include the target.
	local found = false
	local dirs = {
		dir,
		util.dirSides(dir, self.x, self.y)["left"],
		util.dirSides(dir, self.x, self.y)["right"]
	}
	local distances = {100000, 100000, 100000}
	local delta_tg = math.ceil(math.sqrt(math.pow(math.abs(self.x-tx), 2)+math.pow(math.abs(self.y-ty), 2)))
	--We populate the distances table with distances from target to player when target is found
	for i, d in ipairs(dirs) do
		local grids = getGazeGrids(self, nil, d, self.sight or 10)
		for px, ys in pairs(grids) do
			for py, _ in pairs(ys) do
				if px == tx and py == ty then
					local dx, dy = util.dirToCoord(d, self.x, self.y)
					local mod = 1
					if (d % 2 == 1) then mod = 1/1.414 end
					--Compare the target to other points at an equal distance from selfs
					local centre_x, centre_y = self.x+dx*delta_tg*mod, self.y+dy*delta_tg*mod
					--Use Pythagoras to find distance of target from desired point
					local delta = math.sqrt(math.pow(math.abs(centre_x-px), 2)+math.pow(math.abs(centre_y-py), 2))
					distances[i] = delta
				end
			end
		end
	end
	--And then we choose the cone whose median line has the smallest distance from the target.
	local choice = 1

	for i, d in ipairs(dirs) do
		local delta = distances[i]
		if delta then
			if delta < distances[choice] then choice = i end
		end
	end

	self.facing_direction = dirs[choice]

	return true
end

load("/data-wkbeholder/talents/beholder.lua")
load("/data-wkbeholder/talents/fireeye.lua")
load("/data-wkbeholder/talents/frosteye.lua")
load("/data-wkbeholder/talents/lightningeye.lua")
load("/data-wkbeholder/talents/deatheye.lua")
load("/data-wkbeholder/talents/tentaclecombat.lua")
load("/data-wkbeholder/talents/tribeam.lua")
load("/data-wkbeholder/talents/centraleye.lua")
-- load("/data-wkbeholder/talents/ravenous-maw.lua")
