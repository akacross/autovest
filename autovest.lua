script_name("autovest")
script_version("0.4")
script_author("akacross")

require"lib.moonloader"
require"lib.sampfuncs"
require 'extensions-lite'

local imgui, ffi = require 'mimgui', require 'ffi'
local new, str, sizeof = imgui.new, ffi.string, ffi.sizeof
local sampev = require 'lib.samp.events'
local https = require 'ssl.https'
local vk = require 'vkeys'
local wm  = require 'lib.windows.message'
local faicons = require 'fa-icons'
local ti = require 'tabler_icons'
local fa = require 'fAwesome5'
local encoding = require 'encoding'
encoding.default = 'CP1251'
local u8 = encoding.UTF8
local path = getWorkingDirectory() .. '\\config\\' 
local cfg = path .. 'autovest.ini'

local _enabled = true
local move = {false, false}
local autoaccepter = false
local autoacceptertoggle = false
local _last_vest = 0
local _menu = 1
local sampname = 'Nobody'
local playerid = -1
local sampname2 = 'Nobody'
local playerid2 = -1
local cooldown = 0
local specstate = false
local updateskin = false
local temp_pos = {x = 0, y = 0}
local skins = {}
local factions = {61, 71, 73, 141, 163, 164, 165, 166, 191, 255, 265, 266, 267, 280, 281, 282, 283, 284, 285, 286, 287, 288, 294, 312, 300, 301, 306, 309, 310, 311, 120}
local factions_color = {-14269954, -7500289, -14911565}
local menu = new.bool(false)
local blank = {}
local autovest = {
	autosave = true,
	ddmode = false,
	factionboth = false,
	enablebydefault = true,
	sound = true,
	timercorrection = true,
	notification = {true,true},
	vestmode = 2,
	timer = 12,
	skinsurl = "https://dickwhitman.do.am/skins.html",
	autovestcmd = "autovest",
	autoacceptercmd = "av",
	ddmodecmd = "ddmode",
	vestmodecmd = "vestmode",
	factionbothcmd = "factionboth",
	autovestsettingscmd = "autovest.settings",
	offerpos = {500, 500},
	offeredpos = {700, 500}
}

local function loadIconicFont(fontSize, min, max, fontdata)
    local config = imgui.ImFontConfig()
    config.MergeMode = true
    config.PixelSnapH = true
    local iconRanges = imgui.new.ImWchar[3](min, max, 0)
    imgui.GetIO().Fonts:AddFontFromMemoryCompressedBase85TTF(fontdata, fontSize, config, iconRanges)
end

imgui.OnInitialize(function()
	apply_custom_style() -- apply custom style

	loadIconicFont(18, ti.min_range, ti.max_range, ti.get_font_data_base85())
	loadIconicFont(14, faicons.min_range, faicons.max_range, faicons.get_font_data_base85())

	local config = imgui.ImFontConfig()
    config.MergeMode = true
    local glyph_ranges = imgui.GetIO().Fonts:GetGlyphRangesCyrillic()
    local iconRanges = imgui.new.ImWchar[3](fa.min_range, fa.max_range, 0)
    imgui.GetIO().Fonts:AddFontFromFileTTF('trebucbd.ttf', 14.0, nil, glyph_ranges)
    imgui.GetIO().Fonts:AddFontFromFileTTF('moonloader/resource/fonts/fa-solid-900.ttf', 14.0, config, iconRanges)

	imgui.GetIO().ConfigWindowsMoveFromTitleBarOnly = true
	imgui.GetIO().IniFilename = nil
end)

imgui.OnFrame(function() return autovest.notification[1] and _enabled and not isGamePaused() end,
function()
	imgui.SetNextWindowPos(imgui.ImVec2(autovest.offerpos[1], autovest.offerpos[2]), imgui.Cond.Always)
	imgui.Begin("offer", nil, imgui.WindowFlags.NoTitleBar + imgui.WindowFlags.NoResize + imgui.WindowFlags.NoCollapse + imgui.WindowFlags.NoMove + imgui.WindowFlags.NoScrollbar + imgui.WindowFlags.AlwaysAutoResize)
		if autovest.timer - (localClock() - _last_vest) > 0 then
			imgui.Text(string.format("You offered a vest to:\n%s[%d]\nNext vest in: %d\nVestmode: %s", sampname, playerid, autovest.timer - (localClock() - _last_vest), vestmodename(autovest.vestmode)))
		else
			imgui.Text(string.format("You offered a vest to:\n%s[%d]\nNext vest in: 0\nVestmode: %s", sampname, playerid, vestmodename(autovest.vestmode)))
		end
	imgui.End()
end).HideCursor = true

