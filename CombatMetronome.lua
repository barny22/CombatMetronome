-- local Util = DAL:Use("DariansUtilities", 6)
-- CombatMetronome = DAL:Def("CombatMetronome", 4, 1, {
--     onLoad = function(self) self:Init() end,
-- })

CombatMetronome = {
    name = "CombatMetronome",
    major = 6,
    minor = 5,
    version = "1.6.5"
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

	------------------------
	---- Sample Section ----
	------------------------

	if self.showSampleBar then
		self.bar.segments[2].progress = 0.7
		self.bar.backgroundTexture:SetWidth(0.7*self.config.width)
		if self.config.dontShowPing then
			self.bar.segments[1].progress = 0
		else
			self.bar.segments[1].progress = 0.071
		end
		if self.config.showSpell then
			self.spellLabel:SetText("Generic sample text")
			self.spellLabel:SetHidden(false)
			self.spellIcon:SetTexture("/esoui/art/icons/ability_dualwield_002_b.dds")
			self.spellIcon:SetHidden(false)
			self.spellIconBorder:SetHidden(false)
		else
			self.spellLabel:SetHidden(true)
			self.spellIcon:SetHidden(true)
			self.spellIconBorder:SetHidden(true)
		end
		if self.config.showTimeRemaining then
			self.timeLabel:SetText("7.8s")
			self.timeLabel:SetHidden(false)
		else
			self.timeLabel:SetHidden(true)
		end
		if self.config.changeOnChanneled then
			self.bar.segments[2].color = self.config.channelColor
		else
			self.bar.segments[2].color = self.config.progressColor
		end
		self.bar:Update()
	else
	
	-------------------------
	---- Actual Updating ----
	-------------------------

		if self.config.dontShowPing then
			latency = 0
		else
			latency = math.min(GetLatency(), self.config.maxLatency)
		end
		
		local time = GetFrameTimeMilliseconds()
		
		local dodgeTrigger = CombatMetronome:CheckForDodge()
		
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
					local uiVolume = GetSetting(SETTING_TYPE_AUDIO, AUDIO_SETTING_UI_VOLUME)
					local tockQueue = ZO_QueuedSoundPlayer:New(0)
					tockQueue:SetFinishedAllSoundsCallback(function()
						SetSetting(SETTING_TYPE_AUDIO, AUDIO_SETTING_UI_VOLUME, uiVolume)
					end)
					SetSetting(SETTING_TYPE_AUDIO, AUDIO_SETTING_UI_VOLUME, self.config.tickVolume)
					tockQueue:PlaySound(self.config.soundTockEffect, 250)
				end

				if not self.soundTickPlayed and self.config.soundTickEnabled and time > start + length - self.config.soundTickOffset then
					self.soundTickPlayed = true
					local uiVolume = GetSetting(SETTING_TYPE_AUDIO, AUDIO_SETTING_UI_VOLUME)
					local tickQueue = ZO_QueuedSoundPlayer:New(0)
					tickQueue:SetFinishedAllSoundsCallback(function()
						SetSetting(SETTING_TYPE_AUDIO, AUDIO_SETTING_UI_VOLUME, uiVolume)
						-- d("Sound is finished playing. Volume adjusted. Volume is now "..GetSetting(SETTING_TYPE_AUDIO, AUDIO_SETTING_UI_VOLUME))
					end)
					SetSetting(SETTING_TYPE_AUDIO, AUDIO_SETTING_UI_VOLUME, self.config.tickVolume)
					tickQueue:PlaySound(self.config.soundTickEffect, 250)
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
			if (playerDidBlock or playerDidDodge or self.barswap) and duration > 1000+latency then
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
		-- if self.barswap then
			-- d("barswap reset")
		-- end
		self.barswap = false
	end
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
    self.progressbar = CombatMetronome:BuildProgressBar()
    CombatMetronome:BuildMenu()

    self.lastInterval = 0
	self.actionSlotCache = CombatMetronome:StoreAbilitiesOnActionBar()

	self:RegisterMetadata()
	
	Util.Ability.Tracker.CombatMetronome = self
    Util.Ability.Tracker:Start()
	
	----------------------------------
	---- Initialize Stack Tracker ----
	----------------------------------
	
	if CM_TRACKER_CLASS_ATTRIBUTES[self.class] then
		self.stackTracker = CombatMetronome:BuildStackTracker()
		self.stackTracker.indicator.ApplyDistance(self.config.indicatorSize/5, self.config.indicatorSize)
		self.stackTracker.indicator.ApplySize(self.config.indicatorSize)
		self.stackTracker.indicator.ApplyIcon()
	
		self:RegisterTracker()
		self.showSampleTracker = false
	end	
end

-- LOAD HOOK

-- EVENT_MANAGER:RegisterForEvent(CombatMetronome.name.."Load", EVENT_ADD_ON_LOADED, function(...)
--     if (CombatMetronome.loaded) then return end
--     CombatMetronome.loaded = true

--     CombatMetronome:Init()
-- end)

	-----------------------------
	---- Register/Unregister ----
	-----------------------------

function CombatMetronome:RegisterMetadata()
	EVENT_MANAGER:RegisterForUpdate(
        self.name.."CurrentActionslotsOnHotbar",
        1000 / 60,
        function()
			self.actionSlotCache = CombatMetronome:StoreAbilitiesOnActionBar()
			-- self.menu.abilityAdjustChoices = CombatMetronome:BuildListForAbilityAdjusts()
        end
    )
	
	EVENT_MANAGER:RegisterForEvent(
		self.name.."CharacterLoaded",
		EVENT_PLAYER_ACTIVATED,
		function(_,_)
			self.inPVPZone = self:IsInPvPZone()
			self:CMPVPSwitch()
			self:TrackerPVPSwitch()
			self:ResourcesPVPSwitch()
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
end

function CombatMetronome:RegisterCM()
	EVENT_MANAGER:RegisterForUpdate(
        self.name.."Update",
        1000 / 60,
        function(...) self:Update() end
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
	self.cmRegistered = true
	
	EVENT_MANAGER:RegisterForEvent(
		self.name.."BarSwap",
		EVENT_ACTION_SLOTS_ACTIVE_HOTBAR_UPDATED,
		function(_,barswap,_,category)
			if barswap then
				self.barswap = barswap
				-- d("barswap occured. Hotbar was "..category)
			end
			return self.barswap
		end
	)
	-- d("cm is registered")
end

function CombatMetronome:RegisterResourceTracker()
    EVENT_MANAGER:RegisterForUpdate(
        self.name.."UpdateLabels",
        1000 / 60,
        function(...) self:UpdateLabels() end
    )
	
	self.rtRegistered = true
end

function CombatMetronome:RegisterTracker()
	EVENT_MANAGER:RegisterForUpdate(
		self.name.."UpdateStacks",
		1000 / 60,
		function(...) CombatMetronome:TrackerUpdate() end
	)
	self.trackerRegistered = true
	-- d("tracker is registered")
end

function CombatMetronome:UnregisterCM()
	EVENT_MANAGER:UnregisterForUpdate(
        self.name.."Update")
	
	-- EVENT_MANAGER:UnregisterForUpdate(
        -- self.name.."CurrentActionslotsOnHotbar")
		
	-- EVENT_MANAGER:UnregisterForEvent(
		-- self.name.."CharacterLoaded")
	
	EVENT_MANAGER:UnregisterForEvent(
        self.name.."SlotUsed")
	
	self.cmRegistered = false
	-- d("cm is unregistered")
	-- self.cmWarning = false
end

function CombatMetronome:UnregisterResourceTracker()
	EVENT_MANAGER:UnregisterForUpdate(
        self.name.."UpdateLabels")
		
	self.rtRegistered = false
end

function CombatMetronome:UnregisterTracker()
	EVENT_MANAGER:UnregisterForUpdate(
		self.name.."UpdateStacks")
	
	self.trackerRegistered = false
	-- d("tracker is unregistered")
	self.trackerWarning = false
end