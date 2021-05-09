local _M = loadPrevious(...)

function _M:learnType(tt, v)
	self.talent_types_learned[tt] = self.talent_types_learned[tt] or {}
	if v then
		if self.actor:knowTalentType(tt) and self.actor.__increased_talent_types[tt] and self.actor.__increased_talent_types[tt] >= 1 then
			self:simplePopup("Impossible", "You can only improve a category mastery once!")
			return
		end
		if self.actor.descriptor.race == "Beholder" then
			if self.actor.talents_types_def[tt].beholder_growth_req and not self.actor:knowTalentType(tt) then
				local req = self.actor.talents_types_def[tt].beholder_growth_req
				local to_go = req-self.actor.growth_stage
				if to_go > 0 then
					self:simpleLongPopup("Beholder growth requirement",
						([[You must reach the %s beholder growth stage to unlock this talent tree.

That means there's %d more %s to go!

Perhaps it's time to refuel by dining out at one of those lovely Shaloren restaurants... or what was it they call them here in Maj'Eyal, was it "libraries"? "Magic item shops", or something like that? Who cares, it's all the same deliciousness...
							]]):format(string.ordinal(req), to_go, (to_go==1 and "stage" or "stages")), 400)
					return
				end
			end
		end
		if self.actor.unused_talents_types <= 0 then
			self:simplePopup("Not enough talent category points", "You have no category points left!")
			return
		end
		if not self.actor.talents_types_def[tt] or (self.actor.talents_types_def[tt].min_lev or 0) > self.actor.level then
			self:simplePopup("Too low level", ("This talent tree only provides talents starting at level %d. Learning it now would be useless."):format(self.actor.talents_types_def[tt].min_lev))
			return
		end
		if not self.actor:knowTalentType(tt) then
			self.actor:learnTalentType(tt)
			self.talent_types_learned[tt][1] = true
		else
			self.actor.__increased_talent_types[tt] = (self.actor.__increased_talent_types[tt] or 0) + 1
			self.actor:setTalentTypeMastery(tt, self.actor:getTalentTypeMastery(tt) + 0.2)
			self.talent_types_learned[tt][2] = true
		end
		self:triggerHook{"PlayerLevelup:addTalentType", actor=self.actor, tt=tt}
		self.actor.unused_talents_types = self.actor.unused_talents_types - 1
		self.new_talents_changed = true
	else
		if self.actor_dup:knowTalentType(tt) == true and self.actor:knowTalentType(tt) == true and (self.actor_dup.__increased_talent_types[tt] or 0) >= (self.actor.__increased_talent_types[tt] or 0) then
			self:simplePopup("Impossible", "You cannot take out more points!")
			return
		end
		if self.actor_dup:knowTalentType(tt) == true and self.actor:knowTalentType(tt) == true and (self.actor.__increased_talent_types[tt] or 0) == 0 then
			self:simplePopup("Impossible", "You cannot unlearn this category!")
			return
		end
		if not self.actor:knowTalentType(tt) then
			self:simplePopup("Impossible", "You do not know this category!")
			return
		end

		if (self.actor.__increased_talent_types[tt] or 0) > 0 then
			self.actor.__increased_talent_types[tt] = (self.actor.__increased_talent_types[tt] or 0) - 1
			self.actor:setTalentTypeMastery(tt, self.actor:getTalentTypeMastery(tt) - 0.2)
			self.actor.unused_talents_types = self.actor.unused_talents_types + 1
			self.new_talents_changed = true
			self.talent_types_learned[tt][2] = nil
		else
			self.actor:unlearnTalentType(tt)
			local ok, dep_miss = self:checkDeps()
			if ok then
				self.actor.unused_talents_types = self.actor.unused_talents_types + 1
				self.new_talents_changed = true
				self.talent_types_learned[tt][1] = nil
			else
				self:simpleLongPopup("Impossible", "You cannot unlearn this category because of: "..dep_miss, game.w * 0.4)
				self.actor:learnTalentType(tt)
				return
			end
		end
		self:triggerHook{"PlayerLevelup:subTalentType", actor=self.actor, tt=tt}
	end
	self:updateTooltip()
end
