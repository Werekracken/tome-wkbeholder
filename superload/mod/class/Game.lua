local _M = loadPrevious(...)

local base_changeLevelReal = _M.changeLevelReal

function _M:changeLevelReal(lev, zone, params)
	base_changeLevelReal(self, lev, zone, params)

	if self.player:isTalentActive(self.player.T_DRAINING_GAZE) then
		self.player:callTalent("T_DRAINING_GAZE", "drawGaze")
	end
	if self.player:isTalentActive(self.player.T_PARALYZING_GAZE) then
		self.player:callTalent("T_PARALYZING_GAZE", "drawGaze")
	end
end
