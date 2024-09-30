DariansUtilities = DariansUtilities or {}
local Util = DariansUtilities
CombatMetronome.CCTracker = CombatMetronome.CCTracker or {}
local CCTracker = CombatMetronome.CCTracker
CCTracker.cc = CCTracker.cc or {}

function CCTracker:HandleEffectsChanged(_,changeType,_,_,unitTag,_,_,_,_,_,buffType,abilityType,_,unitName,_,aId,_)
	-- d(unitName.." - "..GetUnitName("player"))
	if not (unitTag == "player" or Util.Text.CropZOSString(unitName) == CombatMetronome.currentCharacterName) then
		return
	else
		if CCTracker.variables[abilityType] and CCTracker.variables[abilityType][2] and changeType == (EFFECT_RESULT_UPDATED or EFFECT_RESULT_GAINED) then
			local newAbility = {aId, abilityType}
			if not CCTracker:ResInList(abilityType) then CCTracker.ccChanged = true end
			if not CCTracker:AIdInList(aId) then table.insert(CCTracker.cc, newAbility) end
		end
		if changeType == EFFECT_RESULT_FADED then
			for i, entry in ipairs(CCTracker.cc) do
				if entry[1] == aId then
					table.remove(CCTracker.cc, i)
					CCTracker.ccChanged = true
					break
				end
			end
		end
	end
	if CCTracker.ccChanged then self:ApplyIcons() end
end

function CCTracker:ApplyIcons()
	local active = {}
	for i= 1, #CCTracker.cc do
		-- if CCTracker.variables[entry[2]] then
			if not active[CCTracker.cc[i][2]] then table.insert(active, CCTracker.cc[i][2]) end
		-- end
	end
	if active then
		for i=1, #active do
			CCTracker.UI.indicator[i].controls.icon:SetTexture(self.variables[active[i]][1])
			CCTracker.UI.indicator[i].controls.icon:SetHidden(false)
			CCTracker.UI.indicator[i].controls.frame:SetHidden(false)
		end
		for i = #active+1, (#CM_MENU_CONTROLS-6) do
			CCTracker.UI.indicator[i].controls.icon:SetHidden(true)
			CCTracker.UI.indicator[i].controls.frame:SetHidden(true)
		end
	end
	CCTracker.ccChanged = false
end