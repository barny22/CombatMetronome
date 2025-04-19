local LAM = LibAddonMenu2
local Util = DariansUtilities
Util.Text = Util.Text or {}
Util.Stacks = Util.Stacks or {}
CombatMetronome.StackTracker = CombatMetronome.StackTracker or {}
local StackTracker = CombatMetronome.StackTracker
	
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
	
function CombatMetronome:CreateMenuIconsPath(ControlName, panel)
	local number = 0
	for i, entry in ipairs(panel.controlsToRefresh) do
		if ControlName == entry.data.name then
			number = i
		end
	end
	return number
end

function CombatMetronome:GCDSpecifics(text, icon, gcdProgress, wasSynergy)
	if not (text and icon) then return end
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
	self.Progressbar.jesterFestivalCherryBlossom = false
	-- self.itemCache = nil
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
		local name = "|t20:20:"..GetAbilityIcon(id).."|t "..Util.Text.CropZOSString(GetAbilityName(id), "ability")
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

	local panelControls = self.menu.panels.progressbar.controlsToRefresh
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
		local name = "|t20:20:"..GetAbilityIcon(id).."|t "..Util.Text.CropZOSString(GetAbilityName(id), "ability")
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
	if self.menu.panels and self.menu.panels.progressbar then
		local panelControls = self.menu.panels.progressbar.controlsToRefresh
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
	if CombatMetronome.SV.debug.abilityUsed and event.ability then CombatMetronome.debug:Print("New event "..event.ability.name.." recieved in CombatMetronome. ID: "..event.ability.id) end
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
function StackTracker:MorphCheck()
	if CombatMetronome.API < 101046 then
		if self.class == "NB" then
			Util.Stacks.morphs.GF = Util.Stacks:CheckMorph("NB")
		elseif self.class == "CRO" then
			Util.Stacks.morphs.FS = Util.Stacks:CheckMorph("CRO")
		end
	else
		
	end
end

function StackTracker:TrackerIsActive(skill)
	if skill then
		if self:IsTrackingAvailable(skill) and CombatMetronome.SV.StackTracker[skill].tracked then
			return true
		end
		return false
	else
		for skill, _ in pairs(self.SKILL_ATTRIBUTES) do
			if self:IsTrackingAvailable(skill) and CombatMetronome.SV.StackTracker[skill].tracked then
				return true
			end
		end
		return false
	end
end

function StackTracker:EffectChangedShouldBeActive()
	if self:TrackerIsActive("FS") and not self:IsTrackingAvailable("FS") then
		return true
	end
	return false
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
            -- actionSlot.name = Util.Text.CropZOSString(GetAbilityName(actionSlot.id), "ability")

            -- table.insert(actionSlots, actionSlot)  -- Add the current action slot to the table
        -- end
    -- end

    -- return actionSlots
-- end

		------------------------------------------------
        ---- Tracker check if abilities are slotted ----
        ------------------------------------------------
		
function StackTracker:CheckIfSlotted(skill)
	local ability = ""
	local attributes = StackTracker.SKILL_ATTRIBUTES[skill]
	local abilitySlotted = false
	if skill == "BA" or skill == "MW" or skill == "FI" then ability = attributes.id.ability
	elseif skill == "GF" then 
		local morph = Util.Stacks.morphs.GF
		ability = attributes.id[morph].ability
	end
	if ability ~= "" then
		for i=1,#self.actionSlotCache do
			if self.actionSlotCache[i].id == ability then
				abilitySlotted = true
				break
			end
		end
	elseif self.class == "ARC" then abilitySlotted = true
	elseif skill == "FS" then
		local morph = Util.Stacks.morphs.FS
		for i=1,3 do
			ability = attributes.id[morph].ability[i]
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

function StackTracker:GetCurrentStacks(skill)
	local stacks
	if self:CheckIfSlotted(skill) then
		stacks = Util.Stacks:GetCurrentNumStacksOnPlayer(skill)
		return stacks
	end
	return 0
end

function StackTracker:IsTrackingAvailable(skill)
	if CombatMetronome.API < 101046 then
		if skill == "MW" then
			return self.class == "DK"
		elseif skill == "BA" then
			return self.class == "SORC"
		elseif skill == "GF" then
			return self.class == "NB"
		elseif skill == "Crux" then
			return self.class == "ARC"
		elseif skill == "FS" then
			return self.class == "CRO"
		elseif skill == "FI" then
			return self.class == "DEN"
		end
	else
		return self.activeSkills[skill]
	end
end

