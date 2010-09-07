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
CAframe:SetFrameStrata("MEDIUM")
CAframe:SetFrameLevel(1)

local backdrop = {
	bgFile = "Interface/Tooltips/UI-Tooltip-Background",
	insets = {top = 1, bottom = 1, left = 1, right = 1},
	edgeFile = "Interface/Tooltips/UI-Tooltip-Border",
	edgeSize = 7, tile = true, tileSize = 16
}

local Y_POS = 0

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
	CAframe:SetPoint("LEFT", -3, Y_POS)
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
		if self.link then		
			SetItemRef(self.link:match("|H([^|]+)"))
		else
			-- Links are usually nil on login for new characters, so we fetch it again
			self.link = select(2, GetSpellLink(self.profession))
			ns.db[ns.factionrealm][ns.char][self.profession].link = self.link			
			
			if (self.link) then
				SetItemRef(self.link:match("|H([^|]+)"))
			end
		end
	end
end

local button_OnEnter = function (self, motion)
	CAframe_OnEnter()

	GameTooltip:SetOwner(self)
	GameTooltip:AddDoubleLine(self.char, self.skill)
	GameTooltip:Show()
end

local button_OnLeave = function ()
	CAframe_OnLeave()
	
	GameTooltip:Hide()
end

--[[
--	@ Functions
--]]

function CAframe:slideIn()
	self:ClearAllPoints()
	self:SetPoint("LEFT", UIParent, "LEFT", -self.newWidth + 3, Y_POS)
	self:SetAlpha(.3)	
end


function CAframe:createButtons()
	local characters = ns.db[ns.factionrealm]
	local i = 1
	
	self:Show()
		
	for char, profs in pairs(characters) do
		if profs then
			-- create buttons
			for prof, info in pairs(profs) do
				if info.link or char == ns.char then
					local button = self["button" .. i] or CreateFrame("button")
				
					button:SetHeight(16)
					button:SetWidth(16)
				
					button:SetHighlightTexture([=[Interface\Buttons\ButtonHilight-Square]=])
					button:SetPushedTexture([=[Interface\Buttons\UI-Quickslot-Depress]=])
								
					button.texture = button.texture or button:CreateTexture()
					button.texture:SetWidth(16)
					button.texture:SetHeight(16)
					button.texture:SetPoint("CENTER", button)
				
					button:SetFrameStrata("MEDIUM")
					button:SetFrameLevel(2)
				
					button.texture:SetTexture(select(3, GetSpellInfo(professions[prof])))
				
				
					-- Profession info
					button.link = info.link	
					button.skill = info.rank
					button.char = char
					button.profession = prof
								
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
	end
	
	if i == 1 then
		self:Hide()
	else	
		-- Calculate new width of CAFrame
		self.newWidth = 16 * (i - 1) + 5 * (i - 1) + 5
		self:SetWidth(self.newWidth)
		self:SetPoint("LEFT", UIParent, "LEFT", -self.newWidth + 3, Y_POS)
		self:SetAlpha(.3)
	end
end


function ns:scanProfessions()
	for i = 1, GetNumSkillLines() do
		local skillName, _,_, rank = GetSkillLineInfo(i)
		
		if professions[skillName] then
			ns.db[ns.factionrealm][ns.char][skillName] = ns.db[ns.factionrealm][ns.char][skillName] or {}
			local link = select(2, GetSpellLink(skillName))
			
			ns.db[ns.factionrealm][ns.char][skillName].rank = rank
						
			if link then
				ns.db[ns.factionrealm][ns.char][skillName].link = link
			end
		end
	end
	
	CAframe:createButtons()
end

--[[
--	@ Events
--]]

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
	
	ns:scanProfessions()
	
	LibStub("tekKonfig-AboutPanel").new(nil, myname) -- Make first arg nil if no parent config panel

	self:UnregisterEvent("ADDON_LOADED")
	self.ADDON_LOADED = nil
end

ns:RegisterEvent("PLAYER_ALIVE")
function ns:PLAYER_ALIVE()
	self:scanProfessions()
		
	self:UnregisterEvent("PLAYER_ALIVE")
	self.PLAYER_ALIVE = nil
end

ns:RegisterEvent("SKILL_LINES_CHANGED")
function ns:SKILL_LINES_CHANGED()
	self:scanProfessions()
end

ns:RegisterEvent("TRADE_SKILL_UPDATE")
function ns:TRADE_SKILL_UPDATE()
	self:scanProfessions()
	
	self:UnregisterEvent("TRADE_SKILL_UPDATE")
	self.TRADE_SKILL_UPDATE = nil
end