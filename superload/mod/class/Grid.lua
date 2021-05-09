local _M = loadPrevious(...)

local base_block_move = _M.block_move

function _M:block_move(x, y, e, act, couldpass)
	local ret = base_block_move(self, x, y, e, act, couldpass)

	if self.door_opened and act then
		if e and e:getGaze() then
			e.facing_direction = util.getDir(x, y, e.x, e.y)
			e:callTalent(e[e:getGaze().id], "drawGaze")
		end
	end

	return ret
end

return _M
