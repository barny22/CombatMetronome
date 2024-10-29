local Util = DariansUtilities
Util.Stacks = Util.Stacks or {}
CombatMetronome.StackTracker = CombatMetronome.StackTracker or {}
local StackTracker = CombatMetronome.StackTracker
local CM = CombatMetronome

	-------------------------------
	---- Stack Tracker Updater ----
	-------------------------------

local animStart = false
local trackerShouldBeVisible = false
local sampleAnimationStarted = false
local stacks, previousStack

function StackTracker:Update()

    ------------------------
	---- Sample Section ----
	------------------------
	
	if self.showSampleTracker then
		local attributes = self.CLASS_ATTRIBUTES[self.class]
		for i = 1, attributes.iMax-1 do
			self.UI.indicator[i].Activate()
		end
		if CombatMetronome.SV.StackTracker.hightlightOnFullStacks and not sampleAnimationStarted then
			for i = 1, attributes.iMax do
				self.UI.indicator[i].Animate()
			end
			sampleAnimationStarted = true
		elseif not CombatMetronome.SV.StackTracker.hightlightOnFullStacks then
			for i = 1, attributes.iMax do
				self.UI.indicator[i].StopAnimation()
			end
			sampleAnimationStarted = false
		end
	elseif not self.showSampleTracker and sampleAnimationStarted then
		local attributes = self.CLASS_ATTRIBUTES[self.class]
		for i = 1, attributes.iMax do
			self.UI.indicator[i].StopAnimation()
		end
		sampleAnimationStarted = false
		
	-------------------------
	---- Actual Updating ----
	-------------------------
	
	else
		if self:TrackerIsActive() then
			trackerShouldBeVisible = true
		elseif CombatMetronome.SV.StackTracker.isUnlocked then
			trackerShouldBeVisible = true
		else
			trackerShouldBeVisible = false
		end
		
		if trackerShouldBeVisible then
			local abilitySlotted = self:CheckIfSlotted()
			if Util.Stacks.morphChanged then
				self.UI.indicator.ApplyIcon()
				Util.Stacks.morphChanged = false
			end
			if abilitySlotted then
				self.UI.FadeScenes("UI")
				local attributes = self.CLASS_ATTRIBUTES[self.class]
				local oneOff = attributes.iMax - 1
				if self.class == "ARC" then
						stacks = Util.Stacks:GetCurrentNumCruxOnPlayer()
				elseif self.class == "DK" then
						stacks = Util.Stacks:GetCurrentNumMWOnPlayer()
				elseif self.class == "SORC" then
						stacks = Util.Stacks:GetCurrentNumBAOnPlayer()
				elseif self.class == "NB" then
						stacks = Util.Stacks:GetCurrentNumGFOnPlayer()
				elseif self.class == "CRO" then
						stacks = Util.Stacks:GetCurrentNumFSOnPlayer()
				end
				for i=1,attributes.iMax do 
					self.UI.indicator[i].Deactivate()
				end
				-- if stacks == 0 then return end
				for i=1,stacks do
					self.UI.indicator[i].Activate()
				end
				if CombatMetronome.SV.StackTracker.hightlightOnFullStacks then											--Animation when stacks are full
					if stacks == attributes.iMax and animStart == false then
						for i=1,attributes.iMax do
							self.UI.indicator[i].Animate()
						end
						animStart = true
					end
					if animStart == true and stacks ~= attributes.iMax then
						for i=1,attributes.iMax do
							self.UI.indicator[i].StopAnimation()
						end
						animStart = false
					end
				end
				if CombatMetronome.SV.StackTracker.playSound then
					local uiVolume = GetSetting(SETTING_TYPE_AUDIO, AUDIO_SETTING_UI_VOLUME)											--Sound cue when stacks are full
					if previousStack == oneOff then
						--if self.SV.debug.enabled then CombatMetronome.debug:Print("One off full stacks") end
						if stacks == attributes.iMax then
							local trackerCue = ZO_QueuedSoundPlayer:New(0)
							trackerCue:SetFinishedAllSoundsCallback(function()
								SetSetting(SETTING_TYPE_AUDIO, AUDIO_SETTING_UI_VOLUME, uiVolume)
								--if self.SV.debug.enabled then CombatMetronome.debug:Print("Sound is finished playing. Volume adjusted. Volume is now "..GetSetting(SETTING_TYPE_AUDIO, AUDIO_SETTING_UI_VOLUME)) end
							end)
							SetSetting(SETTING_TYPE_AUDIO, AUDIO_SETTING_UI_VOLUME, CombatMetronome.SV.StackTracker.volume)
							--if self.SV.debug.enabled then CombatMetronome.debug:Print("Volume adjusted. Volume is now "..GetSetting(SETTING_TYPE_AUDIO, AUDIO_SETTING_UI_VOLUME)) end
							trackerCue:PlaySound(SOUNDS[CombatMetronome.SV.StackTracker.sound],250)
							--if self.SV.debug.enabled then CombatMetronome.debug:Print("Stacks are full") end
						end
					end
				end
				previousStack = stacks
			else
				self.UI.FadeScenes("NoUI")
			end
		else
			self.UI.FadeScenes("NoUI")
		end
	end
end