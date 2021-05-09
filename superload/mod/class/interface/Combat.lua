local _M = loadPrevious(...)

local base_bumpInto = _M.bumpInto

function _M:bumpInto(target, x, y)
	self.facing_direction = util.getDir(x, y, self.x, self.y)
	base_bumpInto(self, target, x, y)
end

return _M
