-- local Util = DAL:Use("DariansUtilities", 6)
-- CombatMetronome = DAL:Def("CombatMetronome", 4, 1, {
--     onLoad = function(self) self:Init() end,
-- })

CombatMetronome = {
    name = "CombatMetronome",
    major = 6,
    minor = 4,
    version = "1.6.4"
}

local LAM = LibAddonMenu2
local Util = DariansUtilities

Util.onLoad(CombatMetronome, function(self) self:Init() end)

local INTERVAL = 200

ZO_CreateStringId("SI_BINDING_NAME_COMBATMETRONOME_FORCE", "Force display")

	-------------------------
	---- Update Cast Bar ----
	-------------------------

function CombatMetronome:Update()
	
	if self.config.dontShowPing then
		latency = 0
	else
		latency = math.min(GetLatency(), self.config.maxLatency)
	end
	
    local time = GetFrameTimeMilliseconds()
	
	local dodgeTrigger = self:CheckForDodge()
	local currentHotbar = GetActiveHotbarCategory()
	
	-- this is important for GCD Tracking
	local gcdTrigger = false
	local slotRemaining, slotDuration, _, _ = GetSlotCooldownInfo(3)
	local sR, sD, _, _ = GetSlotCooldownInfo(4)
	if (sR > slotRemaining) or ( sD > slotDuration ) then
		slotRemaining = sR
		slotDuration = sD
	end
	if slotDuration < 1 then
		slotDuration = 1
	end
	if slotRemaining/slotDuration > 0.97 then
		gcdTrigger = true
	end
	local gcdProgress = slotRemaining/slotDuration
	
	--if gcdTrigger then d("gcd was triggered") end
	--if dodgeTrigger then d("dodge was triggered") end
	
	local playerDidDodge = dodgeTrigger and gcdTrigger

    local interval = false
    if time > self.lastInterval + INTERVAL then
        self.lastInterval = time
        interval = true
    end
		---------------------
		---- GCD Tracker ----
		---------------------
    if self.config.trackGCD and not self.currentEvent then
        self.bar.segments[1].progress = 0
		self.bar.segments[2].progress = gcdProgress
		
		if gcdProgress == 0 then
			self:OnCDStop()
		else
			self:HideBar(false)
			self.bar.backgroundTexture:SetWidth(gcdProgress*self.config.width)
		end
        self.bar:Update()
	elseif self.currentEvent then
        local ability = self.currentEvent.ability
        local start = self.currentEvent.start
		if time - start < 0 then
			cdTimer = 0
		else
			cdTimer = time - start
		end
		
        local duration = math.max(ability.heavy and 0 or (self.gcd or 1000), ability.delay) + self.currentEvent.adjust
		local channelTime = ability.delay + self.currentEvent.adjust
		local timeRemaining = ((start + channelTime + GetLatency()) - time) / 1000
		local playerDidDodge = CombatMetronome:CheckForDodge()
		local playerDidBlock = IsBlockActive()
		
		if ability.heavy then
			if self.config.displayPingOnHeavy then
				duration = duration + latency
			else
				latency = 0
			end
		end
		----------------------
		---- Progress Bar ----
		----------------------
        if time > start + duration then
			self:OnCDStop()
        else
            -- Sound contributed to by Seltiix --

            local length = duration - latency

            if not self.soundTockPlayed and self.config.soundTockEnabled and time > start + (length / 2) - self.config.soundTockOffset then
                self.soundTockPlayed = true
                PlaySound(self.config.soundTockEffect)
            end

            if not self.soundTickPlayed and self.config.soundTickEnabled and time > start + length - self.config.soundTickOffset then
                self.soundTickPlayed = true
                PlaySound(self.config.soundTickEffect)
            end
		------------------------------------------------
		---- Switching Color on channeled abilities ----
		------------------------------------------------
			if self.config.changeOnChanneled then
				if not ability.instant and ability.delay <= 1000 then
					-- d("Ability with cast time < 1s detected")
					if timeRemaining >= 0 then
						if self.bar.segments[2].color == self.config.progressColor then
							self.bar.segments[2].color = self.config.channelColor
							-- d("Trying to update Channel Color")
						end
					elseif timeRemaining <= 0 then
						if self.bar.segments[2].color == self.config.channelColor then
							self.bar.segments[2].color = self.config.progressColor
							-- d("Turning back to Progress Color")
						end
					end
				else
					if self.bar.segments[2].color == self.config.channelColor then
						self.bar.segments[2].color = self.config.progressColor
					end
				end
			end
			
			self.bar.segments[2].progress = 1 - (cdTimer/duration)
			self.bar.segments[1].progress = latency / duration
			if cdTimer >= (duration+latency) then
				self:OnCDStop()
			else
				self:HideBar(false)
				self.bar.backgroundTexture:SetWidth((1 - (cdTimer/duration))*self.config.width)
			end
			self.bar:Update()
		end
		------------------------------
		---- Spell Label and Icon ----					--Spell Label on Castbar by barny
		------------------------------
		if self.config.showSpell and ability.delay > 0 and timeRemaining >= 0 and not ability.heavy then
			local spellName = self:CropZOSSpellName(ability.name)
			self.spellLabel:SetText(spellName)
			self.spellLabel:SetHidden(false)
		--Spell Icon next to Castbar
			self.spellIcon:SetTexture(ability.icon)
			self.spellIcon:SetHidden(false)
			self.spellIconBorder:SetHidden(false)
		else
			self.spellLabel:SetHidden(true)
			self.spellIcon:SetHidden(true)
			self.spellIconBorder:SetHidden(true)
		end
			
		--Remaining time on Castbar by barny
		if self.config.showTimeRemaining and ability.delay > 0 and timeRemaining >= 0 and not ability.heavy then
			self.timeLabel:SetText(string.format("%.1fs", timeRemaining))
			self.timeLabel:SetHidden(false)
		else
			self.timeLabel:SetHidden(true)
		end
		--------------------
		---- Interrupts ----							-- check for interrupts by dodge, barswap or block
		--------------------
		if (playerDidBlock or playerDidDodge or oldHotbar ~= currentHotbar) and duration > 1000+latency then
			self:OnCDStop()
			self.bar:Update()
		elseif playerDidDodge and trackGCD then
			self:HideLabels(true)
			self.bar.segments[1].progress = 0
			self.bar.segments[2].progress = gcdProgress
			if gcdProgress == 0 then
				self:OnCDStop()
			else
				self:HideBar(false)
				self.bar.backgroundTexture:SetWidth(gcdProgress*self.config.width)
			end
			self.bar:Update()
		end
	else
		self:OnCDStop()
		self.bar:Update()
    end
	oldHotbar = GetActiveHotbarCategory()
