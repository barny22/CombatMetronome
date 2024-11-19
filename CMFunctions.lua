local LAM = LibAddonMenu2
local Util = DariansUtilities
Util.Text = Util.Text or {}
Util.Stacks = Util.Stacks or {}
CombatMetronome.StackTracker = CombatMetronome.StackTracker or {}
local StackTracker = CombatMetronome.StackTracker

local bAId = { ["buff"] = 203447, ["ability"] = 24165,}
local mWId = { ["buff"] = 122658, ["ability"] = 20805,} -- 122729
local gFId = {
	["gF"] = { ["buff"] = 122585, ["ability"] = 61902,},
	["mR"] = { ["buff"] = 122586, ["ability"] = 61919,},
	["rF"] = { ["buff"] = 122587, ["ability"] = 61927,},
	}
local fSId = {
	["fS"] = { ["buff"] = 114131, ["ability"] = {
	[1] = 114108, [2] = 123683, [3] = 123685
	}},	
	["rS"] = { ["buff"] = 117638, ["ability"] = {
	[1] = 117637, [2] = 123718, [3] = 123719
	}},
	["vS"] = { ["buff"] = 117625, ["ability"] = {
	[1] = 117624, [2] = 123699, [3] = 123704
	}},
	}
	
-- local previousStack = 0

	--------------------------------------------------------------------------------------------------------------------
	---- Script to get (SkillType skillType, luaindex skillLineIndex, luaindex skillIndex) to determine skill morph ----
	--------------------------------------------------------------------------------------------------------------------
	
-- /script _,index,_,_,_,_ = GetAbilityProgressionXPInfoFromAbilityId(ID) CombatMetronome.debug:Print(GetSkillAbilityIndicesFromProgressionIndex(index))

	--------------------------
	---- Helper Functions ----
	--------------------------

function CombatMetronome:OnCDStop()
	if CombatMetronome.SV.Progressbar.dontHide then
		if CombatMetronome.SV.Progressbar.makeItFancy then
			self:HideFancy(false)
		else
			self:HideFancy(true)
		end
	else
		self:HideFancy(true)
		self.Progressbar.bar:SetHidden(true)
	end
	self:HideLabels(true)
	if self.currentEvent then
		self.abilityFinished = GetFrameTimeMilliseconds()
	end
	self:SetEventNil()
end

function CombatMetronome:HideBar(value)
	if CombatMetronome.SV.Progressbar.makeItFancy then
		self:HideFancy(value)
	else
		self:HideFancy(true)
	end
	self.Progressbar.bar:SetHidden(value)
end

function CombatMetronome:SetEventNil()
	self.currentEvent = nil
	self.Progressbar.bar.segments[1].progress = 0
	self.Progressbar.bar.segments[2].progress = 0
	self.Progressbar.bar.backgroundTexture:SetWidth(0)
end

function CombatMetronome:HideLabels(value)
	self.Progressbar.spellLabel:SetHidden(value)
	self.Progressbar.timeLabel:SetHidden(value)
	self.Progressbar.spellIcon:SetHidden(value)
	self.Progressbar.spellIconBorder:SetHidden(value)
end

function CombatMetronome:HideFancy(value)
	self.Progressbar.bar.backgroundTexture:SetHidden(value)
	self.Progressbar.bar.borderL:SetHidden(value)
	self.Progressbar.bar.borderR:SetHidden(value)
end

	--------------------------------
	---- GCD Tracking specifics ----
	--------------------------------
	
function CombatMetronome:CreateMenuIconsPath(ControlName)
	local number = 0
	for i, entry in ipairs(CombatMetronomeOptions.controlsToRefresh) do
		if ControlName == entry.data.name then
			number = i
		end
	end
	return number
end

