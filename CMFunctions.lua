local LAM = LibAddonMenu2
local Util = DariansUtilities
Util.Text = Util.Text or {}
Util.Stacks = Util.Stacks or {}
CombatMetronome.StackTracker = CombatMetronome.StackTracker or {}
local StackTracker = CombatMetronome.StackTracker
CombatMetronome.CCTracker = CombatMetronome.CCTracker or {}
local CCTracker = CombatMetronome.CCTracker

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
	
-- /script _,index,_,_,_,_ = GetAbilityProgressionXPInfoFromAbilityId(ID) d(GetSkillAbilityIndicesFromProgressionIndex(index))

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
	-- for i = 1,#ControlNames do
		-- string[i] = ControlNames[i].Name
		-- for j, controlString in ipairs(CombatMetronomeOptions.controlsToRefresh) do
			-- if string[i] == controlString then
				-- numbers = i
				-- numbers.Number = j end
		-- end
	-- end
	local number = 0
	for i, entry in ipairs(CombatMetronomeOptions.controlsToRefresh) do
		if ControlName == entry.data.name then
			number = i
		end
	end
	
	-- for i = 1,#CombatMetronomeOptions.controlsToRefresh do
		-- if string1 == CombatMetronomeOptions.controlsToRefresh[i].data.name then
			-- number1 = i
		-- end
		-- if string2 == CombatMetronomeOptions.controlsToRefresh[i].data.name then
			-- number2 = i
		-- end
		-- if string3 == CombatMetronomeOptions.controlsToRefresh[i].data.name then
			-- number3 = i
		-- end
		-- if string4 == CombatMetronomeOptions.controlsToRefresh[i].data.name then
			-- number4 = i
		-- end
		-- if string5 == CombatMetronomeOptions.controlsToRefresh[i].data.name then
			-- number5 = i
		-- end
		-- if string6 == CombatMetronomeOptions.controlsToRefresh[i].data.name then
			-- number6 = i
		-- end
		-- if string7 == CombatMetronomeOptions.controlsToRefresh[i].data.name then
			-- number7 = i-1
		-- end
	-- end
	return number
end

function CombatMetronome:GCDSpecifics(text, icon, gcdProgress)
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
	self.killingAction = nil
	self.breakingFree = nil
	self.otherSynergies = nil
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
	local CombatEventsNeedToBeRegistered = CombatMetronome.SV.Progressbar.trackMounting or CombatMetronome.SV.Progressbar.trackKillingActions or CombatMetronome.SV.Progressbar.trackBreakingFree or CombatMetronome:CheckForCCRegister()
	return CombatEventsNeedToBeRegistered
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

	--------------------------
	---- CC Tracker stuff ----
	--------------------------

CCTracker.cc = CCTracker.cc or {}
	
function CCTracker:CheckForCCRegister()
	for _, check in pairs(CombatMetronome.SV.CCTracker.CC) do
		if check == true then
			return true
		end
	end
	return false
end

function CCTracker:AIdInList(aId)
	for i, entry in ipairs(CCTracker.cc) do
        if entry.id == aId then
            return true, i -- 'aId' wurde gefunden
        end
    end
    return false -- 'aId' wurde nicht gefunden
end

function CCTracker:ResInList(res, table)
	for _, entry in ipairs(table) do
        if entry == res then
            return true -- 'res' wurde gefunden
        end
    end
    return false -- 'res' wurde nicht gefunden
end

function CCTracker:NameInList(aName)
	for i, entry in ipairs(CCTracker.cc) do
        if entry[3] == aName then
            return true, i -- 'aName' wurde gefunden
        end
    end
    return false -- 'aName' wurde nicht gefunden
end

function CCTracker:IsUnlocked()
	for _, entry in pairs(self.variables) do
		if self.UI.indicator[entry.name].controls.tlw.IsUnlocked() then 
			return true
		end
	end
	return false
end

	-------------------------
	---- Ability Adjusts ----
	-------------------------

function CombatMetronome:UpdateAdjustChoices()
	local names = self.menu.abilityAdjustChoices

	for k in pairs(names) do names[k] = nil end

	for id, adj in pairs(CombatMetronome.SV.Progressbar.abilityAdjusts) do
		local name = Util.Text.CropZOSString(GetAbilityName(id))
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
		local name = Util.Text.CropZOSString(GetAbilityName(id))
		names[#names + 1] = name
	end
	return names
end

-- function CombatMetronome:BuildListOfCurrentSkills()
	-- local list = {}
	-- local listVariables = CombatMetronome:StoreAbilitiesOnActionBar()
	-- table.insert(list, "----FRONTBAR----")
	-- for i=1,5 do
		-- table.insert(list, tostring(i..": "..listVariables[i].id..", "..listVariables[i].name))
	-- end
	-- table.insert(list, tostring("Ultimate: "..listVariables[6].id..", "..listVariables[6].name))
	-- table.insert(list, "----BACKBAR----")
	-- for i=7,11 do
		-- table.insert(list, tostring((i-6)..": "..listVariables[i].id..", "..listVariables[i].name))
	-- end
	-- table.insert(list, tostring("Ultimate: "..listVariables[12].id..", "..listVariables[12].name))
	-- return list
-- end
	-------------------------
	---- Ability Handler ----
	-------------------------

function CombatMetronome:HandleAbilityUsed(event)
    if not (self.inCombat or CombatMetronome.SV.Progressbar.trackGCD) then return end
	if event == "cancel heavy" then
		if self.currentEvent and self.currentEvent.ability.heavy then
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
		-- d("Got new Event "..event.ability.name)
	end
    self.gcd = Util.Ability.Tracker.gcd
end

	------------------------------------
	---- Check if Tracker is active ----
	------------------------------------

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
	else
		trackerIsActive = false
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
		for i=1,12 do
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
			for j=1,12 do
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
	-- d(self.inPVPZone)
	return self.inPVPZone
end

function CombatMetronome:CMPVPSwitch()
	if not CombatMetronome.SV.Progressbar.hide then
		if CombatMetronome.SV.Progressbar.hideCMInPVP and self.inPVPZone then
			if self.cmRegistered then
				self:UnregisterCM()
				self:HideBar(true)
				-- d("registered cm scenario 1")
			elseif not self.cmRegistered then
				self:HideBar(true)
				-- d("registered cm scenario 2")
			end
		else 
			if not self.cmRegistered then
				self:RegisterCM()
				self:HideBar(not CombatMetronome.SV.Progressbar.dontHide)
				-- d("registered cm scenario 3")
			else
				self:HideBar(not CombatMetronome.SV.Progressbar.dontHide)
				-- d("registered cm scenario 4")
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
				-- d("registered tracker scenario 1")
			elseif not self.registered then
				self.UI.FadeScenes("NoUi")
				-- d("registered tracker scenario 2")
			end
		else
			if not self.registered then
				self:Register()
				-- d("registered tracker scenario 3")
			end
		end
	end
end