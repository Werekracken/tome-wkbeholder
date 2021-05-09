--Add new target type
--local Target = require "engine.Target"
local _M = loadPrevious(...)

local base_project = _M.project

function _M:project(t, x, y, damtype, dam, particles)
	--local typ_new = Target:getType(t)
	if t.type:find("eye") then
		print("setting")
		t.type="cone"
		t.cone = t.eye
		t.cone_angle = t.eye_angle or 55
	end
	local grids, stop_x, stop_y = base_project(self,t, x, y, damtype, dam, particles)

	return grids, stop_x, stop_y
end

return _M