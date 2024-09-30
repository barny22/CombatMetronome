local LAM = LibAddonMenu2
local Util = DariansUtilities
Util.Text = Util.Text or {}
Util.Stacks = Util.Stacks or {}
CombatMetronome.CCTracker = CombatMetronome.CCTracker or {}
local CCTracker = CombatMetronome.CCTracker

-- IDs for easier access
local cruxId = 184220
local carverId1 = 183122
local carverId2 = 193397
local dodgeId = 29721
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
	if self.config.dontHide then
		if self.config.makeItFancy then
			self:HideFancy(false)
		else
			self:HideFancy(true)
		end
	else
		self:HideFancy(true)
		self.bar:SetHidden(true)
	end
	self:HideLabels(true)
	self:SetEventNil()
end

function CombatMetronome:HideBar(value)
	if self.config.makeItFancy then
		self:HideFancy(value)
	else
		self:HideFancy(true)
	end
	self.bar:SetHidden(value)
end

function CombatMetronome:SetEventNil()
	self.currentEvent = nil
	self.bar.segments[1].progress = 0
	self.bar.segments[2].progress = 0
	self.bar.backgroundTexture:SetWidth(0)
end

function CombatMetronome:HideLabels(value)
	self.spellLabel:SetHidden(value)
	self.timeLabel:SetHidden(value)
	self.spellIcon:SetHidden(value)
	self.spellIconBorder:SetHidden(value)
end

function CombatMetronome:HideFancy(value)
	self.bar.backgroundTexture:SetHidden(value)
	self.bar.borderL:SetHidden(value)
	self.bar.borderR:SetHidden(value)
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
	if self.config.showSpell then
		self.spellLabel:SetHidden(false)
		self.spellIcon:SetHidden(false)
		self.spellIconBorder:SetHidden(false)
		self.spellIcon:SetTexture(icon)
		self.spellLabel:SetText(text)
	else
		self.spellLabel:SetHidden(true)
		self.spellIcon:SetHidden(true)
		self.spellIconBorder:SetHidden(true)
	end
	if self.config.showTimeRemaining then
		self.timeLabel:SetHidden(false)
		self.timeLabel:SetText(string.format("%.1fs", gcdProgress))
	else
		self.timeLabel:SetHidden(true)
	end
	if gcdProgress == 0 then CombatMetronome:SetIconsAndNamesNil() end
end

function CombatMetronome:SetIconsAndNamesNil()
	self.activeMount.action = ""
	self.collectibleInUse = nil
	self.itemUsed = nil
	self.killingAction = nil
	self.breakingFree = nil
	self.otherSynergies = nil
	self.timeLabel:SetHidden(true)
	self.spellLabel:SetHidden(true)
	self.spellIcon:SetHidden(true)
	self.spellIconBorder:SetHidden(true)
end

	-----------------------
	---- Combat Events ----
	-----------------------

function CombatMetronome:CheckForCombatEventsRegister()
	-- local ccTrackingActive = CombatMetronome:CheckForCCRegister()
	local CombatEventsNeedToBeRegistered = (self.config.trackMounting or self.config.trackKillingActions or	self.config.trackBreakingFree)
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
	
function CombatMetronome:CheckForCCRegister()
	for _, check in pairs(self.config.CC) do
		if check == true then
			return true
		end
	end
	return false
end

function CCTracker:AIdInList(aId)
	for i, entry in ipairs(CCTracker.cc) do
        if entry[1] == aId then
            return true, i -- 'aId' wurde gefunden
        end
    end
    return false -- 'aId' wurde nicht gefunden
end

function CCTracker:ResInList(res)
	for i, entry in ipairs(CCTracker.cc) do
        if entry[2] == res then
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

	-------------------------
	---- Ability Adjusts ----
	-------------------------

