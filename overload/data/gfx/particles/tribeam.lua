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

-- Make the ray
local ray = {}
local tiles = math.ceil(math.sqrt(tx*tx+ty*ty))
local tx = tx * engine.Map.tile_w
local ty = ty * engine.Map.tile_h
ray.dir = math.atan2(ty, tx)
ray.size = math.sqrt(tx*tx+ty*ty)

-- Populate the beam based on the forks
return { generator = function()
	local a = ray.dir
	--local possible = {1,16,32}
	local r = rng.range(1, ray.size - 32)
	--local id, r = rng.table(possible)
	local tile_size=engine.Map.tile_w * 0.60
	local ra = a + (rng.chance(2) and math.rad(-90) or math.rad(90))
	local rr = rng.float(2, engine.Map.tile_w * 1.20)
	
	local vel = rng.float(1.2, 6)
	if rr >=2 and rr<((tile_size-2)/3)  then
	rr=2
	return {
		life = 32 / vel,
		size = rng.float(4, 10), sizev = -0.1, sizea = 0,
		
		x = r * math.cos(a) + rr * math.cos(ra), xv = 0, xa = 0,
		y = r * math.sin(a) + rr * math.sin(ra), yv = 0, ya = 0,
		dir = ray.dir, dirv = 0, dira = 0,
		vel = vel, velv = -0.1, vela = 0.01,
		
		r = rng.range(140, 200)/255, rv = 0, ra = 0,
		g = rng.range(180, 220)/255, gv = 0, ga = 0,
		b = rng.range(220, 240)/255, bv = 0, ba = 0,
		a = rng.range(230, 255)/255, av = 0, aa = 0,
	}
	end
	if rr >=((tile_size-2)/3)  and ra>a  then
	rr=((tile_size-2)/2)
	return {
		life = 32 / vel,
		size = rng.float(4, 10), sizev = -0.1, sizea = 0,
		
		x = r * math.cos(a) + rr * math.cos(ra)*(.8*(ray.size - 32 - 2-r)/(ray.size - 32 - 2)), xv = 0, xa = 0,
		y = r * math.sin(a) + rr * math.sin(ra)*(.8*(ray.size - 32 - 2-r)/(ray.size - 32 - 2)), yv = 0, ya = 0,
		dir = ray.dir, dirv = 0, dira = 0,
		vel = vel, velv = -0.1, vela = 0.01,
		
		r = 0,   rv = 0, ra = 0,
		g = rng.range(170, 210)/255,   gv = 0, ga = 0,
		b = rng.range(200, 255)/255,   gv = 0, ga = 0,
		a = rng.range(230, 225)/255,   av = 0, aa = 0,
	}
	end
	if rr >=((tile_size-2)/3)  and ra<a  then
	rr=((tile_size-2)/2)
	return {
		life = 32 / vel,
		size = rng.float(4, 10), sizev = -0.1, sizea = 0,

		x = r * math.cos(a) + rr * math.cos(ra)*((ray.size - 32 - 2-r)/(ray.size - 32 - 2)), xv = 0, xa = 0,
		y = r * math.sin(a) + rr * math.sin(ra)*((ray.size - 32 - 2-r)/(ray.size - 32 - 2)), yv = 0, ya = 0,
		dir = ray.dir, dirv = 0, dira = 0,
		vel = vel, velv = -0.1, vela = 0.01,
		
		r = rng.range(220, 255)/255,  rv = 0, ra = 0,
		g = rng.range(200, 230)/255,  gv = -0.04, ga = 0,
		b = 0,                        bv = 0, ba = 0,
		a = rng.range(25, 220)/255,   av = 0, aa = 0,
	}
	end
	
end, },
function(self)
	self.nb = (self.nb or 0) + 1
	if self.nb < 6 then
		self.ps:emit(9*tiles)
	end
end,
128*10*tiles