end

	-------------------------------------
	---- Initialize Combat Metronome ----
	-------------------------------------

function CombatMetronome:Init()
    self.config = ZO_SavedVars:NewCharacterIdSettings("CombatMetronomeSavedVars", 1, nil, CM_DEFAULT_SAVED_VARS)
    if self.config.global then
        self.config = ZO_SavedVars:NewAccountWide("CombatMetronomeSavedVars", 1, nil, CM_DEFAULT_SAVED_VARS)
        self.config.global = true
    end
	
	self.classId = GetUnitClassId("player")
	self.class = CM_CLASS[self.classId]

    self.log = self.config.debug

    self.inCombat = IsUnitInCombat("player")
    self.currentEvent = nil

    self.gcd = 1000

    self.unlocked = false
    CombatMetronome:BuildUI()
    CombatMetronome:BuildMenu()
	-- CombatMetronome:CheckIfStackTrackerShouldLoad()

    self.lastInterval = 0
	self.actionSlotCache = CombatMetronome:StoreAbilitiesOnActionBar()

    EVENT_MANAGER:RegisterForUpdate(
        self.name.."Update",
        1000 / 60,
        function(...) self:Update() end
    )

    EVENT_MANAGER:RegisterForUpdate(
        self.name.."UpdateLabels",
        1000 / 60,
        function(...) self:UpdateLabels() end
    )
	
	EVENT_MANAGER:RegisterForUpdate(
        self.name.."CurrentActionslotsOnHotbar",
        1000 / 60,
        function()
			self.actionSlotCache = CombatMetronome:StoreAbilitiesOnActionBar()
			-- self.menu.abilityAdjustChoices = CombatMetronome:BuildListForAbilityAdjusts()
        end
    )

    EVENT_MANAGER:RegisterForEvent(
        self.name.."CombatStateChange",
        EVENT_PLAYER_COMBAT_STATE,
        function(_, inCombat) 
            self.inCombat = inCombat == true
            -- self.stamGradient:Reset()
        end
    )
    
    EVENT_MANAGER:RegisterForEvent(
        self.name.."SlotUsed",
        EVENT_ACTION_SLOT_ABILITY_USED,
        function(e, slot)
            local ability = Util.Ability:ForId(GetSlotBoundId(slot))
            -- log("Abilty used - ", ability.name)
            if (ability and ability.heavy) then
                -- log("Cancelling heavy")
                self.currentEvent = nil
            end
        end
    )
	
	Util.Ability.Tracker.CombatMetronome = self
    Util.Ability.Tracker:Start()
	
	----------------------------------
	---- Initialize Stack Tracker ----
	----------------------------------
	if CM_TRACKER_CLASS_ATTRIBUTES[self.class] then
		self.stackTracker = CombatMetronome:BuildStackTracker()
		self.stackTracker.indicator.ApplySize(self.config.indicatorSize)
		self.stackTracker.indicator.ApplyDistance(self.config.indicatorSize/5, self.config.indicatorSize)
	
		EVENT_MANAGER:RegisterForUpdate(
			self.name.."UpdateStacks",
			1000 / 60,
			function(...) CombatMetronome:TrackerUpdate() end
		)
	end
end

-- LOAD HOOK

-- EVENT_MANAGER:RegisterForEvent(CombatMetronome.name.."Load", EVENT_ADD_ON_LOADED, function(...)
--     if (CombatMetronome.loaded) then return end
--     CombatMetronome.loaded = true

--     CombatMetronome:Init()
-- end)

	--------------------------------------
	---- Check for stack tracker load ----
	--------------------------------------

-- function CombatMetronome:CheckIfStackTrackerShouldBeVisible()
		-- if self.class == "ARC" and self.config.trackCrux then
			-- CombatMetronome:InitializeTracker()
		-- elseif self.class == "DK" and self.config.trackMW then
			-- CombatMetronome:InitializeTracker()
		-- elseif self.class == "SOR" and self.config.trackBA then
			-- CombatMetronome:InitializeTracker()
		-- elseif self.class == "NB" and self.config.trackGF then
			-- CombatMetronome:InitializeTracker()
		-- end
-- end