local Stats = require "engine.interface.ActorStats"
--local Talents = require "engine.interface.ActorTalents"
--local Dialog = require "engine.ui.Dialog"

newEntity{ base = "BASE_RING",
	define_as = "BEHOLDER_SOCKET_RING",
	power_source = {arcane=true},
	plot = true,
	unique = true,
	color = colors.YELLOW,
	image = "object/artifact/beholder_bracelet_base.png",
	name = "Ring of Command",-- lore="diary-draconian",
	desc = [[Using the remains of your escape pod, you fashioned this simple band. A gem could be placed within to enhance its properties.]],
	cost = 1,
	material_level = 1,
	rarity = false,
	encumberance = 0,
	max_power = 25, power_regen = 1,
	use_power = { name = "Socket Gem", power = 25,
		use = function(self, who)
			local d
			local BeholderStats = require "engine.interface.ActorStats"

			d = who:showInventory("Use which gem?", who:getInven("INVEN"), function(gem) return gem.type == "gem" and gem.imbue_powers and gem.material_level end,
				function(gem, gem_item)
				who:onTakeoff(self)
				local name_old=self.name
				local old_hotkey
				for i, v in pairs(who.hotkey) do
					if v[2]==name_old then
						old_hotkey=i
					end
				end
				self._mo = nil
				self._last_mo = nil
				local old_gem=self.Gem
				if old_gem then
					who:addObject(who:getInven("INVEN"), old_gem)
					game.logPlayer(who, "You remove your %s.", old_gem:getName{do_colour=true, no_count=true})
				end
				self.Gem=nil
				self.wielder = { inc_stats = {[BeholderStats.STAT_MAG] = 1,[BeholderStats.STAT_WIL] = 1,},combat_armor = 1}
				self.name = "Ring of Command"
				self.image ="object/artifact/beholder_bracelet_base.png"
				self.Gem=gem
				if gem then
					who:removeObject(who:getInven("INVEN"), gem_item)
					self.wielder = { inc_stats = {[BeholderStats.STAT_MAG] = 1+math.floor(gem.material_level/2),[BeholderStats.STAT_WIL] = 1+math.floor(gem.material_level/2),},combat_armor = 1+2*gem.material_level}
					self.material_level=gem.material_level
					if gem.subtype =="black" then
						self.image ="object/artifact/beholder_bracelet_black.png"
					end
					if gem.subtype =="blue" then
						self.image ="object/artifact/beholder_bracelet_blue.png"
					end
					if gem.subtype =="green" then
						self.image ="object/artifact/beholder_bracelet_green.png"
					end
					if gem.subtype =="red" then
						self.image ="object/artifact/beholder_bracelet_red.png"
					end
					if gem.subtype =="violet" then
						self.image ="object/artifact/beholder_bracelet_violet.png"
					end
					if gem.subtype =="white" then
						self.image ="object/artifact/beholder_bracelet_white.png"
					end
					if gem.subtype =="yellow" then
						self.image ="object/artifact/beholder_bracelet_yellow.png"
					end
					if gem.subtype == "multi-hued"  then
						self.image ="object/artifact/beholder_bracelet_multihued.png"
					end
					game.logPlayer(who, "You imbue your %s with %s.", self:getName{do_colour=true, no_count=true}, gem:getName{do_colour=true, no_count=true})
					self.name = "Ring of Command ("..gem.name..")"
					table.mergeAdd(self.wielder, gem.imbue_powers, true)

				end
				who:onWear(self)
				for i, v in pairs(who.hotkey) do
					if v[2]==name_old then
						v[2]=self.name
					end
					if v[2]==self.name and old_hotkey and i~=old_hotkey then
						who.hotkey[i] = nil
					end
				end
				d.used_talent=true
				game:unregisterDialog(d)
				return true
			end)

			--local co = coroutine.running()
			--d.unload = function(self) coroutine.resume(co, self.used_talent) end
			--if not coroutine.yield() then return nil end

			return {id=true, used=true}
		end
	},
	on_wear = function(self, who)
		if not who.hasQuest or not who.hasQuest("mage-eye-beholder-start") then
			who:grantQuest("mage-eye-beholder-start")
		end

		return true
	end,
	wielder = {
		inc_stats = {
			[Stats.STAT_MAG] = 1,
			[Stats.STAT_WIL] = 1,
		},
		combat_armor = 1,
	},
}
