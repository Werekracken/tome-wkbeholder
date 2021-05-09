--Add new target type
local _M = loadPrevious(...)

local base_getType = _M.getType

local Map = require "engine.Map"

function _M:getType(t)
	t = base_getType(self,t)
	if t.type then
		if t.type:find("eye") then
--			t.cone = t.radius
--			t.cone_angle = t.cone_angle or 55
			t.selffire = true
			t.eye = t.radius
			t.eye_angle = t.eye_angle or 55
			--table.update(t, target_type)
		end
	end
	return t
end

local base_realDisplay = _M.realDisplay

function _M:realDisplay(dispx, dispy)
	base_realDisplay(self,dispx,dispy)

	local final_x, final_y

	if not self.target_type.source_actor then
		self.target_type.source_actor = self.source_actor
	end

	if self.target_type.eye and self.target_type.eye > 0 then
		if self.target.entity and self.target.entity.x and self.target.entity.y and game.level.map.seens(self.target.entity.x, self.target.entity.y) then
			self.target.x, self.target.y = self.target.entity.x, self.target.entity.y
		end

		self.target.x = self.target.x or self.source_actor.x
		self.target.y = self.target.y or self.source_actor.y

		local l = self.target_type.source_actor:lineFOV(self.target.x, self.target.y, nil, nil, self.target_type.start_x, self.target_type.start_y)
		final_x, final_y = l:step()

		-- if not final_x then final_x = self.source_actor.x end
		-- if not final_y then final_y = self.source_actor.y end
		if not final_x or not final_y then
			if self.source_actor.facing_direction then
				local dx, dy = util.dirToCoord(self.source_actor.facing_direction, self.source_actor.x, self.source_actor.y)
				final_x, final_y = self.source_actor.x+dx, self.source_actor.y+dy
			else final_x, final_y = self.source_actor.x, self.source_actor.y
			end
			self.target.x, self.target.y=final_x, final_y
		end

		self.target.entity = nil

		local ox, oy = self.display_x, self.display_y
		local sx, sy = game.level.map._map:getScroll()
		local stop_x, stop_y = self.target_type.start_x, self.target_type.start_y
		local stop_radius_x, stop_radius_y = self.target_type.start_x, self.target_type.start_y

		sx = sx + game.level.map.display_x
		sy = sy + game.level.map.display_y
		self.display_x, self.display_y = dispx or sx or self.display_x, dispy or sy or self.display_y
		local display_highlight
		if util.isHex() then
			display_highlight = function(texture, tx, ty)
				texture:toScreenHighlightHex(
					self.display_x + (tx - game.level.map.mx) * self.tile_w * Map.zoom,
					self.display_y + (ty - game.level.map.my + util.hexOffset(tx)) * self.tile_h * Map.zoom,
					self.tile_w * Map.zoom,
					self.tile_h * Map.zoom)
				end
		else
			display_highlight = function(texture, tx, ty)
				texture:toScreen(
					self.display_x + (tx - game.level.map.mx) * self.tile_w * Map.zoom,
					self.display_y + (ty - game.level.map.my) * self.tile_h * Map.zoom,
					self.tile_w * Map.zoom,
					self.tile_h * Map.zoom)
				end
		end

		core.fov.calc_beam_any_angle(
			stop_radius_x,
			stop_radius_y,
			game.level.map.w,
			game.level.map.h,
			self.target_type.eye,
			self.target_type.eye_angle,
			self.target_type.start_x,
			self.target_type.start_y,
			final_x - self.target_type.start_x,
			final_y - self.target_type.start_y,
			function(_, px, py)
				if self.target_type.block_radius and self.target_type:block_radius(px, py, true) then return true end
			end,
			function(_, px, py)
				if not self.target_type.no_restrict and not game.level.map.remembers(px, py) and not game.level.map.seens(px, py) then
					display_highlight(self.syg, px, py)
				else
					display_highlight(self.sg, px, py)
				end
			end,
		nil)
	end
end

return _M
