        -------------------------------
        ---- Stack Tracker Updater ----
        -------------------------------

local animStart = false
local trackerShouldBeVisible = false

function CombatMetronome:TrackerUpdate()
	if self.inPVPZone and self.config.hideTrackerInPVP and not self.trackerWarning then
		d("Tracker is still updating...")
		self.trackerWarning = true
	end
	if self:TrackerIsActive() then
		trackerShouldBeVisible = true
	-- if self.class == "ARC" and self.config.trackCrux then
		-- trackerShouldBeVisible = true
	-- elseif self.class == "DK" and self.config.trackMW then
		-- trackerShouldBeVisible = true
	-- elseif self.class == "SOR" and self.config.trackBA then
		-- trackerShouldBeVisible = true
	-- elseif self.class == "NB" and self.config.trackGF then
		-- trackerShouldBeVisible = true
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