function StackTracker:GetRelevantActiveSkillLines()
	for skill, entry in pairs(self.SKILL_ATTRIBUTES) do
		if type(entry.skillLineIndex == "table" then
			for _, id in ipairs(entry.skillLineIndex) do
				local _,_,isActive,_,_,_ = GetSkillLineDynamicInfo(SKILL_TYPE_CLASS, id)
				self.activeSkills[skill] = isActive
				if isActive then break end
			end
		else
			local _,_,isActive,_,_,_ = GetSkillLineDynamicInfo(SKILL_TYPE_CLASS, entry.skillLineIndex)
			self.activeSkills[skill] = isActive
		end
	end
end

function StackTracker:InitializeUI(skill)
	if not self.UI[skill] then
		self.UI[skill] = self:BuildUI(skill)
		self.UI[skill].indicator.ApplyDistance(CombatMetronome.SV.StackTracker[skill].indicatorSize/5, CombatMetronome.SV.StackTracker[skill].indicatorSize)
		self.UI[skill].indicator.ApplySize(CombatMetronome.SV.StackTracker[skill].indicatorSize)
		self.UI[skill].indicator.ApplyIcon()
		self.UI[skill].stacksWindow:SetMovable(CombatMetronome.SV.StackTracker.isUnlocked)
		if CombatMetronome.SV.StackTracker.isUnlocked then self:HandleUIVisibility(skill, "Sample") end
	end
	self:HandleUIVisibility(skill, "UI")
end

function StackTracker:HandleUIVisibility(skill, scene)
	if StackTracker.UI[skill] then
		StackTracker.UI[skill].FadeScenes(scene)
		StackTracker.UI[skill].stacksWindow:SetHidden(false)
		if scene == "NoUI" or scene == "NoSample" then
			StackTracker.UI[skill].stacksWindow:SetHidden(true)
		end
	end
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

function StackTracker:PVPSwitch(skill)
	if self:TrackerIsActive(skill) and self:CheckIfSlotted(skill) and self.UI[skill] then
		if CombatMetronome.SV.StackTracker[skill].hideInPVP and CombatMetronome.inPVPZone then
			if (skill == "FS" and self.registered.hotbarUpdate) or self.registered.effectChanged[skill] then
				self:Unregister(skill)
				self.UI[skill].FadeScenes("NoUI")
				-- if self.SV.debug.enabled then CombatMetronome.debug:Print("registered tracker scenario 1") end
			else
				self.UI[skill].FadeScenes("NoUi")
				-- if self.SV.debug.enabled then CombatMetronome.debug:Print("registered tracker scenario 2") end
			end
		else
			if not (skill == "FS" and self.registered.hotbarUpdate) or self.registered.effectChanged[skill] then
				self:Register(skill)
				-- if self.SV.debug.enabled then CombatMetronome.debug:Print("registered tracker scenario 3") end
			end
		end
	elseif self:TrackerIsActive(skill) and self:CheckIfSlotted(skill) and not self.UI[skill] and not CombatMetronome.inPVPZone then
		self:InitializeUI(skill)
		self:Register(skill)
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

		-----------------------------
        ---- CoralBahseiTracking ----
        -----------------------------

function CombatMetronome:UpdateCoralBahsei(setId, changeType, unitTag, localPlayer, activeType)
	if setId == 647 then
		self.Resources.coralActive = self.LSD.ConvertActiveType(activeType)
	elseif setId == 147 then
		self.Resources.mkActive = self.LSD.ConvertActiveType(activeType)
	elseif setId == 587 then
		self.Resources.bahseiActive = self.LSD.ConvertActiveType(activeType)
	elseif not setId then
		self.Resources.mkActive = self.LSD.ConvertActiveType(self.LSD.GetUnitSetActiveType("player", 147))
		self.Resources.coralActive = self.LSD.ConvertActiveType(self.LSD.GetUnitSetActiveType("player", 647))
		self.Resources.bahseiActive = self.LSD.ConvertActiveType(self.LSD.GetUnitSetActiveType("player", 587))
	end
	self.Progressbar.UI.Anchors()
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

function CombatMetronome:AutomaticSVCleanup()
	local year, month, day = GetDateElementsFromTimestamp(GetTimeStamp())
	if self.SV.automaticSVCleanup.lastCleanup.year == year or (self.SV.automaticSVCleanup.lastCleanup.year == year - 1 and self.SV.automaticSVCleanup.lastCleanup.month < month) then
		CombatMetronome.debug:Print("No SV cleanup necessary. Last SV cleanup has taken place less than a year ago on "..self.SV.lastSVCleanup.lastCleanup.day.."-"..self.SV.lastSVCleanup.lastCleanup.month.."-"..self.SV.lastSVCleanup.lastCleanup.year)
	elseif self.SV.automaticSVCleanup.lastCleanup.year == 0 then
		CombatMetronome.debug:Print("No SV cleanup has taken place yet. Starting automatic cleanup.")
		self:CleanupSVEnstries()
	elseif year > self.SV.automaticSVCleanup.lastCleanup.year and month >= self.SV.lastSVCleanup.lastCleanup.month then
		self.SV.lastSVCleanup = {["year"] = year, ["month"] = month, ["day"] = day}
		CombatMetronome.debug:Print("Last SV cleanup was about a year ago. Starting automatic cleanup.")
		self:CleanupSVEntries()
	end
end

function CombatMetronome:CleanupSVEntries()
	for _, vars in pairs(CombatMetronomeSavedVars.Default[GetDisplayName()]) do
		for section, subsection in pairs(vars) do
			local sectionNeedsClearing = true
			for entry, _ in pairs(CombatMetronome.DEFAULT_SAVED_VARS) do
				if entry == section then
					sectionNeedsClearing = false
					break
				end
			end
			if sectionNeedsClearing then
				-- vars[section] = nil
				CombatMetronome.debug:Print("saved vars cleanup - cleaning section: |c2a52be"..section.."|r")
			elseif type(subsection) == "table" then
				for name, _ in pairs(subsection) do
					local needsToBeCleaned = true
					for entry, _ in pairs(CombatMetronome.DEFAULT_SAVED_VARS[section]) do
						if name == entry then
							needsToBeCleaned = false
							break
						end
					end
					if needsToBeCleaned then
						-- subsection[name] = nil
						CombatMetronome.debug:Print("saved vars cleanup - cleaning option/table: |c2a52be"..section.."|r - |ce11212"..name.."|r")
					end
				end
			end
		end
	end
end