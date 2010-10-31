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
CAframe:SetFrameStrata("HIGH")
CAframe:SetFrameLevel(1)

local backdrop = {
	bgFile = "Interface/Tooltips/UI-Tooltip-Background",
	insets = {top = 1, bottom = 1, left = 1, right = 1},
	edgeFile = "Interface/Tooltips/UI-Tooltip-Border",
	edgeSize = 7, tile = true, tileSize = 16
}


local mover = CreateFrame("Frame")
local moving = false

mover:SetScript("OnUpdate", function ()
	if moving then
		CAframe:move()
	end
end)

CAframe:SetScript("OnMouseDown", function (self)
	if IsShiftKeyDown() then
		moving = true
	end
end)

CAframe:SetScript("OnMouseUp", function (self)
	moving = false
	
	CAframe:SavePosition()
end)

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
	self:SetScript("OnUpdate", nil)
	self:SetAlpha(1)
	self:ClearAllPoints()
	
	if (self.orientation == "VERTICAL") then
		if self.slideWay == "UP" then
			self:SetPoint("TOPLEFT", UIParent, "TOPLEFT", self.pos, 3)
		else
			self:SetPoint("BOTTOMLEFT", UIParent, "BOTTOMLEFT", self.pos, -3)
		end
	else
		if self.slideWay == "LEFT" then 
			self:SetPoint("BOTTOMLEFT", UIParent, "BOTTOMLEFT", -3, self.pos)
		else
			self:SetPoint("BOTTOMRIGHT", UIParent, "BOTTOMRIGHT",  3, self.pos)
		end
	end	
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
	CAframe_OnEnter(CAframe)

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
	self:SetAlpha(.3)
		
	if self.orientation == "VERTICAL" then
		self:SetHeight(self.buttonLength)
		self:SetWidth(23)
		
		if self.slideWay == "UP" then
			self:SetPoint("TOPLEFT", UIParent, "TOPLEFT", self.pos, self.buttonLength - 3)
		else
			self:SetPoint("BOTTOMLEFT", UIParent, "BOTTOMLEFT", self.pos, -self.buttonLength + 3)
		end
	else
		self:SetHeight(23)
		self:SetWidth(self.buttonLength)
		
		if self.slideWay == "LEFT" then 
			self:SetPoint("BOTTOMLEFT", UIParent, "BOTTOMLEFT", -self.buttonLength + 3, self.pos)
		else
			self:SetPoint("BOTTOMRIGHT", UIParent, "BOTTOMRIGHT", self.buttonLength - 3, self.pos)
		end
	end
end

function CAframe:SetOrientation(orientation)
	self.orientation = orientation
	
	if (orientation == 'VERTICAL') then
		self:SetWidth(23)
		self:SetHeight(self.buttonLength)
		
		for i = 1, self.numButtons - 1 do
			local button = self["button"..i]
			
			button:ClearAllPoints()
			
			if i == 1 then
				button:SetPoint("TOP", self, "TOP", 0, -5)
			else 
				button:SetPoint("TOP", self["button" .. i - 1], "BOTTOM", 0, -5)
			end
		end				
	else
		self:SetHeight(23)
		self:SetWidth(self.buttonLength)

		for i = 1, self.numButtons - 1 do
			local button = self["button"..i]
			
			button:ClearAllPoints()
			
			if i == 1 then
				button:SetPoint("LEFT", self, "LEFT", 5, 0)
			else 
				button:SetPoint("LEFT", self["button" .. i - 1], "RIGHT", 5, 0)
			end
		end
	end
end

function CAframe:SavePosition()
	ns.db.frame = {
		orientation = self.orientation,
		slideWay = self.slideWay,
		pos = self.pos		
	}
end

