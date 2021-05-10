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
local ActorInventory = require "engine.interface.ActorInventory"
--local game = require "mod.class.Game"
--local player = require "mod.class.Player"
name = "Crash Landing"
desc = function(self, who)
	local desc = {}
	desc[#desc+1] = "Your colony has sent you on a mission to investigate a recently detected burst of magical energy in this area of space.\n"
	desc[#desc+1] = "You unfortunately have crash landed on this planet and need to regain your powers by draining magical items.\n"

	desc[#desc+1] = ("\nCurrent growth points: #LIGHT_GREEN#%0.2f#WHITE#."):format(who.growth_points)
	if who.growth_stage == 1 then
		desc[#desc+1] = ("\nNeeded for next level: #LIGHT_GREEN#%d#WHITE#."):format(who.growth_curve[1])
		desc[#desc+1] = "\nCurrent form bonuses: #GOLD#NONE#WHITE#."
	end
	if who.growth_stage == 2 then
		desc[#desc+1] = ("\nNeeded for next level: #LIGHT_GREEN#%d#WHITE#."):format(who.growth_curve[2])
		desc[#desc+1] = "\nCurrent form bonuses: #GOLD#+1 life rating(retroactive), +10% armor hardiness, +3 armor, +20% blindness resistance, +50 max air, +10% movement speed, +2 infravision#WHITE#."
	end
	if who.growth_stage == 3 then
		desc[#desc+1] = ("\nNeeded for next level: #LIGHT_GREEN#%d#WHITE#."):format(who.growth_curve[3])
		desc[#desc+1] = "\nCurrent form bonuses: #GOLD#+2 life rating(retroactive), +20% armor hardiness, +6 armor, +40% blindness resistance, +100 max air, +20% movement speed, +4 infravision#WHITE#."
		desc[#desc+1] = "\n#GOLD#+1 class points."
	end
	if who.growth_stage == 4 then
		desc[#desc+1] = ("\nNeeded for next level: #LIGHT_GREEN#%d#WHITE#."):format(who.growth_curve[4])
		desc[#desc+1] = "\nCurrent form bonuses: #GOLD#+3 life rating(retroactive), +30% armor hardiness, +9 armor, +60% blindness resistance, +150 max air, +30% movement speed, +6 infravision#WHITE#."
		desc[#desc+1] = "\n#GOLD#+1 class points."
	end
	if who.growth_stage == 5 then
		desc[#desc+1] = "\nYou have acquired all the magical power you need."
		desc[#desc+1] = "\nCurrent form bonuses: #GOLD#+4 life rating(retroactive), +40% armor hardiness, +12 armor, +80% blindness resistance, underwater breathing, +35% movement speed, +8 infravision#WHITE#."
		desc[#desc+1] = "\n#GOLD#+2 class points."
	end
	return table.concat(desc, "\n")
end

on_grant = function(self, who, status, sub)
	--game.log(who.inven_def[1])

	who.moddable_tile = nil--"beholder"
	who.moddable_tile_base = nil--self.true_moddable_tile_base
	who.moddable_tile_nude = true
	who.moddable_tile_ornament=nil
	who:removeAllMOs()
	who.image="player/human_male/base_shadow_01.png"
	who.add_mos = {{image="player/beholder/"..(who.true_moddable_tile_base), display_h=.75,display_w=.75, display_y=.25, display_x=.15}}
	game.level.map:updateMap(who.x, who.y)
	who:updateModdableTile()

	--who:learnTalent(who.T_STAMINA_POOL, true)
	if who.inven[who["INVEN_FEET"]] then
		who.inven[who["INVEN_FEET"]] = nil
	end
	if who.inven[who["INVEN_BODY"]] then
		who.inven[who["INVEN_BODY"]] = nil
	end
	if who.inven[who["INVEN_QUIVER"]] then
		who.inven[who["INVEN_QUIVER"]] = nil
	end
	if who.inven[who["INVEN_BELT"]] then
		who.inven[who["INVEN_BELT"]] = nil
	end
	if who.inven[who["INVEN_HANDS"]] then
		who.inven[who["INVEN_HANDS"]] = nil
	end
	if who.inven[who["INVEN_CLOAK"]] then
		who.inven[who["INVEN_CLOAK"]] = nil
	end
end

-- on_status_change = function(self, who, status, sub)
	-- if sub then
		-- if self:isCompleted("found-necklace") then
			-- who:grantQuest("starter-zones")
		-- end
	-- end
-- end
