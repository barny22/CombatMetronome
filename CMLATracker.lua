local CM = CombatMetronome
CM.LATracker = CM.LATracker or {}
local LATracker = CM.LATracker

local NumLA = 0
local TimeOfLastLA = 0
local TimeBetweenLA = 0
local LightAttacksPerSecond = 0

function LATracker:HandleLightAttacks(time)
	if CM.config.hideLATrackerInPVP and CM.inPVPZone then
		return
	else
		if CM.inCombat and not self.combatStart then
			self.combatStart = time
			LATracker:NumberOfLightAttacks()
			LATracker:TimeBetweenLightAttacks(time)
			LATracker:CalculateLightAttacksPerSecond(time)
			LATracker:DisplayText()
		elseif CM.inCombat and self.combatStart then
			LATracker:NumberOfLightAttacks()
			LATracker:TimeBetweenLightAttacks(time)
			LATracker:CalculateLightAttacksPerSecond(time)
			LATracker:DisplayText()
		end
	end
end

function LATracker:NumberOfLightAttacks()
	if self.combatStart then
		NumLA = NumLA + 1
	end
end

function LATracker:TimeBetweenLightAttacks(time)
	if TimeOfLastLA ~= 0 then
		TimeBetweenLA = time - TimeOfLastLA
	else
		TimeBetweenLA = 0
	end
	TimeOfLastLA = time
end

function LATracker:CalculateLightAttacksPerSecond(time)
	if NumLA ~= 0 and self.combatStart then
		LightAttacksPerSecond = (NumLA * 1000) / (time - self.combatStart)
		
	end
end

function LATracker:DisplayText()
	if CM.config.laTrackerChoice == "Nothing" then
		LATracker.label:SetHidden(true)
	else
		if CM.inCombat or CM.config.laTrackerIsUnlocked then
			LATracker.label:SetHidden(false)
			if CM.config.laTrackerChoice == "Time between light attacks" then
				LATracker.label:SetText(TimeBetweenLA.." ms")
			elseif CM.config.laTrackerChoice == "la/s" then
				LATracker.label:SetText(string.format("%.2f", LightAttacksPerSecond).." la/s")
			end
		end
	end
end	

function LATracker:StartLATracker()
	if not self.combatStart then
		self.combatStart = GetFrameTimeMilliseconds()
	end
end

function LATracker:ResetLATracker()
	LATracker:CalculateLightAttacksPerSecond(GetFrameTimeMilliseconds())
	LATracker:DisplayText()
	if CM.config.showLALogAfterFight then
		d("End of combat")
		d("You've been in combat for "..((GetFrameTimeMilliseconds()-self.combatStart)/1000).."s")
		d("Total amount of light attacks: "..NumLA)
		d("This equals to "..LightAttacksPerSecond.." la/s")
	end
	if NumLA ~= 0 then NumLA = 0 end
	if TimeOfLastLA ~= 0 then TimeOfLastLA = 0 end
	if TimeBetweenLA ~= 0 then TimeBetweenLA = 0 end
	if LightAttacksPerSecond ~= 0 then LightAttacksPerSecond = 0 end
	self.combatStart = nil
	zo_callLater(function()
		if CM.inCombat == false then
			LATracker.label:SetHidden(true)
		end
	end,
	CM.config.timeTilHidingLATracker*1000)
end

function LATracker:ManageLATracker(inCombat)
	if not inCombat and LATracker.combatStart then LATracker:ResetLATracker() end
	if inCombat and not LATracker.combatStart then LATracker:StartLATracker() end
end