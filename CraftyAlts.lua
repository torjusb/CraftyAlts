--[[
	TODO: Better scanProfessions function
	TODO: Better createButtons function
	TODO: Hide on the edge, show on mouseEnter (needs improvement)
]]

--[[
--	@ Setup
--]]

local myname, ns = ...

local professions = {
	['Cooking'] = 2550,
	['Tailoring'] = 3908,
	['Enchanting'] = 7411,
	['Blacksmithing'] = 3100,
	['Alchemy'] = 2259,
	['Leatherworking'] = 2108,
	['Engineering'] = 4036,
	['Jewelcrafting'] = 25229,
	['Inscription'] = 45357
}

local GameTooltip = GameTooltip

local CAframe = CreateFrame("frame", "CraftyAltsFrame")
local backdrop = {
	bgFile = "Interface/Tooltips/UI-Tooltip-Background",
	insets = {top = 1, bottom = 1, left = 1, right = 1},
	edgeFile = "Interface/Tooltips/UI-Tooltip-Border",
	edgeSize = 7, tile = true, tileSize = 16
}

--[[
--	@ Event handlers
--]]

local hiddenElapsed = 0
local OnUpdate = function (self, elapsed) 
	hiddenElapsed = hiddenElapsed + elapsed
	if hiddenElapsed < .5 then return end
	
	self:SetScript("OnUpdate", nil)
	self:slideIn()
end

local CAframe_OnEnter = function (self, motion)
	CAframe:SetScript("OnUpdate", nil)
	CAframe:SetAlpha(1)
	CAframe:SetPoint("LEFT", -3, 100)
end

local CAframe_OnLeave = function (self)
	hiddenElapsed = 0
	CAframe:SetScript("OnUpdate", OnUpdate)
end

local button_OnClick = function (self, button, down) 
	if IsShiftKeyDown() then
		if not ChatEdit_InsertLink(self.link) then
			ChatFrameEditBox:Show()
			ChatEdit_InsertLink(self.link)
		end
	else
		CAframe:slideIn()
		SetItemRef(self.link:match("|H([^|]+)"))
	end
end

local button_OnEnter = function (self, motion)
	CAframe_OnEnter()

	GameTooltip:SetOwner(self)
	GameTooltip:AddDoubleLine(self.char, self.skill)
	GameTooltip:Show()
end

local button_OnLeave = function (self)
	CAframe_OnLeave()
	
	GameTooltip:Hide()
end


function CAframe:slideIn()
	CAframe:ClearAllPoints()
	CAframe:SetPoint("LEFT", UIParent, "LEFT", -self.newWidth + 3, 100)
	CAframe:SetAlpha(.3)	
end


function CAframe:createButtons()
	local characters = ns.db[ns.factionrealm]
	local i = 1
		
	for char, profs in pairs(characters) do
		ns.Debug(char, profs)
		if profs then
			-- create buttons
			for prof, info in pairs(profs) do
				ns.Debug(prof, info)
				local button = CreateFrame("button")
				
				button:SetHeight(16)
				button:SetWidth(16)
				
				button:SetHighlightTexture([=[Interface\Buttons\ButtonHilight-Square]=])
				button:SetPushedTexture([=[Interface\Buttons\UI-Quickslot-Depress]=])
								
				button.texture = button:CreateTexture()
				button.texture:SetWidth(16)
				button.texture:SetHeight(16)
				button.texture:SetPoint("CENTER", button)
				
				button:SetFrameStrata("HIGH")
				
				local _,_, icon = GetSpellInfo(professions[prof])
				button.texture:SetTexture(icon)
				
				-- Profession info
				button.link = info.link	
				button.skill = info.rank
				button.char = char
				
				if i == 1 then
					button:SetPoint("LEFT", self, "LEFT", 5, 0)
				else 
					button:SetPoint("LEFT", self["button" .. i - 1], "RIGHT", 5, 0)
				end

				button:SetScript("OnClick", button_OnClick)
				button:SetScript("OnEnter", button_OnEnter)
				button:SetScript("OnLEave", button_OnLeave)
				
				self["button" .. i] = button
				i = i + 1
			end
		end
	end
	
	
	-- Calculate new width of CAFrame
	self.newWidth = 16 * (i - 1) + 5 * (i - 1) + 5
	self:SetWidth(self.newWidth)
	self:SetPoint("LEFT", UIParent, "LEFT", -self.newWidth + 3, 100)
	self:SetAlpha(.3)
end

function ns:scanProfessions()
	ns.Debug(GetNumSkillLines())
	for i = 1, GetNumSkillLines() do
		local skillName, _,_, rank = GetSkillLineInfo(i)
		if professions[skillName] then
			ns.db[ns.factionrealm][ns.char][skillName] = ns.db[ns.factionrealm][ns.char][skillName] or {}
			local link = select(2, GetSpellLink(skillName))
			if link then
				ns.db[ns.factionrealm][ns.char][skillName].link = link
				ns.db[ns.factionrealm][ns.char][skillName].rank = rank
			end
		end
	end
	
	CAframe:createButtons()
end

ns:RegisterEvent("ADDON_LOADED")
function ns:ADDON_LOADED(event, addon)
	if addon ~= myname then return end
	self:InitDB()
	
	CAframe:SetHeight(23)
	CAframe:SetWidth(100)

	CAframe:SetBackdrop(backdrop)
	CAframe:SetBackdropColor(0, 0, 0, .7)
	CAframe:SetBackdropBorderColor(0, 0, 0, .5)

	CAframe:Show()
	
	CAframe:EnableMouse(true)
	CAframe:SetScript("OnEnter", CAframe_OnEnter)
	CAframe:SetScript("OnLeave", CAframe_OnLeave)
			
	
	LibStub("tekKonfig-AboutPanel").new(nil, myname) -- Make first arg nil if no parent config panel

	self:UnregisterEvent("ADDON_LOADED")
	self.ADDON_LOADED = nil

	if IsLoggedIn() then self:PLAYER_LOGIN() else self:RegisterEvent("PLAYER_LOGIN") end
end

ns:RegisterEvent("SKILL_LINES_CHANGED")
function ns:SKILL_LINES_CHANGED()
	ns.Debug("Scan from update")
	ns:scanProfessions()
	
	ns:RegisterEvent("SKILL_LINES_CHANGED")
	self.SKILL_LINES_CHANGED = nil
end

function ns:PLAYER_LOGOUT()
--	self:FlushDB()
	-- Do anything you need to do as the player logs out
end