function CAframe:move()
	local curX, curY = GetCursorPosition()
	local uiScale = UIParent:GetEffectiveScale()
	local uiWidth, uiHeight = UIParent:GetWidth() * uiScale, UIParent:GetHeight() * uiScale
	
	if self.slideWay == "DOWN" or self.slideWay == "UP" then
		if curX < 100 and curY > 100 and self.slideWay == "DOWN"
		or curX < 100 and curY < uiHeight - 100 and self.slideWay == "UP" then
			self:SetOrientation('HORIZONTAL')
			self.slideWay = 'LEFT'
		elseif curX > uiWidth - 100 and curY > 100 and self.slideWay == "DOWN"
		or curX > uiWidth - 100 and curY < uiHeight - 100 and self.slideWay == "UP" then
			self:SetOrientation('HORIZONTAL')
			self.slideWay = 'RIGHT'
		end
	else
		if curY < 100 and curX > 100 and self.slideWay == "LEFT"
		or curY < 100 and curX < uiWidth - 100 and self.slideWay == "RIGHT" then
			self:SetOrientation('VERTICAL')
			self.slideWay = 'DOWN'
		elseif curY > uiHeight - 100 and curX > 100 and self.slideWay == "LEFT"
		or curY > uiHeight - 100 and curX < uiWidth - 100 and self.slideWay == "RIGHT" then
			self:SetOrientation('VERTICAL')
			self.slideWay = 'UP'
		end
	end
		
	self:ClearAllPoints()
	if self.slideWay == 'DOWN' then
 		self:SetPoint("BOTTOMLEFT", UIParent, "BOTTOMLEFT", curX, -3)
		self.pos = curX
	elseif self.slideWay == 'UP' then
		self:SetPoint("TOPLEFT", UIParent, "TOPLEFT", curX, 3)
		self.pos = curX
	elseif self.slideWay == 'LEFT' then
		self:SetPoint("BOTTOMLEFT", UIParent, "BOTTOMLEFT", -3, curY)
		self.pos = curY
	else
		self:SetPoint("BOTTOMRIGHT", UIParent, "BOTTOMRIGHT", 3, curY)
		self.pos = curY
	end
		
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
				
					button:SetFrameStrata("HIGH")
					button:SetFrameLevel(2)
				
					button.texture:SetTexture(select(3, GetSpellInfo(professions[prof])))
				
					-- Profession info
					button.link = info.link	
					button.skill = info.rank
					button.char = char
					button.profession = prof
								
					if i == 1 then
						button:SetPoint("TOP", self, "TOP", 0, -5)
					else 
						button:SetPoint("TOP", self["button" .. i - 1], "BOTTOM", 0, -5)
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
		self.buttonLength = 16 * (i - 1) + 5 * (i - 1) + 5
		self.numButtons = i
		self.slideWay = ns.db.frame.slideWay
		self.pos = ns.db.frame.pos
		self:SetOrientation(ns.db.frame.orientation)
		
		self:slideIn()
	end
end


function ns:scanProfessions()
	local profs = {GetProfessions()}
	for i = 1, #profs do
		if profs[i] then
			local skillName,_, rank = GetProfessionInfo(profs[i])
		
			if professions[skillName] then
				ns.db[ns.factionrealm][ns.char][skillName] = ns.db[ns.factionrealm][ns.char][skillName] or {}
				local link = select(2, GetSpellLink(skillName))
			
				ns.db[ns.factionrealm][ns.char][skillName].rank = rank
						
				if link then
					ns.db[ns.factionrealm][ns.char][skillName].link = link
				end
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
	CAframe:SetWidth(23)

	CAframe:SetBackdrop(backdrop)
	CAframe:SetBackdropColor(0, 0, 0, .7)
	CAframe:SetBackdropBorderColor(0, 0, 0, .5)

	CAframe:Show()
	
	CAframe:EnableMouse(true)
	CAframe:SetScript("OnEnter", CAframe_OnEnter)
	CAframe:SetScript("OnLeave", CAframe_OnLeave)
	
	ns:scanProfessions()
	
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

-- ns:RegisterEvent("TRADE_SKILL_UPDATE")
-- function ns:TRADE_SKILL_UPDATE()
-- 	self:scanProfessions()
-- 	
-- 	self:UnregisterEvent("TRADE_SKILL_UPDATE")
-- 	self.TRADE_SKILL_UPDATE = nil
-- end