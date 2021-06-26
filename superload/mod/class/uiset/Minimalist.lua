local _M = loadPrevious(...)

local Shader = require "engine.Shader"
local UI = require "engine.ui.Base"

local frames_colors = {
	ok = {0.3, 0.6, 0.3},
	sustain = {0.6, 0.6, 0},
	cooldown = {0.6, 0, 0},
	disabled = {0.65, 0.65, 0.65},
}

local move_handle = {core.display.loadImage("/data/gfx/ui/move_handle.png"):glTexture()}

function _M:displayBuffs(scale, bx, by)
	local shader = Shader.default.textoutline and Shader.default.textoutline.shad

	local player = game.player

	local durs={}
	local txts={}

	if player then
		if player.changed then
			for _, d in pairs(self.pbuff) do if not player.sustain_talents[d[1]] then game.mouse:unregisterZone(d[2]) end end
			for _, d in pairs(self.tbuff) do if not player.tmp[d[1]] then game.mouse:unregisterZone(d[2]) end end
			self.tbuff = {} self.pbuff = {}
		end

		local orient = self.sizes.buffs and self.sizes.buffs.orient or "right"
		local hs = 40
		local x, y = 0, 0
		local is_first = true

		for tid, act in pairs(player.sustain_talents) do
			if act then
				if not self.pbuff[tid] or act.__update_display then
					if act.__update_display then game.mouse:unregisterZone("pbuff"..tid) end
					act.__update_display = false
					local t = player:getTalentFromId(tid)
					local displayName = t.name
					if t.getDisplayName then displayName = t.getDisplayName(player, t, player:isTalentActive(tid)) end

					if player.sustain_talents[tid].beholder_sustain_dur and player.sustain_talents[tid].beholder_sustain_dur > 0 then
						--A nice, long obfuscated name so that this functionality will not interfere with other addons
						local font = self.buff_font
						--dur = tostring(dur)
						txts[tid] = font:draw(tostring(player.sustain_talents[tid].beholder_sustain_dur) , 40, colors.WHITE.r, colors.WHITE.g, colors.WHITE.b, true)[1]
						txts[tid].fw, txts[tid].fh = font:size(tostring(player.sustain_talents[tid].beholder_sustain_dur))
					end

					local is_first = is_first
					local desc_fct = function(button, mx, my, xrel, yrel, bx, by, event)
						if is_first then
							if event == "out" then self.mhandle.buffs = nil return
							else self.mhandle.buffs = true end
							-- Move handle
							if not self.locked and bx >= self.mhandle_pos.buffs.x and bx <= self.mhandle_pos.buffs.x + move_handle[6] and by >= self.mhandle_pos.buffs.y and by <= self.mhandle_pos.buffs.y + move_handle[7] then self:uiMoveResize("buffs", button, mx, my, xrel, yrel, bx, by, event) end
						end
						local desc = "#GOLD##{bold}#"..displayName.."#{normal}##WHITE#\n"..tostring(player:getTalentFullDescription(t))
						game.tooltip_x, game.tooltip_y = 1, 1; game:tooltipDisplayAtMap(game.w, game.h, desc)
					end
					self.pbuff[tid] = {tid, "pbuff"..tid, function(x, y)
						core.display.drawQuad(x+4, y+4, 32, 32, 0, 0, 0, 255)
						t.display_entity:toScreen(self.hotkeys_display_icons.tiles, x+4, y+4, 32, 32)
						UI:drawFrame(self.buffs_base, x, y, frames_colors.sustain[1], frames_colors.sustain[2], frames_colors.sustain[3], 1)

						if txts[tid] then
							if shader then
								shader:use(true)
								shader:uniOutlineSize(1, 1)
								shader:uniTextSize(txts[tid]._tex_w, txts[tid]._tex_h)
							else
								txts[tid]._tex:toScreenFull(x+4+2 + (32 - txts[tid].fw)/2, y+4+2 + (32 - txts[tid].fh)/2, txts[tid].w, txts[tid].h, txts[tid]._tex_w, txts[tid]._tex_h, 0, 0, 0, 0.7)
							end
						txts[tid]._tex:toScreenFull(x+4 + (32 - txts[tid].fw)/2, y+4 + (32 - txts[tid].fh)/2, txts[tid].w, txts[tid].h, txts[tid]._tex_w, txts[tid]._tex_h)
						end


					end, desc_fct}
				end

				if not game.mouse:updateZone("pbuff"..tid, bx+x*scale, by+y*scale, hs, hs, nil, scale) then
					game.mouse:unregisterZone("pbuff"..tid)
					game.mouse:registerZone(bx+x*scale, by+y*scale, hs, hs, self.pbuff[tid][4], nil, "pbuff"..tid, true, scale)
				end

				self.pbuff[tid][3](x, y)

				is_first = false
				x, y = self:buffOrientStep(orient, bx, by, scale, x, y, hs, hs)
			end
		end


		local good_e, bad_e = {}, {}
		for eff_id, p in pairs(player.tmp) do
			local e = player.tempeffect_def[eff_id]
			if e.status == "detrimental" then bad_e[eff_id] = p else good_e[eff_id] = p end
		end

		for eff_id, p in pairs(good_e) do
			local e = player.tempeffect_def[eff_id]
			self:handleEffect(player, eff_id, e, p, x, y, hs, bx, by, is_first, scale, (e.status == "beneficial") or config.settings.cheat)
			is_first = false
			x, y = self:buffOrientStep(orient, bx, by, scale, x, y, hs, hs)
		end

		x, y = self:buffOrientStep(orient, bx, by, scale, x, y, hs, hs, true)

		for eff_id, p in pairs(bad_e) do
			local e = player.tempeffect_def[eff_id]
			self:handleEffect(player, eff_id, e, p, x, y, hs, bx, by, is_first, scale, config.settings.cheat)
			is_first = false
			x, y = self:buffOrientStep(orient, bx, by, scale, x, y, hs, hs)
		end

		if not self.locked then
			move_handle[1]:toScreenFull(40 - move_handle[6], 0, move_handle[6], move_handle[7], move_handle[2], move_handle[3])
		end

		if orient == "down" or orient == "up" then
			self:computePadding("buffs", bx, by, bx + x * scale + hs, by + hs)
		else
			self:computePadding("buffs", bx, by, bx + hs, by + y * scale + hs)
		end
	end

	if self.drawPassiveCooldownTrackers then
		self:drawPassiveCooldownTrackers(scale, bx, by)
	end
end
