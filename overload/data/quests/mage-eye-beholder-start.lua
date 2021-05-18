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

name = "Crash Landing"
desc = function(self, who)
	local desc = {}
	desc[#desc+1] = "Your colony has sent you on a mission to investigate a recently detected burst of magical energy in this area of space.\n"
	desc[#desc+1] = "You unfortunately have crash landed on this planet and need to regain your powers by draining magical items.\n"

	--desc[#desc+1] = ("\nCurrent growth points: #LIGHT_GREEN#%0.2f#WHITE#."):format(who.growth_points)

	if who.growth_stage == 1 then
		desc[#desc+1] = "\nCurrent growth stage: #LIGHT_GREEN#1#WHITE#."
		desc[#desc+1] = "\nTotal growth bonuses: #GOLD#NONE#WHITE#."
		desc[#desc+1] = ("\nGrowth points needed for next stage: #LIGHT_GREEN#%d#WHITE#."):format(who.growth_curve[1])
	end
	if who.growth_stage == 2 then
		desc[#desc+1] = "\nCurrent growth stage: #LIGHT_GREEN#2#WHITE#."
		desc[#desc+1] = "\nTotal growth bonuses: #GOLD#+1 life rating(retroactive), +10% armor hardiness, +3 armor, +20% blindness resistance, +50 max air, +10% movement speed, +2 infravision#WHITE#."
		desc[#desc+1] = ("\nGrowth points needed for next stage: #LIGHT_GREEN#%d#WHITE#."):format(who.growth_curve[2])
	end
	if who.growth_stage == 3 then
		desc[#desc+1] = "\nCurrent growth stage: #LIGHT_GREEN#3#WHITE#."
		desc[#desc+1] = "\nTotal growth bonuses: #GOLD#+2 life rating(retroactive), +20% armor hardiness, +6 armor, +40% blindness resistance, +100 max air, +20% movement speed, +4 infravision, size: Medium#WHITE#."
		desc[#desc+1] = "\n#GOLD#+1 class points."
		desc[#desc+1] = ("\nGrowth points needed for next stage: #LIGHT_GREEN#%d#WHITE#."):format(who.growth_curve[3])
	end
	if who.growth_stage == 4 then
		desc[#desc+1] = "\nCurrent growth stage: #LIGHT_GREEN#4#WHITE#."
		desc[#desc+1] = "\nTotal growth bonuses: #GOLD#+3 life rating(retroactive), +30% armor hardiness, +9 armor, +60% blindness resistance, +150 max air, +30% movement speed, +6 infravision, size: Big#WHITE#."
		desc[#desc+1] = "\n#GOLD#+1 class points."
		desc[#desc+1] = ("\nGrowth points needed for next stage: #LIGHT_GREEN#%d#WHITE#."):format(who.growth_curve[4])
	end
	if who.growth_stage == 5 then
		desc[#desc+1] = "\nCurrent growth stage: #LIGHT_GREEN#5#WHITE#."
		desc[#desc+1] = "\nTotal growth bonuses: #GOLD#+4 life rating(retroactive), +40% armor hardiness, +12 armor, +80% blindness resistance, underwater breathing, +35% movement speed, +8 infravision, size: Huge#WHITE#."
		desc[#desc+1] = "\n#GOLD#+2 class points."
		desc[#desc+1] = "\nYou have grown as large as you can."
	end
	return table.concat(desc, "\n")
end

on_grant = function(self, who, status, sub)
	who.moddable_tile_ornament=nil
	who.moddable_tile = "runic_golem" -- change from beholder to runic_golem so we can show equipment on the character
	who:removeAllMOs()
	who.image="player/human_male/base_shadow_01.png"
	who.add_mos = {{image="player/runic_golem/"..(who.true_moddable_tile_base)}}
	game.level.map:updateMap(who.x, who.y)
	who:updateModdableTile()

	if who.inven[who["INVEN_FEET"]] then
		who.inven[who["INVEN_FEET"]] = nil
	end
	if who.inven[who["INVEN_BODY"]] then
		who.inven[who["INVEN_BODY"]] = nil
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
