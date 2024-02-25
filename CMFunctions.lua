local LAM = LibAddonMenu2
local Util = DariansUtilities

-- IDs for easier access
local cruxId = 184220
local carverId1 = 183122
local carverId2 = 193397
local dodgeId = 29721
local bAId = { ["buff"] = 203447, ["ability"] = 24165,}
local mWId = { ["buff"] = 122658, ["ability"] = "",} -- 122729
local gFId = {
	["gF"] = { ["buff"] = 122585, ["ability"] = 61902,},
	["mR"] = { ["buff"] = 122586, ["ability"] = 61919,},
	["rF"] = { ["buff"] = 122587, ["ability"] = 61927,},
	}
local previousStack = 0

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

function CombatMetronome:CropZOSSpellName(zosString)
    local _, zosSpellDivider = string.find(zosString, "%^")
    
    if zosSpellDivider then
        return string.sub(zosString, 1, zosSpellDivider - 1)
    else
        return zosString
    end
end

	-----------------------
	---- Dodge Checker ----
	-----------------------

function CombatMetronome:CheckForDodge()
	local dodge = false
	for i=1,GetNumBuffs("player") do
		local _,startTime,endTime,_,_,_,_,_,_,_,abilityId = GetUnitBuffInfo("player", i)
		if abilityId == dodgeId then
			buffTimer = endTime - math.floor(GetGameTimeMilliseconds()/1000)
			buffLength = endTime - startTime
			--d(tostring(buffTimer))
			if buffTimer > 3 and buffLength == 3 then
			dodge = true
			--d("dodge detected")
			end
		break
		end
	end
	return dodge
end

	-----------------------
	---- Combat Events ----
	-----------------------

function CombatMetronome:HandleCombatEvents(...)
    local e = Util.CombatEvent:New(...)

    if e:IsPlayerTarget() and not e:IsError() then
        local r = e:GetResult()
        if r == ACTION_RESULT_KNOCKBACK
        or r == ACTION_RESULT_PACIFIED
        or r == ACTION_RESULT_STAGGERED
        or r == ACTION_RESULT_STUNNED
        or r == ACTION_RESULT_INTERRUPTED then
            self.currentEvent = nil
            return
        end
    end
end

	-------------------------
	---- Ability Adjusts ----
	-------------------------

function CombatMetronome:UpdateAdjustChoices()
    local names = self.menu.abilityAdjustChoices

    for k in pairs(names) do names[k] = nil end

    for id, adj in pairs(self.config.abilityAdjusts) do
        local name = GetAbilityName(id)
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

function CombatMetronome:BuildListForAbilityAdjusts()
	local list = {}
	local listVariables = CombatMetronome:StoreAbilitiesOnActionBar()
	table.insert(list, "----FRONTBAR----")
	for i=1,5 do
		local abilitiyString = tostring(i..": "..listVariables[i].id..", "..listVariables[i].name)
		table.insert(list, abilityString)
	end
	-- for i=6,6 do
		-- local abilitiyString = tostring("Ultimate: "..listVariables[i].id..", "..listVariables[i].name)
		table.insert(list, tostring("Ultimate: "..listVariables[6].id..", "..listVariables[6].name))
	-- end
	table.insert(list, "----BACKBAR----")
	for i=7,11 do
		local abilitiyString = tostring((i-6)..": "..listVariables[i].id..", "..listVariables[i].name)
		table.insert(list, abilityString)
	end
	-- for i=12,12 do
		-- local abilitiyString = tostring("Ultimate: "..listVariables[i].id..", "..listVariables[i].name)
		table.insert(list, tostring("Ultimate: "..listVariables[12].id..", "..listVariables[12].name))
	-- end
	return list
end
	-------------------------
	---- Ability Handler ----
	-------------------------

function CombatMetronome:HandleAbilityUsed(event)
    if not (self.inCombat or self.config.showOOC) then return end

    self.soundTickPlayed = false
    self.soundTockPlayed = false

    local ability = event.ability

    event.adjust = (self.config.abilityAdjusts[ability.id] or 0)
                    + ((ability.instant and self.config.gcdAdjust)
                    or (ability.heavy and self.config.globalHeavyAdjust)
                    or self.config.globalAbilityAdjust)
	
	-- d(event.ability.id)						--gives 183122 for Fatecarver
	if	event.ability.id == carverId1 or event.ability.id == carverId2 then
		local cruxes = CombatMetronome:GetCurrentNumCruxOnPlayer()
		event.adjust = event.adjust + (338 * cruxes)
		-- d(string.format("Fatecarver duration succesfully adjusted with %d crux(es)", cruxes))
	end
	if self.config.stopHATracking and event.ability.type == 6 then
		self.currentEvent = nil
	else
		self.currentEvent = event
	end
    self.gcd = Util.Ability.Tracker.gcd
