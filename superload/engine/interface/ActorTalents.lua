local _M = loadPrevious(...)

function _M:learnTalentType(tt, v)
	if v == nil then v = true end
	if self.talents_types[tt] then return end
	self.talents_types[tt] = v
	self.talents_types_mastery[tt] = self.talents_types_mastery[tt] or 0
	self.changed = true
	return true
end