imgui.OnFrame(function() return autovest.notification[2] and _enabled and not isGamePaused() end,
function()
	imgui.SetNextWindowPos(imgui.ImVec2(autovest.offeredpos[1], autovest.offeredpos[2]), imgui.Cond.Always)
	imgui.Begin("offered", nil, imgui.WindowFlags.NoTitleBar + imgui.WindowFlags.NoResize + imgui.WindowFlags.NoCollapse + imgui.WindowFlags.NoMove + imgui.WindowFlags.NoScrollbar)
		imgui.Text(string.format("You got an offer from: \n%s[%d]", sampname2, playerid2))
	imgui.End()
end).HideCursor = true

imgui.OnFrame(function() return menu[0] and not isGamePaused() end,
function()
	local width, height = getScreenResolution()
	imgui.SetNextWindowPos(imgui.ImVec2(width / 2, height / 2), imgui.Cond.Always, imgui.ImVec2(0.5, 0.5))
	--imgui.SetNextWindowSize(imgui.ImVec2(480, 320), imgui.Cond.Always)
	imgui.Begin(fa.ICON_FA_SHIELD_ALT .. "Autovest Settings", menu, imgui.WindowFlags.NoResize + imgui.WindowFlags.NoCollapse + imgui.WindowFlags.NoMove + imgui.WindowFlags.NoScrollbar + imgui.WindowFlags.AlwaysAutoResize)

		imgui.BeginChild("##1", imgui.ImVec2(85, 392), true)
				
			imgui.SetCursorPos(imgui.ImVec2(5, 5))
      
			if imgui.CustomButton(
				faicons.ICON_POWER_OFF, 
				_enabled and imgui.ImVec4(0.15, 0.59, 0.18, 0.7) or imgui.ImVec4(1, 0.19, 0.19, 0.5), 
				_enabled and imgui.ImVec4(0.15, 0.59, 0.18, 0.5) or imgui.ImVec4(1, 0.19, 0.19, 0.3), 
				_enabled and imgui.ImVec4(0.15, 0.59, 0.18, 0.4) or imgui.ImVec4(1, 0.19, 0.19, 0.2), 
				imgui.ImVec2(75, 75)) then
				_enabled = not _enabled
			end
			if imgui.IsItemHovered() then
				imgui.SetTooltip('Toggles Notifications')
			end
		
			imgui.SetCursorPos(imgui.ImVec2(5, 81))

			if imgui.CustomButton(
				faicons.ICON_FLOPPY_O,
				imgui.ImVec4(0.16, 0.16, 0.16, 0.9), 
				imgui.ImVec4(0.40, 0.12, 0.12, 1), 
				imgui.ImVec4(0.30, 0.08, 0.08, 1), 
				imgui.ImVec2(75, 75)) then
				saveIni()
			end
			if imgui.IsItemHovered() then
				imgui.SetTooltip('Save the Script')
			end
      
			imgui.SetCursorPos(imgui.ImVec2(5, 157))

			if imgui.CustomButton(
				faicons.ICON_REPEAT, 
				imgui.ImVec4(0.16, 0.16, 0.16, 0.9), 
				imgui.ImVec4(0.40, 0.12, 0.12, 1), 
				imgui.ImVec4(0.30, 0.08, 0.08, 1), 
				imgui.ImVec2(75, 75)) then
				loadIni()
			end
			if imgui.IsItemHovered() then
				imgui.SetTooltip('Reload the Script')
			end

			imgui.SetCursorPos(imgui.ImVec2(5, 233))

			if imgui.CustomButton(
				faicons.ICON_ERASER, 
				imgui.ImVec4(0.16, 0.16, 0.16, 0.9), 
				imgui.ImVec4(0.40, 0.12, 0.12, 1), 
				imgui.ImVec4(0.30, 0.08, 0.08, 1), 
				imgui.ImVec2(75, 75)) then
				blankIni()
			end
			if imgui.IsItemHovered() then
				imgui.SetTooltip('Reset the Script to default settings')
			end

			imgui.SetCursorPos(imgui.ImVec2(5, 309))

			if imgui.CustomButton(
				faicons.ICON_RETWEET .. ' Update',
				imgui.ImVec4(0.16, 0.16, 0.16, 0.9), 
				imgui.ImVec4(0.40, 0.12, 0.12, 1), 
				imgui.ImVec4(0.30, 0.08, 0.08, 1),  
				imgui.ImVec2(75, 75)) then
				--update_script()
			end
			if imgui.IsItemHovered() then
				imgui.SetTooltip('Update the script')
			end
      
		imgui.EndChild()
		
		imgui.SetCursorPos(imgui.ImVec2(92, 28))

		imgui.BeginChild("##2", imgui.ImVec2(337, 88), true)
      
			imgui.SetCursorPos(imgui.ImVec2(5,5))
			if imgui.CustomButton(fa.ICON_FA_COG .. '  Settings',
				_menu == 1 and imgui.ImVec4(0.56, 0.16, 0.16, 1) or imgui.ImVec4(0.16, 0.16, 0.16, 0.9),
				imgui.ImVec4(0.40, 0.12, 0.12, 1), 
				imgui.ImVec4(0.30, 0.08, 0.08, 1), 
				imgui.ImVec2(165, 75)) then
				_menu = 1
			end

			imgui.SetCursorPos(imgui.ImVec2(170, 5))
			  
			if imgui.CustomButton(fa.ICON_FA_INFO_CIRCLE .. '  About me',
				_menu == 2 and imgui.ImVec4(0.56, 0.16, 0.16, 1) or imgui.ImVec4(0.16, 0.16, 0.16, 0.9),
				imgui.ImVec4(0.40, 0.12, 0.12, 1), 
				imgui.ImVec4(0.30, 0.08, 0.08, 1), 
				imgui.ImVec2(165, 75)) then
			  
				_menu = 2
			end
		imgui.EndChild()

		imgui.SetCursorPos(imgui.ImVec2(92, 112))
		
		imgui.BeginChild("##3", imgui.ImVec2(337, 276), true)
			if _menu == 1 then
				imgui.SetCursorPosX(imgui.GetWindowWidth() / 4.1)
				imgui.Text(fa.ICON_FA_WRENCH .. " Current configuration")
				imgui.Spacing()
				imgui.Columns(1)
				imgui.Separator()
				imgui.Spacing()

				if imgui.Checkbox("Diamond Donator", new.bool(autovest.ddmode)) then
					autovest.ddmode = not autovest.ddmode
					if autovest.ddmode then
						autovest.timer = 7
					else
						autovest.timer = 12
					end
				end
				
				if imgui.IsItemHovered() then
					imgui.SetTooltip('If you are Diamond Donator toggle this on.')
				end

				imgui.SameLine()
				imgui.SetCursorPosX(imgui.GetWindowWidth() / 1.8)

				if imgui.Checkbox("Notification Offer",  new.bool(autovest.notification[1])) then
					autovest.notification[1] = not autovest.notification[1]
				end
				if imgui.IsItemHovered() then
					imgui.SetTooltip('Toggles Notification Offer')
				end
				
				if imgui.Checkbox("Notification Offered",  new.bool(autovest.notification[2])) then
					autovest.notification[2] = not autovest.notification[2]
				end
				if imgui.IsItemHovered() then
					imgui.SetTooltip('Toggles Notification Offered')
				end

				imgui.SameLine()
				imgui.SetCursorPosX(imgui.GetWindowWidth() / 1.8)
				if imgui.Checkbox("Compare Both", new.bool(autovest.factionboth)) then
					autovest.factionboth = not autovest.factionboth
				end
				if imgui.IsItemHovered() then
					imgui.SetTooltip('Compare faction (color and skin) or (color or skin)')
				end

				if imgui.Checkbox("Sound", new.bool(autovest.sound)) then
					autovest.sound = not autovest.sound
				end
				imgui.SameLine()
				imgui.SetCursorPosX(imgui.GetWindowWidth() / 1.8)
				if imgui.Checkbox("Timer fix", new.bool(autovest.timercorrection)) then
					autovest.timercorrection = not autovest.timercorrection
				end
				if imgui.Checkbox("Enabled by default", new.bool(autovest.enablebydefault)) then
					autovest.enablebydefault = not autovest.enablebydefault
				end
				imgui.SetCursorPosY(imgui.GetWindowHeight() / 2.1)
				imgui.Columns(1)
				imgui.Separator()
				imgui.Spacing()
				imgui.Text("Autovest Command: ")
				imgui.SameLine()
				imgui.PushItemWidth(125)
				local text = new.char[256](autovest.autovestcmd)
				if imgui.InputText('##Autovest command', text, sizeof(text), imgui.InputTextFlags.EnterReturnsTrue) then
					autovest.autovestcmd = u8:decode(str(text))
				end
				imgui.Text("Settings Command:  ")
				imgui.SameLine()
				imgui.PushItemWidth(125)
				
				local text2 = new.char[256](autovest.autovestsettingscmd)
				if imgui.InputText('##Autovestsettings command', text2, sizeof(text2), imgui.InputTextFlags.EnterReturnsTrue) then
					autovest.autovestsettingscmd = u8:decode(str(text2))
				end
				imgui.Text("Autoaccepter Command: ")
				imgui.SameLine()
				imgui.PushItemWidth(125)
				
				local text3 = new.char[256](autovest.autoacceptercmd)
				if imgui.InputText('##Autoaccepter command', text3, sizeof(text3), imgui.InputTextFlags.EnterReturnsTrue) then
					autovest.autoacceptercmd = u8:decode(str(text3))
				end
				imgui.Spacing()
				imgui.Text("Changing this will require the script to restart")
				imgui.Spacing()
				imgui.SetCursorPosX(imgui.GetWindowWidth() / 5.7)

				if imgui.Button(fa.ICON_FA_SYNC_ALT .. " Save and restart the script", imgui.ImVec2(imgui.GetWindowWidth() / 1.5, imgui.GetWindowHeight() / 11)) then
					saveIni()
					thisScript():reload()
				end
			end
			
			if _menu == 2 then
				--imgui.SetCursorPosX(imgui.GetWindowWidth() / 3)
				--imgui.SetCursorPosY(imgui.GetWindowHeight() / 10)
				--imgui.Image(nzlogo, imgui.ImVec2(96, 96))
				imgui.SetCursorPosY(imgui.GetWindowHeight() / 1.7)
				imgui.SetCursorPosX(imgui.GetWindowWidth() / 4.5)
				imgui.Text(fa.ICON_FA_COPYRIGHT .. " Made by SpnKO(Oleg)/akacross")
			end
		imgui.EndChild()
		imgui.SetCursorPos(imgui.ImVec2(92, 384))
		
		imgui.BeginChild("##5", imgui.ImVec2(337, 36), true)
			
			
			if imgui.Button(vestmodename(autovest.vestmode)) then
				if autovest.vestmode == 2 then
					autovest.vestmode = 0
				else
					autovest.vestmode = autovest.vestmode + 1
				end
			end
			imgui.SameLine()
			if imgui.Button(move[1] and u8"Undo##1" or u8"Move##1") then
				move[1] = not move[1]
				if move[1] then
					sampAddChatMessage(string.format('%s: Press {FF0000}%s {FFFFFF}to save the pos.', script.this.name, vk.id_to_name(VK_LBUTTON)), -1) 
					temp_pos.x = autovest.offerpos[1]
					temp_pos.y = autovest.offerpos[2]
					move[1] = true
				else
					autovest.offerpos[1] = temp_pos.x
					autovest.offerpos[2] = temp_pos.y
					move[1] = false
				end
			end
			imgui.SameLine()
			if imgui.Button(move[2] and u8"Undo##2" or u8"Move##2") then
				move[2] = not move[2]
				if move[2] then
					sampAddChatMessage(string.format('%s: Press {FF0000}%s {FFFFFF}to save the pos.', script.this.name, vk.id_to_name(VK_LBUTTON)), -1) 
					temp_pos.x = autovest.offeredpos[1]
					temp_pos.y = autovest.offeredpos[2]
					move[2] = true
				else
					autovest.offeredpos[1] = temp_pos.x
					autovest.offeredpos[2] = temp_pos.y
					move[2] = false
				end
			end
			imgui.SameLine()
			if imgui.Button('Update Skins') and not updateskin then
				lua_thread.create(function()
					updateskin = true
					loadskinids()
					wait(5000)
					updateskin = false
				end)
			end
		imgui.EndChild()
	imgui.End()
end)