end

	-----------------------
	---- Crux Tracking ----
	-----------------------

function CombatMetronome:GetCurrentNumCruxOnPlayer()					-- Crux Tracking by barny (special thanks to akasha who basically did all the work)
	--local start = GetGameTimeMilliseconds()
	local crux = 0
	if self.class == "ARC" then
		for i=1,GetNumBuffs("player") do
			local _,_,_,_,stack,_,_,_,_,_,abilityId = GetUnitBuffInfo("player", i)
			if	abilityId == cruxId then
				crux = stack
				-- d("You currently have "..tostring(crux).." Crux")
			break 
			end
		end
	end
	-- d(string.format("found %d crux(es); search time %d ms", crux, GetGameTimeMilliseconds() - start))
	return crux
end

	---------------------------------
	---- Bound Armaments Tracker ----
	---------------------------------

function CombatMetronome:GetCurrentNumBAOnPlayer()
	--local start = GetGameTimeMilliseconds()
	local bAStacks = 0
	for i=1,GetNumBuffs("player") do
		local _,_,_,_,stack,_,_,_,_,_,abilityId = GetUnitBuffInfo("player", i)
		if	abilityId == bAId.buff then
			bAStacks = stack
			-- d("You currently have "..tostring(bAStacks).." Stacks of Bound Armaments")
		break 
		end
	end
	return bAStacks
end

	-----------------------------
	---- Molten Whip Tracker ----
	-----------------------------

function CombatMetronome:GetCurrentNumMWOnPlayer()
	--local start = GetGameTimeMilliseconds()
	local mWStacks = 0
	for i=1,GetNumBuffs("player") do
		local _,_,_,_,stack,_,_,_,_,_,abilityId = GetUnitBuffInfo("player", i)
		if	abilityId == mWId.buff then
			mWStacks = stack
			-- d("You currently have "..tostring(mWStacks).." Stacks of Molten Whip")
		break 
		end
	end
	return mWStacks
end

	----------------------------------------------------------------
	---- Grimm Focus/Merciless Resolve/Relentless Focus Tracker ----
	----------------------------------------------------------------
function CombatMetronome:CheckForGFMorph()
	local morph = ""
	local morphId = GetProgressionSkillCurrentMorphSlot(GetProgressionSkillProgressionId(1, 1, 6))
		if morphId == 0 then morph = "gF"
		elseif morphId == 1 then morph = "rF"
		elseif morphId == 2 then morph = "mR"
		end
	return morph
end

function CombatMetronome:GetCurrentNumGFOnPlayer()
	local morph = CombatMetronome:CheckForGFMorph()
	local gFStacks = 0
	for i=1,GetNumBuffs("player") do
		local _,_,_,_,stack,_,_,_,_,_,abilityId = GetUnitBuffInfo("player", i)
		if	abilityId == gFId[morph].buff then
			gFStacks = stack
			-- d("You currently have "..tostring(gFStacks).." Stacks of Grimm Focus")
		break 
		end
	end
	return gFStacks
end

-- function CombatMetronome:GetCurrentNumGFOnPlayer()
	-- local start = GetGameTimeMilliseconds()
	-- local gFStacks = 0
	-- local mRStacks = 0
	-- local rFStacks = 0
	-- local maxStacks = 0
	-- local icon = "gF"
	-- for i=1,GetNumBuffs("player") do
		-- local _,_,_,_,stack,_,_,_,_,_,abilityId = GetUnitBuffInfo("player", i)
		-- if	abilityId == gFId then															--61902
			-- gFStacks = stack
			-- d("You currently have "..tostring(gFStacks).." Stacks of Grimm Focus")
		-- break 
		-- end
	-- end
	-- for i=1,GetNumBuffs("player") do
		-- local _,_,_,_,stack,_,_,_,_,_,abilityId = GetUnitBuffInfo("player", i)
		-- if	abilityId == mRId then															-- 61919
			-- mRStacks = stack
			-- d("You currently have "..tostring(mRStacks).." Stacks of Merciless Resolve")
		-- break 
		-- end
	-- end
	-- for i=1,GetNumBuffs("player") do
		-- local _,_,_,_,stack,_,_,_,_,_,abilityId = GetUnitBuffInfo("player", i)
		-- if	abilityId == rFId then															--61927
			-- rFStacks = stack
			-- d("You currently have "..tostring(rFStacks).." Stacks of Relentless Focus")
		-- break 
	-- end
	-- end
	-- if gFStacks > 0 and gFStacks > maxStacks then
        -- maxStacks = gFStacks
		-- icon = "gF"
    -- end
    -- if mRStacks > 0 and mRStacks > maxStacks then
        -- maxStacks = mRStacks
		-- icon = "mR"
    -- end
    -- if rFStacks > 0 and rFStacks > maxStacks then
        -- maxStacks = rFStacks
		-- icon = "rF"
    -- end
	-- return maxStacks, icon