function CombatMetronome:GCDSpecifics(text, icon, gcdProgress, wasSynergy)
	if not wasSynergy and self.Progressbar.synergy.wasUsed then self.Progressbar.synergy.wasUsed = false end
	if CombatMetronome.SV.Progressbar.showSpell then
		self.Progressbar.spellLabel:SetHidden(false)
		self.Progressbar.spellIcon:SetHidden(false)
		self.Progressbar.spellIconBorder:SetHidden(false)
		self.Progressbar.spellIcon:SetTexture(icon)
		self.Progressbar.spellLabel:SetText(text)
	else
		self.Progressbar.spellLabel:SetHidden(true)
		self.Progressbar.spellIcon:SetHidden(true)
		self.Progressbar.spellIconBorder:SetHidden(true)
	end
	if CombatMetronome.SV.Progressbar.showTimeRemaining then
		self.Progressbar.timeLabel:SetHidden(false)
		self.Progressbar.timeLabel:SetText(string.format("%.1fs", gcdProgress))
	else
		self.Progressbar.timeLabel:SetHidden(true)
	end
	if gcdProgress == 0 then CombatMetronome:SetIconsAndNamesNil() end
end

function CombatMetronome:SetIconsAndNamesNil()
	self.Progressbar.activeMount.action = ""
	self.Progressbar.collectibleInUse = nil
	self.Progressbar.itemUsed = nil
	-- self.Progressbar.killingAction = nil
	self.Progressbar.breakingFree = nil
	self.Progressbar.synergy.wasUsed = false
	-- self.Progressbar.nonAbilityGCDRunning = false
	self.Progressbar.timeLabel:SetHidden(true)
	self.Progressbar.spellLabel:SetHidden(true)
	self.Progressbar.spellIcon:SetHidden(true)
	self.Progressbar.spellIconBorder:SetHidden(true)
end

	-----------------------
	---- Combat Events ----
	-----------------------

function CombatMetronome:CheckForCombatEventsRegister()
	-- local ccTrackingActive = CombatMetronome:CheckForCCRegister()
	if CombatMetronome.SV.Progressbar.trackMounting or CombatMetronome.SV.Progressbar.trackSynergies or CombatMetronome.SV.Progressbar.trackBreakingFree then
		return true
	end
	return false
end

-- function CombatMetronome:HandleCombatEvents(...)
    -- local e = Util.CombatEvent:New(...)

    -- if e:IsPlayerTarget() and not e:IsError() then
        -- local r = e:GetResult()
        -- if r == ACTION_RESULT_KNOCKBACK
        -- or r == ACTION_RESULT_PACIFIED
        -- or r == ACTION_RESULT_STAGGERED
        -- or r == ACTION_RESULT_STUNNED
        -- or r == ACTION_RESULT_INTERRUPT then
            -- self.currentEvent = nil
            -- return
        -- end
    -- end
-- end

	-------------------------
	---- Ability Adjusts ----
	-------------------------
local ABILITY_ADJUST_PLACEHOLDER = "Add ability adjust"