-- IMGUI_API bool          CustomButton(const char* label, const ImVec4& col, const ImVec4& col_focus, const ImVec4& col_click, const ImVec2& size = ImVec2(0,0));
function imgui.CustomButton(name, color, colorHovered, colorActive, size)
    local clr = imgui.Col
    imgui.PushStyleColor(clr.Button, color)
    imgui.PushStyleColor(clr.ButtonHovered, colorHovered)
    imgui.PushStyleColor(clr.ButtonActive, colorActive)
    if not size then size = imgui.ImVec2(0, 0) end
    local result = imgui.Button(name, size)
    imgui.PopStyleColor(3)
    return result
end

function main()
	blank = table.deepcopy(autovest)
	if not doesDirectoryExist(path) then createDirectory(path) end
	if doesFileExist(cfg) then loadIni() else blankIni() end
	while not isSampAvailable() do wait(100) end
	
	setSampfuncsGlobalVar('aduty', 0)
	setSampfuncsGlobalVar('HideMe_check', 0)
	
	mp3 = loadAudioStream("moonloader\\resource\\autovest\\sound.mp3")
	
	if autovest.ddmode then
		autovest.timer = 7
	else
		autovest.timer = 12
	end
	
	sampRegisterChatCommand(autovest.autovestcmd, function() 
		_enabled = not _enabled
		sampAddChatMessage(string.format("[Horizon Autovest]{ffff00} Automatic vest %s.", _enabled and 'enabled' or 'disabled'), 1999280)
	end)
	
	sampRegisterChatCommand(autovest.autoacceptercmd, function() 
		autoaccepter = not autoaccepter
		sampAddChatMessage(string.format("[Horizon Autovest]{ffff00} Autoaccepter is now %s.", autoaccepter and 'enabled' or 'disabled'), 1999280)
	end)
	
	sampRegisterChatCommand(autovest.ddmodecmd, function() 
		autovest.ddmode = not autovest.ddmode
		sampAddChatMessage(string.format("[Horizon Autovest]{ffff00} ddmode is now %s.", autovest.ddmode and 'enabled' or 'disabled'), 1999280)
		
		if autovest.ddmode then
			autovest.timer = 7
		else
			autovest.timer = 12
		end
	end)
	
	sampRegisterChatCommand(autovest.factionbothcmd, function() 
		autovest.factionboth  = not autovest.factionboth
		sampAddChatMessage(string.format("[Horizon Autovest]{ffff00} factionbothcmd is now %s.", autovest.factionboth and 'enabled' or 'disabled'), 1999280)
	end)
	
	sampRegisterChatCommand(autovest.autovestsettingscmd, function() 
		_menu = 1
		menu[0] = not menu[0]
	end)
	
	sampRegisterChatCommand(autovest.vestmodecmd, function(params) 
		if string.len(params) > 0 then 
			if params == 'gang' then
				autovest.vestmode = 0
				sampAddChatMessage("[Horizon Autovest]{ffff00} vestmode is now set to Gang.", 1999280)
			elseif params == 'faction' then
				autovest.vestmode = 1
				sampAddChatMessage("[Horizon Autovest]{ffff00} vestmode is now set to Faction.", 1999280)
			elseif params == 'everyone' then
				autovest.vestmode = 2
				sampAddChatMessage("[Horizon Autovest]{ffff00} vestmode is now set to Everyone.", 1999280)
			else
				sampAddChatMessage("[Horizon Autovest]{ffff00} vestmode is currently set to "..vestmodename(autovest.vestmode)..".", 1999280)
				sampAddChatMessage('USAGE: /'..autovest.vestmodecmd..' [gang/faction/everyone]', -1)
			end
		else
			sampAddChatMessage("[Horizon Autovest]{ffff00} vestmode is currently set to "..vestmodename(autovest.vestmode)..".", 1999280)
			sampAddChatMessage('USAGE: /'..autovest.vestmodecmd..' [gang/faction/everyone]', -1)
		end
	end)
	
	if not autovest.enablebydefault then
		_enabled = false
	end
	
	loadskinids()
	
	while true do wait(0)
		if move[1] then	
			x, y = getCursorPos()
			if isKeyJustPressed(VK_LBUTTON) then 
				move[1] = false
			elseif isKeyJustPressed(VK_ESCAPE) then
				move[1] = false
			else 
				autovest.offerpos[1] = x + 1
				autovest.offerpos[2] = y + 1
			end
		end
		
		if move[2] then	
			x, y = getCursorPos()
			if isKeyJustPressed(VK_LBUTTON) then 
				move[2] = false
			elseif isKeyJustPressed(VK_ESCAPE) then
				move[2] = false
			else 
				autovest.offeredpos[1] = x + 1
				autovest.offeredpos[2] = y + 1
			end
		end
	
		local _, aduty = getSampfuncsGlobalVar("aduty")
		local _, HideMe = getSampfuncsGlobalVar("HideMe_check")
		if _enabled and autovest.timer <= localClock() - _last_vest and not specstate and HideMe == 0 and not aduty then
			if autovest.ddmode then
				local _, ped = storeClosestEntities(PLAYER_PED)
				local result, PlayerID = sampGetPlayerIdByCharHandle(ped)
				if result and not sampIsPlayerPaused(PlayerID) then
					local myX, myY, myZ = getCharCoordinates(playerPed)
					local playerX, playerY, playerZ = getCharCoordinates(ped)
					if getDistanceBetweenCoords3d(myX, myY, myZ, playerX, playerY, playerZ) < 6 then
						if sampGetPlayerArmor(PlayerID) < 49 then
							local pAnimId = sampGetPlayerAnimationId(select(2, sampGetPlayerIdByCharHandle(PLAYER_PED)))
							local pAnimId2 = sampGetPlayerAnimationId(playerid)
							local aim, _ = getCharPlayerIsTargeting(playerHandle)
							if pAnimId ~= 1158 and pAnimId ~= 1159 and pAnimId ~= 1160 and pAnimId ~= 1161 and pAnimId ~= 1162 and pAnimId ~= 1163 and pAnimId ~= 1164 and pAnimId ~= 1165 and pAnimId ~= 1166 and pAnimId ~= 1167 and pAnimId ~= 1069 and pAnimId ~= 1070 and pAnimId2 ~= 746 and not aim then
								if autovest.vestmode == 0 then
									if has_number(skins, getCharModel(ped)) then
										sendGuard(PlayerID)
									end
								end
								if autovest.vestmode == 1 then
									local color = sampGetPlayerColor(PlayerID)
									local r, g, b = hex2rgb(color)
									color = join_argb_int(255, r, g, b)
									if (autovest.factionboth and has_number(factions, getCharModel(ped)) and has_number(factions_color, color)) or (not autovest.factionboth and has_number(factions, getCharModel(ped)) or has_number(factions_color, color)) then
										sendGuard(PlayerID)
									end
								end
								if autovest.vestmode == 2 then
									sendGuard(PlayerID)
								end
							end
						end
					end
				end
			else
				local _, ped = storeClosestEntities(PLAYER_PED)
				local result, PlayerID = sampGetPlayerIdByCharHandle(ped)
				if result and not sampIsPlayerPaused(PlayerID) then
					local myX, myY, myZ = getCharCoordinates(playerPed)
					local playerX, playerY, playerZ = getCharCoordinates(ped)
					if getDistanceBetweenCoords3d(myX, myY, myZ, playerX, playerY, playerZ) < 6 then
						if sampGetPlayerArmor(PlayerID) < 49 then
							local pAnimId = sampGetPlayerAnimationId(select(2, sampGetPlayerIdByCharHandle(PLAYER_PED)))
							local pAnimId2 = sampGetPlayerAnimationId(playerid)
							local aim, _ = getCharPlayerIsTargeting(playerHandle)
							if pAnimId ~= 1158 and pAnimId ~= 1159 and pAnimId ~= 1160 and pAnimId ~= 1161 and pAnimId ~= 1162 and pAnimId ~= 1163 and pAnimId ~= 1164 and pAnimId ~= 1165 and pAnimId ~= 1166 and pAnimId ~= 1167 and pAnimId ~= 1069 and pAnimId ~= 1070 and pAnimId2 ~= 746 and not aim then
								if autovest.vestmode == 0 then
									if has_number(skins, getCharModel(ped)) then
										sendGuard(PlayerID)
									end
								end
								if autovest.vestmode == 1 then
									local color = sampGetPlayerColor(PlayerID)
									local r, g, b = hex2rgb(color)
									color = join_argb_int(255, r, g, b)
									if (autovest.factionboth and has_number(factions, getCharModel(ped)) and has_number(factions_color, color)) or (not autovest.factionboth and has_number(factions, getCharModel(ped)) or has_number(factions_color, color)) then
										sendGuard(PlayerID)
									end
								end
								if autovest.vestmode == 2 then
									sendGuard(PlayerID)
								end
							end
						end
					end
				end
			end
			if autoaccepter and autoacceptertoggle then
				local _, ped = storeClosestEntities(PLAYER_PED)
				local result, PlayerID = sampGetPlayerIdByCharHandle(ped)
				if result and ped ~= PLAYER_PED then
					if getCharArmour(PLAYER_PED) < 49 and sampGetPlayerAnimationId(PLAYER_PED) ~= 746 then
						autoaccepternickname = sampGetPlayerNickname(PlayerID)

						local playerx, playery, playerz = getCharCoordinates(PLAYER_PED)
						local pedx, pedy, pedz = getCharCoordinates(ped)

						if getDistanceBetweenCoords3d(playerx, playery, playerz, pedx, pedy, pedz) < 4 then
							if autoaccepternickname == autoaccepternick then
								sampSendChat("/accept bodyguard")
									
								autoacceptertoggle = false
							end
						end
					end
				end
			end
		end
	end	