-- end

		---------------------------------------
        ---- Store abilities on Actionbars ----
        ---------------------------------------

function CombatMetronome:StoreAbilitiesOnActionBar()
    local actionSlots = {}  -- Create a table to store action slots

    for j = 0, 1 do
        for i = 3, 8 do
            local actionSlot = {}  -- Create a new table for each action slot
            -- setmetatable(actionSlot, {__index = index})
            
            actionSlot.place = tostring(i .. j)
            actionSlot.id = GetSlotBoundId(i, j)
            actionSlot.icon = GetAbilityIcon(actionSlot.id)
            actionSlot.name = self:CropZOSSpellName(GetAbilityName(actionSlot.id))

            table.insert(actionSlots, actionSlot)  -- Add the current action slot to the table
        end
    end

    return actionSlots
end

		------------------------------------------------
        ---- Tracker check if abilities are slotted ----
        ------------------------------------------------
		
function CombatMetronome:CheckIfSlotted()
	local morph = self:CheckForGFMorph()
	local ability = ""
	local abilitySlotted = false
		if self.class == "SOR" then ability = bAId.ability
		elseif self.class == "NB" then ability = gFId[morph].ability
		elseif self.class == "DK" then ability = mWId.ability
		end
	for i=1,12 do
		if self.actionSlotCache[i].id == ability then
			abilitySlotted = true
			break
		end
	end
	return abilitySlotted
end

        -------------------------------
        ---- Stack Tracker Updater ----
        -------------------------------

function CombatMetronome:TrackerUpdate()
	local trackerShouldBeVisible = false
	if self.class == "ARC" and self.config.trackCrux then
		trackerShouldBeVisible = true
	elseif self.class == "DK" and self.config.trackMW then
		trackerShouldBeVisible = true
	elseif self.class == "SOR" and self.config.trackBA then
		trackerShouldBeVisible = true
	elseif self.class == "NB" and self.config.trackGF then
		trackerShouldBeVisible = true
	elseif self.config.trackerIsUnlocked then
		trackerShouldBeVisible = true
	else
		trackerShouldBeVisible = false
	end
	
	if trackerShouldBeVisible then
		local abilitySlotted = CombatMetronome:CheckIfSlotted()
		if abilitySlotted or self.class == "ARC" then
			self.stackTracker.showTracker(true)
			local attributes = CM_TRACKER_CLASS_ATTRIBUTES[self.class]
			if self.class == "ARC" then
					stacks = self:GetCurrentNumCruxOnPlayer()
			elseif self.class == "DK" then
					stacks = self:GetCurrentNumMWOnPlayer()
			elseif self.class == "SOR" then
					stacks = self:GetCurrentNumBAOnPlayer()
			elseif self.class == "NB" then
					stacks = self:GetCurrentNumGFOnPlayer()
			end
			for i=1,attributes.iMax do 
					self.stackTracker.indicator[i].Deactivate()
			end
			if stacks == 0 then return end
			for i=1,stacks do
					self.stackTracker.indicator[i].Activate()
			end
			-- if self.config.hightlightOnFullStacks then
				-- if previousStack == (attributes.iMax-1) then
					-- if stacks == attributes.iMax then
						
					-- end
				-- end
			-- end
			if self.config.trackerPlaySound then												--Sound cue when stacks are full
				if previousStack == (attributes.iMax-1) then
					if stacks == attributes.iMax then
						PlaySound(SOUNDS[self.config.trackerSound])
						-- d("Stacks are full")
					end
				end
			end
			previousStack = stacks
		else
			self.stackTracker.showTracker(false)
		end
	else
		self.stackTracker.showTracker(false)
	end
end
