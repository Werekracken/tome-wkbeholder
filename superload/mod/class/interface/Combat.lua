local _M = loadPrevious(...)

local base_bumpInto = _M.bumpInto

function _M:bumpInto(target, x, y)
	if not x or not y then x, y = target.x, target.y end
	self.facing_direction = util.getDir(x, y, self.x, self.y)
	base_bumpInto(self, target, x, y)
end

return _M
