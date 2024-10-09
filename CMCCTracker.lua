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
		if self.variables[abilityType] and self.variables[abilityType].tracked and (changeType == EFFECT_RESULT_UPDATED or changeType == EFFECT_RESULT_GAINED) then
			local newAbility = {["id"] = aId, ["type"] = abilityType, ["endTime"] = endTime*1000}
			local inList, num = self:AIdInList(aId)
			-- if not self:ResInList(abilityType) then
				if not inList then
					self.ccChanged = true
					table.insert(self.cc, newAbility)
				else
					self.cc[num].endTime = endTime*1000
				end
			-- end
		elseif self.ccCache and self.ccCache[1] and self.ccCache[1].recorded == time and not self.variables[abilityType] then
			local newAbility = {["id"] = aId, ["type"] = self.ccCache[1].type, ["endTime"] = endTime*1000}
			local inList, num = self:AIdInList(aId)
			-- if not self:ResInList(self.ccCache[1][2]) then
				if not inList then
					self.ccChanged = true
					table.insert(self.cc, newAbility)
				else
					self.cc[num].endTime = endTime*1000
				end
			self.ccCache = {}
			-- end
		end
		if changeType == EFFECT_RESULT_FADED then
			for i, entry in ipairs(self.cc) do
				if entry.id == aId then
					table.remove(self.cc, i)
					self.ccChanged = true
					break
				end
			end
		end
		for i = #self.cc, 1, -1 do
			if self.cc[i].endTime < time then
				table.remove(self.cc, i)
				self.ccChanged = true
				-- d("deleting entries in cc list")
			end
		end
	end
	if CCTracker.ccChanged then self:ApplyIcons() end
end

function CCTracker:ApplyIcons()
	local active = {}
	-- d("got "..#self.cc.."debuffs in list")
	for _, entry in pairs(self.variables) do
		entry.active = false
		self.UI.indicator[entry.name].controls.frame:SetHidden(true)
		self.UI.indicator[entry.name].controls.icon:SetHidden(true)
	end
	
	for _, entry in ipairs(self.cc) do
		-- if not self:ResInList(entry.type, active) then
			-- table.insert(active, entry.type)
			self.variables[entry.type].active = true
			self.UI.indicator[self.variables[entry.type].name].controls.frame:SetHidden(false)
			self.UI.indicator[self.variables[entry.type].name].controls.icon:SetHidden(false)
		-- end
	end
	
	
	-- if active then
		-- for i=1, #active do
			-- self.UI.indicator[i].controls.icon:SetTexture(self.variables[active[i]].icon)
			-- self.UI.indicator[i].controls.icon:SetHidden(false)
			-- self.UI.indicator[i].controls.frame:SetHidden(false)
		-- end
		-- for i = #active+1, (#CM_MENU_CONTROLS-6) do
			-- self.UI.indicator[i].controls.icon:SetHidden(true)
			-- self.UI.indicator[i].controls.frame:SetHidden(true)
		-- end
	-- else 
		-- for i=1, (#CM_MENU_CONTROLS-6) do
			-- self.UI.indicator[i].controls.icon:SetHidden(true)
			-- self.UI.indicator[i].controls.frame:SetHidden(true)
		-- end
	-- end
	self.ccChanged = false
end