end

function sendGuard(id)
	if autovest.ddmode then
		sampSendChat('/guardnear')
	else
		sampSendChat(string.format("/guard %d 200", id))
	end
	sampname = sampGetPlayerNickname(id)
	playerid = id
	playSound()
	_last_vest = localClock()
end

function playSound()
	if autovest.sound then
		if mp3 ~= nil then
			setAudioStreamVolume(mp3, 10)
			setAudioStreamState(mp3, 1)
		end
	end
end

function loadskinids()
	urlstring = https.request(autovest.skinsurl)
	for skinid in string.match(urlstring, "<body>(.+)</body>").gmatch(urlstring, "%d*") do
		if string.len(skinid) > 0 then 
			table.insert(skins, skinid)
		end
	end
end

function onScriptTerminate(scr, quitGame) 
	if scr == script.this then 
		if autovest.autosave then 
			saveIni() 
		end 
	end
end

function onWindowMessage(msg, wparam, lparam)
	if wparam == VK_ESCAPE and menu[0] then
        if msg == wm.WM_KEYDOWN then
            consumeWindowMessage(true, false)
        end
        if msg == wm.WM_KEYUP then
            menu[0] = false
        end
    end
end

function sampev.onServerMessage(color, text)
	if text:find("has taken control of the") and color == -65366 and autoaccepter then
		autoaccepter = false

		sampAddChatMessage("[Horizon Autovest]{ffff00} Automatic vest disabled because point had ended.", 1999280)
	end

	if text:find("That player isn't near you.") and color == -1347440726 then
		if autovest.ddmode then
			_last_vest = localClock() - 6.8
		else
			_last_vest = localClock() - 11.8
		end
	end

	if text:find("You can't /guard while aiming.") and color == -1347440726 then
		if autovest.ddmode then
			_last_vest = localClock() - 6.8
		else
			_last_vest = localClock() - 11.8
		end
	end
	
	if text:find("You must wait") and text:find("seconds before selling another vest.") and autovest.timercorrection then
		cooldown = string.match (text, "%d+")
		autovest.timer = cooldown + 0.5
	end
	
	if text:find("accepted your protection, and the $200 was added to your money.") and color == 869072810 then
		sampname = 'Nobody'
		playerid = -1
	end
	
	if text:find("You accepted the protection for $200 from") and color == 869072810 then
		sampname2 = 'Nobody'
		playerid2 = -1
	end
	
	if text:find("* Bodyguard ") and text:find(" wants to protect you for $200, type /accept bodyguard to accept.") and color == 869072810 then
		lua_thread.create(function()
			wait(0)
			if getCharArmour(PLAYER_PED) < 49 and sampGetPlayerAnimationId(PLAYER_PED) ~= 746 and autoaccepter and not specstate then
				sampSendChat("/accept bodyguard")

				autoacceptertoggle = false
			end

			if color >= 40 and text ~= 746 then
				autoaccepternick = text:match("%* Bodyguard (.+) wants to protect you for %$200, type %/accept bodyguard to accept%.")
				autoaccepternick = autoaccepternick:gsub("%s+", "_")
				
				sampname2 = autoaccepternick
				playerid2 = sampGetPlayerIdByNickname(autoaccepternick)
				autoacceptertoggle = true
			end
		end)
	end
