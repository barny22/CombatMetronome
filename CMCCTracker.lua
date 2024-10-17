DariansUtilities = DariansUtilities or {}
local Util = DariansUtilities
CombatMetronome.CCTracker = CombatMetronome.CCTracker or {}
local CCTracker = CombatMetronome.CCTracker
CCTracker.cc = CCTracker.cc or {}

function CCTracker:HandleEffectsChanged(_,changeType,_,eName,unitTag,beginTime,endTime,_,_,_,buffType,abilityType,_,unitName,_,aId,_)
	-- d(unitName.." - "..GetUnitName("player"))
	time = GetFrameTimeMilliseconds()
	if not (unitTag == "player" or Util.Text.CropZOSString(unitName) == CombatMetronome.currentCharacterName) then
		return
	else
		-- self.currentBuffs = {}
		if IsUnitDeadOrReincarnating("player") then
			self.cc = {}
			self:ApplyIcons()
			return
		elseif changeType == EFFECT_RESULT_UPDATED or changeType == EFFECT_RESULT_GAINED or changeType == EFFECT_RESULT_ITERATION_BEGIN or changeType == EFFECT_RESULT_FULL_REFRESH then
			if self.variables[abilityType] and self.variables[abilityType].tracked then
				local ending = ((endTime-beginTime~=0) and endTime) or 0
				local newAbility = {["id"] = aId, ["type"] = abilityType, ["endTime"] = ending*1000}
				if self.ccCache and self.ccCache[1].type == abilityType then newAbility.cacheId = self.ccCache[1].id end
				local inList, num = self:AIdInList(aId)
				-- if not self:ResInList(abilityType) then
				if not inList then
					self.ccChanged = true
					table.insert(self.cc, newAbility)
				else
					self.cc[num].endTime = endTime*1000
				end
				if CombatMetronome.SV.debug.ccCache then d("New cc "..Util.Text.CropZOSString(eName)) end
				-- end
			elseif self.ccCache and self.ccCache[1] and self.ccCache[1].recorded == time and not self.variables[abilityType] then
				local ending = ((endTime-beginTime~=0) and endTime) or 0
				local newAbility = {["id"] = aId, ["type"] = self.ccCache[1].type, ["endTime"] = ending*1000, ["cacheId"] = self.ccCache[1].id }
				local inList, num = self:AIdInList(aId)
				-- if not self:ResInList(self.ccCache[1][2]) then
				if not inList then
					self.ccChanged = true
					table.insert(self.cc, newAbility)
				else
					self.cc[num].endTime = endTime*1000
				end
				if CombatMetronome.SV.debug.ccCache then d("New cc from cache "..Util.Text.CropZOSString(eName)) end
				self.ccCache = {}
				if CombatMetronome.SV.debug.ccCache then d("Clearing CC cache") end
				-- end
			end
		elseif changeType == EFFECT_RESULT_FADED or changeType == EFFECT_RESULT_ITERATION_END or changeType == EFFECT_RESULT_TRANSFER then
			for i, entry in ipairs(self.cc) do
				if entry.id == aId then
					table.remove(self.cc, i)
					self.ccChanged = true
					break
				end
			end
		end
		for i = #self.cc, 1, -1 do
			if self.cc[i].endTime ~= 0 then
				if self.cc[i].endTime < time then
					table.remove(self.cc, i)
					self.ccChanged = true
					-- d("deleting entries in cc list")
				end
			-- else
				-- if not self.currentBuffs then
					-- for i = 1, GetNumBuffs() do
						-- local _, _, _, _, _, _, _, _, _, _, aId, _, _ = GetUnitBuffInfo("player", i)
						-- self.currentBuffs[aId] = true
					-- end
				-- end
				-- if not self.currentBuffs[self.cc[i].id] then
					-- table.remove(self.cc, i)
				-- end
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
	if CombatMetronome.SV.debug.ccCache then d("Done with hiding CC icons") end
	
	for _, entry in ipairs(self.cc) do
		-- if not self:ResInList(entry.type, active) then
			-- table.insert(active, entry.type)
			self.variables[entry.type].active = true
			self.UI.indicator[self.variables[entry.type].name].controls.frame:SetHidden(false)
			self.UI.indicator[self.variables[entry.type].name].controls.icon:SetHidden(false)
		-- end
	end
	if CombatMetronome.SV.debug.ccCache then d("CC icons are shown") end
	
	
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