function CombatMetronome:UpdateAdjustChoices()
	local names = self.menu.abilityAdjustChoices

	for k in pairs(names) do names[k] = nil end

	for id, adj in pairs(CombatMetronome.SV.Progressbar.abilityAdjusts) do
		local name = "|t20:20:"..GetAbilityIcon(id).."|t "..Util.Text.CropZOSString(GetAbilityName(id))
		names[#names + 1] = name
	end

    if #names == 0 then
        names[1] = ABILITY_ADJUST_PLACEHOLDER
        self.menu.curSkillName = ABILITY_ADJUST_PLACEHOLDER
        self.menu.curSkillId = -1
    else
        if not CombatMetronome.SV.Progressbar.abilityAdjusts[self.menu.curSkillId] then
            for id, _ in pairs(CombatMetronome.SV.Progressbar.abilityAdjusts) do
                self.menu.curSkillId = id
                self.menu.curSkillName = GetAbilityName(id)
                break
            end
        end
    end

	local panelControls = self.menu.panel.controlsToRefresh
	for i = 1, #panelControls do
		local control = panelControls[i]
		if (control.data and control.data.name == "Select skill adjust") then
			control:UpdateChoices()
			control:UpdateValue()
			break
		end
	end
end

function CombatMetronome:CreateAdjustList()
	local names = {}
	for id, adj in pairs(CombatMetronome.SV.Progressbar.abilityAdjusts) do
		local name = "|t20:20:"..GetAbilityIcon(id).."|t "..Util.Text.CropZOSString(GetAbilityName(id))
		names[#names + 1] = name
	end
	if #names == 0 then table.insert(names, ABILITY_ADJUST_PLACEHOLDER) end
	return names
end

function CombatMetronome:CropIconFromSkill(ability)
    local _, iconDivider = string.find(ability, "%|t ")
    
    if iconDivider then
        return string.sub(ability, iconDivider + 1, -1)
    else
        return ability
    end
end

function CombatMetronome:FindSkillInAdjustList(name)
	for i, entry in ipairs(self.menu.abilityAdjustChoices) do
		if self:CropIconFromSkill(entry) == name then return i end
	end
end

function CombatMetronome:IsSkillCurrentlyEquipped(id)
	for i, entry in ipairs(self.currentlyEquippedAbilities.data) do
		if id == entry.id then return i end
	end
	return false
end

function CombatMetronome:GetEquippedSkillData(selectedSkill)
	for i, entry in ipairs(self.currentlyEquippedAbilities.list) do
		if entry == selectedSkill then
		-- self.debug:Print("Returning selected skill data")
		-- d(self.currentlyEquippedAbilities.data[i])
		return self.currentlyEquippedAbilities.data[i] end
	end
end

function CombatMetronome:BuildListOfCurrentlyEquippedAbilities()
	self.currentlyEquippedAbilities.data = Util.Stacks:StoreAbilitiesOnActionBar()
	
	-- clear current list
	if self.currentlyEquippedAbilities.list then
		for i in pairs(self.currentlyEquippedAbilities.list) do self.currentlyEquippedAbilities.list[i] = nil end
	end
	
	if not self.currentlyEquippedAbilities.list then self.currentlyEquippedAbilities.list = {} end
	
	for i, skill in ipairs(self.currentlyEquippedAbilities.data) do
		self.currentlyEquippedAbilities.list[i] = tostring("|t20:20:"..skill.icon.."|t "..skill.name)
	end
	
	-- refresh equipped ability list
	if self.menu.panel then
		local panelControls = self.menu.panel.controlsToRefresh
		for i = 1, #panelControls do
			local control = panelControls[i]
			if (control.data and control.data.name == "Currently equipped abilities:") then
				-- CombatMetronome.debug:Print("Updating currently equipped skills")
				-- self.currentlyEquippedAbilities = self:BuildListOfCurrentlyEquippedAbilities()
				control:UpdateChoices()
				control:UpdateValue()
				break
			end
		end
	end
end

	-------------------------
	---- Ability Handler ----
	-------------------------

function CombatMetronome:HandleAbilityUsed(event)
    if not (self.inCombat or CombatMetronome.SV.Progressbar.showOOC) then return end
	if CombatMetronome.SV.debug.abilityUsed and event.ability then CombatMetronome.debug:Print("New event "..event.ability.name.." recieved in CombatMetronome") end
	if event == "cancel heavy" then
		if self.currentEvent and self.currentEvent.ability.heavy then
			if CombatMetronome.SV.debug.currentEvent then CombatMetronome.debug:Print("Canceled heavy"..self.currentEvent.ability.name) end
			self.currentEvent = nil
			self.gcd = 0
		end
		return
	end

    self.Progressbar.soundTickPlayed = false
    self.Progressbar.soundTockPlayed = false

    local ability = event.ability

    event.adjust = (CombatMetronome.SV.Progressbar.abilityAdjusts[ability.id] or 0)
                    + ((ability.instant and CombatMetronome.SV.Progressbar.gcdAdjust)
                    or (ability.heavy and CombatMetronome.SV.Progressbar.globalHeavyAdjust)
                    or CombatMetronome.SV.Progressbar.globalAbilityAdjust)
					
	if CombatMetronome.SV.Progressbar.stopHATracking and event.ability.heavy then
		return
	else
		self.currentEvent = event
		-- if self.SV.debug.enabled then CombatMetronome.debug:Print("Got new Event "..event.ability.name) end
	end
	self.lastAbilityFinished = self.abilityFinished
	self.abilityFinished = event.start + math.max(ability.delay, 1000)
    self.gcd = Util.Ability.Tracker.gcd
end

	-------------------------------------------
	---- Check if Stack  Tracker is active ----
	-------------------------------------------

function StackTracker:TrackerIsActive()
	local trackerIsActive = false
	if self.class == "ARC" and CombatMetronome.SV.StackTracker.trackCrux then
		trackerIsActive = true
	elseif self.class == "DK" and CombatMetronome.SV.StackTracker.trackMW then
		trackerIsActive = true
	elseif self.class == "SORC" and CombatMetronome.SV.StackTracker.trackBA then
		trackerIsActive = true
	elseif self.class == "NB" and CombatMetronome.SV.StackTracker.trackGF then
		trackerIsActive = true
	elseif self.class == "CRO" and CombatMetronome.SV.StackTracker.trackFS then
		trackerIsActive = true
	end
	return trackerIsActive
end

		---------------------------------------
        ---- Store abilities on Actionbars ----
        ---------------------------------------

-- function CombatMetronome:StoreAbilitiesOnActionBar()
    -- local actionSlots = {}  -- Create a table to store action slots

    -- for j = 0, 1 do
        -- for i = 3, 8 do
            -- local actionSlot = {}  -- Create a new table for each action slot
			-- local slotType = GetSlotType(i, j)
            -- setmetatable(actionSlot, {__index = index})
            
            -- actionSlot.place = tostring(i .. j)
			-- if slotType == ACTION_TYPE_CRAFTED_ABILITY then
				-- actionSlot.id = GetAbilityIdForCraftedAbilityId(GetSlotBoundId(i, j))
			-- else
				-- actionSlot.id = GetSlotBoundId(i, j)
			-- end
            -- actionSlot.icon = GetAbilityIcon(actionSlot.id)
            -- actionSlot.name = Util.Text.CropZOSString(GetAbilityName(actionSlot.id))

            -- table.insert(actionSlots, actionSlot)  -- Add the current action slot to the table
        -- end
    -- end

    -- return actionSlots
-- end

		------------------------------------------------
        ---- Tracker check if abilities are slotted ----
        ------------------------------------------------
		
function StackTracker:CheckIfSlotted()
	local ability = ""
	local abilitySlotted = false
	if self.class == "SORC" then ability = bAId.ability
	elseif self.class == "NB" then 
		local morph = Util.Stacks:CheckForGFMorph()
		ability = gFId[morph].ability
	elseif self.class == "DK" then ability = mWId.ability
	end
	if ability ~= "" then
		for i=1,#self.actionSlotCache do
			if self.actionSlotCache[i].id == ability then
				abilitySlotted = true
				break
			end
		end
	elseif self.class == "ARC" then abilitySlotted = true
	elseif self.class == "CRO" then
		local morph = Util.Stacks:CheckForFSMorph()
		for i=1,3 do
			ability = fSId[morph].ability[i]
			for j=1,#self.actionSlotCache do
				if self.actionSlotCache[j].id == ability then
					abilitySlotted = true
					break
				end
			end
			if ablilitySlotted then
				break
			end
		end
	end
	return abilitySlotted
end

		-------------------------------
        ---- PVP Check and Handler ----
        -------------------------------

function CombatMetronome:IsInPvPZone()
	if IsActiveWorldBattleground() or IsPlayerInAvAWorld() then
		self.inPVPZone = true
	else
		self.inPVPZone = false
	end
	-- if self.SV.debug.enabled then CombatMetronome.debug:Print(self.inPVPZone) end
	return self.inPVPZone
end

function CombatMetronome:CMPVPSwitch()
	if not CombatMetronome.SV.Progressbar.hide then
		if CombatMetronome.SV.Progressbar.hideCMInPVP and self.inPVPZone then
			if self.cmRegistered then
				self:UnregisterCM()
				self:HideBar(true)
				-- if self.SV.debug.enabled then CombatMetronome.debug:Print("registered cm scenario 1") end
			elseif not self.cmRegistered then
				self:HideBar(true)
				-- if self.SV.debug.enabled then CombatMetronome.debug:Print("registered cm scenario 2") end
			end
		else 
			if not self.cmRegistered then
				self:RegisterCM()
				self:HideBar(not CombatMetronome.SV.Progressbar.dontHide)
				-- if self.SV.debug.enabled then CombatMetronome.debug:Print("registered cm scenario 3") end
			else
				self:HideBar(not CombatMetronome.SV.Progressbar.dontHide)
				-- if self.SV.debug.enabled then CombatMetronome.debug:Print("registered cm scenario 4") end
			end
		end
	end
end

function CombatMetronome:ResourcesPVPSwitch()
	-- local hideResources = false
	if CombatMetronome.SV.Resources.hideInPVP and self.inPVPZone then
		-- hideResources = true
		if self.rtRegistered then
			self:UnregisterResourceTracker()
			self.Resources.stamLabel:SetHidden(true)
            self.Resources.magLabel:SetHidden(true)
            self.Resources.hpLabel:SetHidden(true)    
            self.Resources.ultLabel:SetHidden(true)
		elseif not self.rtRegistered then
			self.Resources.stamLabel:SetHidden(true)
            self.Resources.magLabel:SetHidden(true)
            self.Resources.hpLabel:SetHidden(true)    
            self.Resources.ultLabel:SetHidden(true)
		end
	else
		if not self.rtRegistered then
			self:RegisterResourceTracker()
		end
		-- hideResources = false
	end
	-- return hideResources
end

function StackTracker:PVPSwitch()
	if self:TrackerIsActive() then
		if CombatMetronome.SV.StackTracker.hideInPVP and CombatMetronome.inPVPZone then
			if self.registered then
				self:Unregister()
				self.UI.FadeScenes("NoUI")
				-- if self.SV.debug.enabled then CombatMetronome.debug:Print("registered tracker scenario 1") end
			elseif not self.registered then
				self.UI.FadeScenes("NoUi")
				-- if self.SV.debug.enabled then CombatMetronome.debug:Print("registered tracker scenario 2") end
			end
		else
			if not self.registered then
				self:Register()
				-- if self.SV.debug.enabled then CombatMetronome.debug:Print("registered tracker scenario 3") end
			end
		end
	end
end

		--------------
        ---- Menu ----
        --------------
		
local MENU_SOUND_CONTROLS = {
["Volume of 'tick' and 'tock'"] = true,
["Sound 'tick'"] = true,
["Sound 'tock'"] = true,
["Sound 'tick' effect"] = true,
["Sound 'tock' effect"] = true,
["Sound 'tick' offset"] = true,
["Sound 'tock' offset"] = true,
["Play 'tick' at the start of an ability"] = true,
["Don't play 'tick' on heavy attacks"] = true,
["Play sounds ooc"] = true,
}

function CombatMetronome:RefreshSoundControls()
	if not self.menu.soundControlsToRefresh then self.menu.soundControlsToRefresh = {} end
	if #self.menu.soundControlsToRefresh == 0 then
		if self.menu.panel then
			local num = 0
			for _,_ in pairs(MENU_SOUND_CONTROLS) do
				num = num + 1
			end
			local updateCount = 0
			local panelControls = self.menu.panel.controlsToRefresh
			for i, control in ipairs(panelControls) do
				if control.data and MENU_SOUND_CONTROLS[control.data.name] then
					if control.UpdateValue then control:UpdateValue() end
					if control.UpdateDisabled then control:UpdateDisabled() end
					updateCount = updateCount + 1
					self.menu.soundControlsToRefresh[updateCount] = i				
				end
				if updateCount == num then break end -- number of 
			end
		end
	else
		-- CombatMetronome.debug:Print("Second wind")
		for _, i in ipairs(self.menu.soundControlsToRefresh) do
			if self.menu.panel.controlsToRefresh[i].UpdateValue then self.menu.panel.controlsToRefresh[i]:UpdateValue() end
			if self.menu.panel.controlsToRefresh[i].UpdateDisabled then self.menu.panel.controlsToRefresh[i]:UpdateDisabled() end
		end
	end
end

		---------------
        ---- Debug ----
        ---------------
		
function CombatMetronome:SetAllDebugFalse()
	for entry, bool in pairs(CombatMetronome.SV.debug) do
		CombatMetronome.SV.debug[entry] = false
	end
	CombatMetronome.SV.debug.triggerTimer = 170
end