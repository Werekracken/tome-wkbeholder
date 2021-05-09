newTalent{
	name = "Armour Training",
	type = {"technique/combat-training", 1},
	ArmorEffect = function(self, t)  -- Becomes more effective with heavier armors
		local am = self:getInven("BODY") and self:getInven("BODY")[1]
		if not am then return 0 end
--		if am.subtype == "cloth" then return 0.75
--		elseif am.subtype == "light" then return 1.0
		if am.subtype == "cloth" then return 0
		elseif am.subtype == "light" then return 0
		elseif am.subtype == "heavy" then return 1.5
		elseif am.subtype == "massive" then	return 2.0
		end
		return 0
	end
}