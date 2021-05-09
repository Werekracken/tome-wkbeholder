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

base_size = 32

local base_w = engine.Map.tile_w
local base_h = engine.Map.tile_h
local first = true
local nb = 50

return { blend_mode=core.particles.BLEND_ADDITIVE, generator = function()

	--local bx = math.floor(x / engine.Map.tile_w)
	--local by = math.floor(y / engine.Map.tile_h) 

	return {
		trail = 0,
		life = core.particles.ETERNAL,

		size = 32, sizev = 0, sizea = 0,

		x = 0, xv = 0, xa = 0,
		y = 0, yv = 0, ya = 0,
		vel = 0, velv = 0, vela = 0,

		r = 0.8125, rv = 0, ra =0,
		g = 0.8, gv = 0, ga = 0,
		b = 0.75, bv = 0, ba = 0,
		a = 0.28, av = 0, aa = 0,
	}
end, },
function(self)
	if first then self.ps:emit(1) first = false end
end,
40, "particles_images/square"