end

function sampev.onTogglePlayerSpectating(state)
    specstate = state
end

function blankIni()
	autovest = table.deepcopy(blank)
	saveIni()
	loadIni()
end

function loadIni()
	local f = io.open(cfg, "r")
	if f then
		autovest = decodeJson(f:read("*all"))
		f:close()
	end
end

function saveIni()
	if type(autovest) == "table" then
		local f = io.open(cfg, "w")
		f:close()
		if f then
			f = io.open(cfg, "r+")
			f:write(encodeJson(autovest))
			f:close()
		end
	end
end

function has_number(tab, val)
    for index, value in ipairs(tab) do
        if tonumber(value) == val then
            return true
        end
    end

    return false
end

function has_value(tab, val)
    for index, value in ipairs(tab) do
        if value == val then
            return true
        end
    end

    return false
end

function sampGetPlayerIdByNickname(nick)
	nick = tostring(nick)
	local _, myid = sampGetPlayerIdByCharHandle(PLAYER_PED)
	if nick == sampGetPlayerNickname(myid) then return myid end
	for i = 0, 1003 do
		if sampIsPlayerConnected(i) and sampGetPlayerNickname(i) == nick then
			return i
		end
	end
end

function vestmodename(vestmode)
	if vestmode == 0 then
		return 'Gang'
	elseif vestmode == 1 then
		return 'Faction'
	elseif vestmode == 2 then
		return 'Everyone'
	end
