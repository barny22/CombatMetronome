local LAM = LibAddonMenu2
local Util = DariansUtilities

-- IDs for easier access
local cruxId = 184220
local carverId1 = 183122
local carverId2 = 193397
local dodgeId = 29721
local bAId = 203447

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
	self.bar.backgroundTexture:SetHidden( value)
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
	---- Crux Tracking ----
	-----------------------

function CombatMetronome:GetCurrentNumCruxOnPlayer()					-- Crux Tracking by barny (special thanks to akasha who basically did all the work)
	--local start = GetGameTimeMilliseconds()
	local crux = 0
	for i=1,GetNumBuffs("player") do
		local _,_,_,_,stack,_,_,_,_,_,abilityId = GetUnitBuffInfo("player", i)
		if	abilityId == cruxId then
			crux = stack
			-- d("You currently have "..tostring(crux).." Crux")
		break 
		end
	end
	-- d(string.format("found %d crux(es); search time %d ms", crux, GetGameTimeMilliseconds() - start))
	return crux
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

	---------------------------------
	---- Bound Armaments Tracker ----
	---------------------------------

function CombatMetronome:GetCurrentNumBAOnPlayer()
	--local start = GetGameTimeMilliseconds()
	local bAStacks = 0
	for i=1,GetNumBuffs("player") do
		local _,_,_,_,stack,_,_,_,_,_,abilityId = GetUnitBuffInfo("player", i)
		if	abilityId == bAId then
			bAStacks = stack
			-- d("You currently have "..tostring(bAStacks).." Stacks of Bound Armaments")
		break 
		end
	end
	return bAStacks
end