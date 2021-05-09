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
local nb = 2

return { blend_mode=core.particles.BLEND_ADDITIVE, generator = function()
	local ad = rng.range(20+90, 160+90)
	local a = math.rad(ad)
	local dir = math.rad(ad + 90)
	local r = rng.range(1, 36)
	local dirv = math.rad(rng.float(-0.5,0.5))
	local life = 9

	return {
		trail = 1,
		life = life,
		size = rng.range(16, 20), sizev = 0, sizea = 0,

		x = r * math.cos(a), xv = -0.1, xa = 0,
		y = r * math.sin(a), yv = -0.1, ya = 0,
		dir = dir, dirv = dirv, dira = 0, --dirv/life,
		vel = rng.float(0.15, 0.5), velv = 0, vela = 0,

		r = rng.range(30, 80)/255,   rv = 0, ra = 0,
		g = rng.range(0, 0)/255,   gv = 0, ga = 0,
		b = rng.range(80, 200)/255,      bv = 0, ba = 0,
		a = rng.range(6, 10)/255,    av = 0, aa = 0,
	}
end, },
function(self)
	if nb > 0 then
		self.ps:emit(4)
	end
	nb = nb - 1
	if nb == -3 then nb = 1 end
end,
40, "particle_cloud"
