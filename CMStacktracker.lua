        -------------------------------
        ---- Stack Tracker Updater ----
        -------------------------------

local animStart = false
local trackerShouldBeVisible = false
local sampleAnimationStarted = false

function CombatMetronome:TrackerUpdate()

    ------------------------
	---- Sample Section ----
	------------------------
	
	if self.showSampleTracker then
		local attributes = CM_TRACKER_CLASS_ATTRIBUTES[self.class]
		for i = 1, attributes.iMax-1 do
			self.stackTracker.indicator[i].Activate()
		end
		if self.config.hightlightOnFullStacks and not sampleAnimationStarted then
			for i = 1, attributes.iMax do
				self.stackTracker.indicator[i].Animate()
			end
			sampleAnimationStarted = true
		elseif not self.config.hightlightOnFullStacks then
			for i = 1, attributes.iMax do
				self.stackTracker.indicator[i].StopAnimation()
			end
			sampleAnimationStarted = false
		end
	elseif not self.showSampleTracker and sampleAnimationStarted then
		local attributes = CM_TRACKER_CLASS_ATTRIBUTES[self.class]
		for i = 1, attributes.iMax do
			self.stackTracker.indicator[i].StopAnimation()
		end
		sampleAnimationStarted = false
		
	-------------------------
	---- Actual Updating ----
	-------------------------
	
	else
		if self:TrackerIsActive() then
			trackerShouldBeVisible = true
		elseif self.config.trackerIsUnlocked then
			trackerShouldBeVisible = true
		else
			trackerShouldBeVisible = false
		end
		
		if trackerShouldBeVisible then
			local abilitySlotted = CombatMetronome:CheckIfSlotted()
			if self.morphChanged then
				self.stackTracker.indicator.ApplyIcon()
				self.morphChanged = false
			end
			if abilitySlotted then
				self.stackTracker.FadeScenes("UI")
				local attributes = CM_TRACKER_CLASS_ATTRIBUTES[self.class]
				if self.class == "ARC" then
						stacks = self:GetCurrentNumCruxOnPlayer()
				elseif self.class == "DK" then
						stacks = self:GetCurrentNumMWOnPlayer()
				elseif self.class == "SORC" then
						stacks = self:GetCurrentNumBAOnPlayer()
				elseif self.class == "NB" then
						stacks = self:GetCurrentNumGFOnPlayer()
				elseif self.class == "CRO" then
						stacks = self:GetCurrentNumFSOnPlayer()
				end
				for i=1,attributes.iMax do 
					self.stackTracker.indicator[i].Deactivate()
				end
				-- if stacks == 0 then return end
				for i=1,stacks do
					self.stackTracker.indicator[i].Activate()
				end
				if self.config.hightlightOnFullStacks then											--Animation when stacks are full
					if stacks == attributes.iMax and animStart == false then
						for i=1,attributes.iMax do
							self.stackTracker.indicator[i].Animate()
						end
						animStart = true
					end
					if animStart == true and stacks ~= attributes.iMax then
						for i=1,attributes.iMax do
							self.stackTracker.indicator[i].StopAnimation()
						end
						animStart = false
					end
				end
				if self.config.trackerPlaySound then	
					local uiVolume = GetSetting(SETTING_TYPE_AUDIO, AUDIO_SETTING_UI_VOLUME)											--Sound cue when stacks are full
					if previousStack == (attributes.iMax-1) then
						if stacks == attributes.iMax then
							local trackerCue = ZO_QueuedSoundPlayer:New(0)
							trackerCue:SetFinishedAllSoundsCallback(function()
								SetSetting(SETTING_TYPE_AUDIO, AUDIO_SETTING_UI_VOLUME, uiVolume)
								-- d("Sound is finished playing. Volume adjusted. Volume is now "..GetSetting(SETTING_TYPE_AUDIO, AUDIO_SETTING_UI_VOLUME))
							end)
							SetSetting(SETTING_TYPE_AUDIO, AUDIO_SETTING_UI_VOLUME, self.config.trackerVolume)
							-- d("Volume adjusted. Volume is now "..GetSetting(SETTING_TYPE_AUDIO, AUDIO_SETTING_UI_VOLUME))
							trackerCue:PlaySound(SOUNDS[self.config.trackerSound],250)
							-- d("Stacks are full")
						end
					end
				end
				previousStack = stacks
			else
				self.stackTracker.FadeScenes("NoUI")
			end
		else
			self.stackTracker.FadeScenes("NoUI")
		end
	end
end