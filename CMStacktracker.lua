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
local previousStack

function StackTracker:HandleEffectChanged(_,changeType, _, _, unitTag, _, _, stackCount, _, _, _, _, _, uName, uId, aId, _)	
	if not self.trackedIds[aId] then return end
	
	local iMax = self.SKILL_ATTRIBUTES[self.trackedIds[aId]].iMax
	if self.trackedIds[aId] == "FI" then 
		stackCount = 1
	elseif self.trackedIds[aId] == "FS" and stackCount == 3 then
		stackCount = 0
	end
	-- if CombatMetronome.SV.debug.enabled then CombatMetronome.debug:Print("Found matching id, initiating stackCount change") end
	if changeType == EFFECT_RESULT_FADED then stackCount = 0 end
	self:ChangeStackCount(self.trackedIds[aId], stackCount)
end

function StackTracker:HandleHotbarChangeRequested(_,aId,_,_)
	local morph = Util.Stacks.morphs.FS
	for i=2,3 do
		if self.SKILL_ATTRIBUTES.FS.id[morph].ability[i] then
			self:ChangeStackCount("FS", i-1)
			break
		end
	end
end

function StackTracker:ChangeStackCount(skill, stackCount)
	if not self.UI[skill] then
		if CombatMetronome.SV.debug.enabled then CombatMetronome.debug:Print("Tried to change "..skill.." stackCount without UI initialized") end
		return
	end
	local attributes = self.SKILL_ATTRIBUTES[skill]
	local oneOff = attributes.iMax - 1
	local animStart = not self.UI[skill].indicator[attributes.iMax].controls.highlightAnimation:IsControlHidden()
	previousStack = self.stacks[skill]
	self.stacks[skill] = stackCount
	
	
	for i=1,#self.UI[skill].indicator do 
		self.UI[skill].indicator[i].Deactivate()
		self.UI[skill].indicator[i].SetAnimationHidden(true)
	end
	if CombatMetronome.SV.StackTracker[skill].hightlightOnFullStacks then											--Animation when stacks are full
		if stackCount >= attributes.iMax and not animStart then
			for i=1,#self.UI[skill].indicator do
				self.UI[skill].indicator[i].Animate()
			end
			animStart = true
		elseif animStart == true and stackCount < attributes.iMax then
			for i=1,#self.UI[skill].indicator do
				self.UI[skill].indicator[i].StopAnimation()
			end
			animStart = false
		end
	end
	for i=1,stackCount do
		self.UI[skill].indicator[i].Activate()
		if animStart then self.UI[skill].indicator[i].SetAnimationHidden(false) end
	end
	if CombatMetronome.SV.StackTracker[skill].playSound then
		local uiVolume = GetSetting(SETTING_TYPE_AUDIO, AUDIO_SETTING_UI_VOLUME)											--Sound cue when stacks are full
		if previousStack == oneOff and stackCount == attributes.iMax then
			local trackerCue = ZO_QueuedSoundPlayer:New(0)
			trackerCue:SetFinishedAllSoundsCallback(function()
				SetSetting(SETTING_TYPE_AUDIO, AUDIO_SETTING_UI_VOLUME, uiVolume)
				--if self.SV.debug.enabled then CombatMetronome.debug:Print("Sound is finished playing. Volume adjusted. Volume is now "..GetSetting(SETTING_TYPE_AUDIO, AUDIO_SETTING_UI_VOLUME)) end
			end)
			SetSetting(SETTING_TYPE_AUDIO, AUDIO_SETTING_UI_VOLUME, CombatMetronome.SV.StackTracker[skill].volume)
			--if self.SV.debug.enabled then CombatMetronome.debug:Print("Volume adjusted. Volume is now "..GetSetting(SETTING_TYPE_AUDIO, AUDIO_SETTING_UI_VOLUME)) end
			trackerCue:PlaySound(SOUNDS[CombatMetronome.SV.StackTracker[skill].sound],250)
			--if self.SV.debug.enabled then CombatMetronome.debug:Print("Stacks are full") end
		end
	end
end