function CombatMetronome:UpdateAdjustChoices()
	local names = self.menu.abilityAdjustChoices

	for k in pairs(names) do names[k] = nil end

	for id, adj in pairs(self.config.abilityAdjusts) do
		local name = Util.Text.CropZOSString(GetAbilityName(id))
		names[#names + 1] = name
	end

    if #names == 0 then
        names[1] = ABILITY_ADJUST_PLACEHOLDER
        self.menu.curSkillName = ABILITY_ADJUST_PLACEHOLDER
        self.menu.curSkillId = -1
    else
        if not self.config.abilityAdjusts[self.menu.curSkillId] then
            for id, _ in pairs(self.config.abilityAdjusts) do
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
		for id, adj in pairs(self.config.abilityAdjusts) do
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
    if not (self.inCombat or self.config.showOOC) then return end
	if event == "cancel heavy" then
		if self.currentEvent and self.currentEvent.ability.heavy then
			self.currentEvent = nil
			self.gcd = 0
		end
		return
	end

    self.soundTickPlayed = false
    self.soundTockPlayed = false

    local ability = event.ability

    event.adjust = (self.config.abilityAdjusts[ability.id] or 0)
                    + ((ability.instant and self.config.gcdAdjust)
                    or (ability.heavy and self.config.globalHeavyAdjust)
                    or self.config.globalAbilityAdjust)
	
	-- d(event.ability.id)						--gives 183122 for Fatecarver
	-- if	event.ability.id == carverId1 or event.ability.id == carverId2 then
		-- local cruxes = CombatMetronome:GetCurrentNumCruxOnPlayer()
		-- event.adjust = event.adjust + (338 * cruxes)
		-- d(string.format("Fatecarver duration succesfully adjusted with %d crux(es)", cruxes))
	-- end
	if self.config.stopHATracking and event.ability.heavy then
		return
	else
		self.currentEvent = event
		-- d("Got new Event "..event.ability.name)
	end
    self.gcd = Util.Ability.Tracker.gcd
end

	-----------------------
	---- Crux Tracking ----
	-----------------------

-- function CombatMetronome:GetCurrentNumCruxOnPlayer()					-- Crux Tracking by barny (special thanks to akasha who basically did all the work)
	-- local start = GetGameTimeMilliseconds()
	-- local crux = 0
	-- if self.class == "ARC" then
		-- for i=1,GetNumBuffs("player") do
			-- local name,_,_,_,stack,_,_,_,_,statusEffectType,abilityId = GetUnitBuffInfo("player", i)
			-- if	abilityId == cruxId then
				-- crux = stack
				-- d("You currently have "..tostring(crux).." Crux")
			-- break 
			-- end
		-- end
	-- end
	-- d(string.format("found %d crux(es); search time %d ms", crux, GetGameTimeMilliseconds() - start))
	-- return crux
-- end

	---------------------------------
	---- Bound Armaments Tracker ----
	---------------------------------

-- function CombatMetronome:GetCurrentNumBAOnPlayer()
	-- local start = GetGameTimeMilliseconds()
	-- local bAStacks = 0
	-- for i=1,GetNumBuffs("player") do
		-- local _,_,_,_,stack,_,_,_,_,_,abilityId = GetUnitBuffInfo("player", i)
		-- if	abilityId == bAId.buff then
			-- bAStacks = stack
			-- d("You currently have "..tostring(bAStacks).." Stacks of Bound Armaments")
		-- break 
		-- end
	-- end
	-- return bAStacks
-- end

	-----------------------------
	---- Molten Whip Tracker ----
	-----------------------------

-- function CombatMetronome:GetCurrentNumMWOnPlayer()
	-- local start = GetGameTimeMilliseconds()
	-- local mWStacks = 0
	-- for i=1,GetNumBuffs("player") do
		-- local _,_,_,_,stack,_,_,_,_,_,abilityId = GetUnitBuffInfo("player", i)
		-- if	abilityId == mWId.buff then
			-- mWStacks = stack
			-- d("You currently have "..tostring(mWStacks).." Stacks of Molten Whip")
		-- break 
		-- end
	-- end
	-- return mWStacks
-- end

	----------------------------------------------------------------
	---- Grimm Focus/Merciless Resolve/Relentless Focus Tracker ----
	----------------------------------------------------------------
	
-- function CombatMetronome:CheckForGFMorph()
	-- local morph = ""
	-- local morphId = GetProgressionSkillCurrentMorphSlot(GetProgressionSkillProgressionId(1, 1, 6))
		-- if morphId == 0 then morph = "gF"
		-- elseif morphId == 1 then morph = "rF"
		-- elseif morphId == 2 then morph = "mR"
		-- end
	-- if morph ~= self.oldMorph and morph ~= "" then self.morphChanged = true end --self.stackTracker.indicator.ApplyIcon() end
	-- if morphChanged then d("How dare you change morphs midgame??") end
	-- self.oldMorph = morph
	-- return morph
-- end

-- function CombatMetronome:GetCurrentNumGFOnPlayer()
	-- local morph,_ = CombatMetronome:CheckForGFMorph()
	-- local gFStacks = 0
	-- for i=1,GetNumBuffs("player") do
		-- local _,_,_,_,stack,_,_,_,_,_,abilityId = GetUnitBuffInfo("player", i)
		-- if	abilityId == gFId[morph].buff then
			-- gFStacks = stack
			-- d("You currently have "..tostring(gFStacks).." Stacks of Grimm Focus")
		-- break 
		-- end
	-- end
	-- return gFStacks
-- end

	-----------------------------
	---- Necro skull Tracker ----
	-----------------------------
	
-- function CombatMetronome:CheckForFSMorph()
	-- local morph = ""
	-- local morphId = GetProgressionSkillCurrentMorphSlot(GetProgressionSkillProgressionId(1, 1, 2))
		-- if morphId == 0 then morph = "fS"
		-- elseif morphId == 1 then morph = "vS"
		-- elseif morphId == 2 then morph = "rS"
		-- end
	-- if morph ~= self.oldMorph and morph ~= "" then self.morphChanged = true end -- self.stackTracker.indicator.ApplyIcon() end
	-- self.oldMorph = morph
	-- return morph
-- end

-- function CombatMetronome:GetCurrentNumFSOnPlayer()
	-- local morph,_ = CombatMetronome:CheckForFSMorph()
	-- local fSStacks = 0
	-- for i=2,3 do
			-- ability = fSId[morph].ability[i]
			-- for j=1,12 do
				-- if self.actionSlotCache[j].id == ability then
					-- fSStacks = i-1
					-- break
				-- end
			-- end
		-- if fSStacks ~= 0 then break	end
		-- end
	-- return fSStacks
-- end

	------------------------------------
	---- Check if Tracker is active ----
	------------------------------------

function CombatMetronome:TrackerIsActive()
	local trackerIsActive = false
	if self.class == "ARC" and self.config.trackCrux then
		trackerIsActive = true
	elseif self.class == "DK" and self.config.trackMW then
		trackerIsActive = true
	elseif self.class == "SORC" and self.config.trackBA then
		trackerIsActive = true
	elseif self.class == "NB" and self.config.trackGF then
		trackerIsActive = true
	elseif self.class == "CRO" and self.config.trackFS then
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
		
function CombatMetronome:CheckIfSlotted()
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
	if not self.config.hideProgressbar then
		if self.config.hideCMInPVP and self.inPVPZone then
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
				self:BuildProgressBar()
				self:HideBar(not self.config.dontHide)
				-- d("registered cm scenario 3")
			else
				self:BuildProgressBar()
				self:HideBar(not self.config.dontHide)
				-- d("registered cm scenario 4")
			end
		end
	end
end

function CombatMetronome:ResourcesPVPSwitch()
	-- local hideResources = false
	if self.config.hideResourcesInPVP and self.inPVPZone then
		-- hideResources = true
		if self.rtRegistered then
			self:UnregisterResourceTracker()
			self.stamLabel:SetHidden(true)
            self.magLabel:SetHidden(true)
            self.hpLabel:SetHidden(true)    
            self.ultLabel:SetHidden(true)
		elseif not self.rtRegistered then
			self.stamLabel:SetHidden(true)
            self.magLabel:SetHidden(true)
            self.hpLabel:SetHidden(true)    
            self.ultLabel:SetHidden(true)
		end
	else
		if not self.rtRegistered then
			self:RegisterResourceTracker()
		end
		-- hideResources = false
	end
	-- return hideResources
end

function CombatMetronome:TrackerPVPSwitch()
	if self:TrackerIsActive() then
		if self.config.hideTrackerInPVP and self.inPVPZone then
			if self.trackerRegistered then
				self:UnregisterTracker()
				self.stackTracker.FadeScenes("NoUI")
				-- d("registered tracker scenario 1")
			elseif not self.trackerRegistered then
				self.stackTracker.FadeScenes("NoUi")
				-- d("registered tracker scenario 2")
			end
		else
			if not self.trackerRegistered then
				self:RegisterTracker()
				-- d("registered tracker scenario 3")
			end
		end
	end
end