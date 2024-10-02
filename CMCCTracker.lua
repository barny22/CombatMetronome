DariansUtilities = DariansUtilities or {}
local Util = DariansUtilities
CombatMetronome.CCTracker = CombatMetronome.CCTracker or {}
local CCTracker = CombatMetronome.CCTracker
CCTracker.cc = CCTracker.cc or {}

function CCTracker:HandleEffectsChanged(_,changeType,_,_,unitTag,_,endTime,_,_,_,buffType,abilityType,_,unitName,_,aId,_)
	-- d(unitName.." - "..GetUnitName("player"))
	time = GetFrameTimeMilliseconds()
	if not (unitTag == "player" or Util.Text.CropZOSString(unitName) == CombatMetronome.currentCharacterName) then
		return
	else
		if self.variables[abilityType] and self.variables[abilityType][2] and changeType == (EFFECT_RESULT_UPDATED or EFFECT_RESULT_GAINED) then
			local newAbility = {aId, abilityType, endTime}
			-- if not self:ResInList(abilityType) then
				if not self:AIdInList(aId) then
					self.ccChanged = true
					table.insert(self.cc, newAbility)
				else return
				end
			-- end
		elseif self.ccCache and self.ccCache[1] and self.ccCache[1][3] == time and not self.variables[abilityType] then
			local newAbility = {aId, self.ccCache[1][2], endTime}
			-- if not self:ResInList(self.ccCache[1][2]) then
				if not self:AIdInList(aId) then
					self.ccChanged = true
					table.insert(self.cc, newAbility)
				else return
				end
			-- end
		end
		if changeType == EFFECT_RESULT_FADED then
			for i, entry in ipairs(self.cc) do
				if entry[1] == aId then
					table.remove(self.cc, i)
					self.ccChanged = true
					break
				end
			end
		end
		for i, entry in ipairs(self.cc) do
			if entry[3] < time then
				table.remove(self.cc, i)
				self.ccChanged = true
			end
		end
	end
	if CCTracker.ccChanged then self:ApplyIcons() end
end

function CCTracker:ApplyIcons()
	local active = {}
	for num, _ in pairs(self.variables) do
		for _, entry in ipairs(self.cc) do
			if entry[2] == num and not active[num] then
			 table.insert(active, num)
			end
		end
	end
	-- for i= 1, #self.cc do
		-- if CCTracker.variables[entry[2]] then
			-- if not active[self.cc[i][2]] then table.insert(active, self.cc[i][2]) end
		-- end
	-- end
	if active then
		for i=1, #active do
			self.UI.indicator[i].controls.icon:SetTexture(self.variables[active[i]][1])
			self.UI.indicator[i].controls.icon:SetHidden(false)
			self.UI.indicator[i].controls.frame:SetHidden(false)
		end
		for i = #active+1, (#CM_MENU_CONTROLS-6) do
			self.UI.indicator[i].controls.icon:SetHidden(true)
			self.UI.indicator[i].controls.frame:SetHidden(true)
		end
	end
	self.ccChanged = false
end