end

function hex2rgb(rgba)
	local a = bit.band(bit.rshift(rgba, 24),	0xFF)
	local r = bit.band(bit.rshift(rgba, 16),	0xFF)
	local g = bit.band(bit.rshift(rgba, 8),		0xFF)
	local b = bit.band(rgba, 0xFF)
	return r / 255, g / 255, b / 255
end

function join_argb_int(a, r, g, b)
	local argb = b * 255
    argb = bit.bor(argb, bit.lshift(g * 255, 8))
    argb = bit.bor(argb, bit.lshift(r * 255, 16))
    argb = bit.bor(argb, bit.lshift(a, 24))
    return argb
end

function apply_custom_style()
	imgui.SwitchContext()
	local ImVec4 = imgui.ImVec4
	local ImVec2 = imgui.ImVec2
	local style = imgui.GetStyle()
	style.WindowRounding = 0
	style.WindowPadding = ImVec2(8, 8)
	style.WindowTitleAlign = ImVec2(0.5, 0.5)
	--style.ChildWindowRounding = 0
	style.FrameRounding = 0
	style.ItemSpacing = ImVec2(8, 4)
	style.ScrollbarSize = 10
	style.ScrollbarRounding = 3
	style.GrabMinSize = 10
	style.GrabRounding = 0
	style.Alpha = 1
	style.FramePadding = ImVec2(4, 3)
	style.ItemInnerSpacing = ImVec2(4, 4)
	style.TouchExtraPadding = ImVec2(0, 0)
	style.IndentSpacing = 21
	style.ColumnsMinSpacing = 6
	style.ButtonTextAlign = ImVec2(0.5, 0.5)
	style.DisplayWindowPadding = ImVec2(22, 22)
	style.DisplaySafeAreaPadding = ImVec2(4, 4)
	style.AntiAliasedLines = true
	--style.AntiAliasedShapes = true
	style.CurveTessellationTol = 1.25
	local colors = style.Colors
	local clr = imgui.Col
	colors[clr.FrameBg]                = ImVec4(0.48, 0.16, 0.16, 0.54)
	colors[clr.FrameBgHovered]         = ImVec4(0.98, 0.26, 0.26, 0.40)
	colors[clr.FrameBgActive]          = ImVec4(0.98, 0.26, 0.26, 0.67)
	colors[clr.TitleBg]                = ImVec4(0.04, 0.04, 0.04, 1.00)
	colors[clr.TitleBgActive]          = ImVec4(0.48, 0.16, 0.16, 1.00)
	colors[clr.TitleBgCollapsed]       = ImVec4(0.00, 0.00, 0.00, 0.51)
	colors[clr.CheckMark]              = ImVec4(0.98, 0.26, 0.26, 1.00)
	colors[clr.SliderGrab]             = ImVec4(0.88, 0.26, 0.24, 1.00)
	colors[clr.SliderGrabActive]       = ImVec4(0.98, 0.26, 0.26, 1.00)
	colors[clr.Button]                 = ImVec4(0.98, 0.26, 0.26, 0.40)
	colors[clr.ButtonHovered]          = ImVec4(0.98, 0.26, 0.26, 1.00)
	colors[clr.ButtonActive]           = ImVec4(0.98, 0.06, 0.06, 1.00)
	colors[clr.Header]                 = ImVec4(0.98, 0.26, 0.26, 0.31)
	colors[clr.HeaderHovered]          = ImVec4(0.98, 0.26, 0.26, 0.80)
	colors[clr.HeaderActive]           = ImVec4(0.98, 0.26, 0.26, 1.00)
	colors[clr.Separator]              = colors[clr.Border]
	colors[clr.SeparatorHovered]       = ImVec4(0.75, 0.10, 0.10, 0.78)
	colors[clr.SeparatorActive]        = ImVec4(0.75, 0.10, 0.10, 1.00)
	colors[clr.ResizeGrip]             = ImVec4(0.98, 0.26, 0.26, 0.25)
	colors[clr.ResizeGripHovered]      = ImVec4(0.98, 0.26, 0.26, 0.67)
	colors[clr.ResizeGripActive]       = ImVec4(0.98, 0.26, 0.26, 0.95)
	colors[clr.TextSelectedBg]         = ImVec4(0.98, 0.26, 0.26, 0.35)
	colors[clr.Text]                   = ImVec4(1.00, 1.00, 1.00, 1.00)
	colors[clr.TextDisabled]           = ImVec4(0.50, 0.50, 0.50, 1.00)
	colors[clr.WindowBg]               = ImVec4(0.06, 0.06, 0.06, 0.94)
	--colors[clr.ChildWindowBg]          = ImVec4(1.00, 1.00, 1.00, 0.00)
	colors[clr.PopupBg]                = ImVec4(0.08, 0.08, 0.08, 0.94)
	--colors[clr.ComboBg]                = colors[clr.PopupBg]
	colors[clr.Border]                 = ImVec4(0.43, 0.43, 0.50, 0.50)
	colors[clr.BorderShadow]           = ImVec4(0.00, 0.00, 0.00, 0.00)
	colors[clr.MenuBarBg]              = ImVec4(0.14, 0.14, 0.14, 1.00)
	colors[clr.ScrollbarBg]            = ImVec4(0.02, 0.02, 0.02, 0.53)
	colors[clr.ScrollbarGrab]          = ImVec4(0.31, 0.31, 0.31, 1.00)
	colors[clr.ScrollbarGrabHovered]   = ImVec4(0.41, 0.41, 0.41, 1.00)
	colors[clr.ScrollbarGrabActive]    = ImVec4(0.51, 0.51, 0.51, 1.00)
	--colors[clr.CloseButton]            = ImVec4(0.41, 0.41, 0.41, 0.50)
	--colors[clr.CloseButtonHovered]     = ImVec4(0.98, 0.39, 0.36, 1.00)
	--colors[clr.CloseButtonActive]      = ImVec4(0.98, 0.39, 0.36, 1.00)
	colors[clr.PlotLines]              = ImVec4(0.61, 0.61, 0.61, 1.00)
	colors[clr.PlotLinesHovered]       = ImVec4(1.00, 0.43, 0.35, 1.00)
	colors[clr.PlotHistogram]          = ImVec4(0.90, 0.70, 0.00, 1.00)
	colors[clr.PlotHistogramHovered]   = ImVec4(1.00, 0.60, 0.00, 1.00)
	--colors[clr.ModalWindowDarkening]   = ImVec4(0.80, 0.80, 0.80, 0.35)
end