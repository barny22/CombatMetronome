function CombatMetronome:CheckSavedVariables()
	if _G["CombatMetronomeSavedVars"] and
	   _G["CombatMetronomeSavedVars"].Default[GetDisplayName()] and
	   _G["CombatMetronomeSavedVars"].Default[GetDisplayName()][GetCurrentCharacterId()] and
	   _G["CombatMetronomeSavedVars"].Default[GetDisplayName()][GetCurrentCharacterId()].version == 1 then
		for charId, sv in pairs(_G["CombatMetronomeSavedVars"].Default[GetDisplayName()]) do
			if sv.version == 1 then
				_G["CombatMetronomeSavedVars"].Default[GetDisplayName()][charId] = {}
				_G["CombatMetronomeSavedVars"].Default[GetDisplayName()][charId] = CombatMetronome:ConvertSavedVariables(sv)
			end
		end
	end
end

function CombatMetronome:ConvertSavedVariables(oldSV)
	local configCache = oldSV
	self.SV = {}
	self.SV.version = 2
	self.SV.global = configCache.global
	
	self.SV.Progressbar = { }
	self.SV.Progressbar.hide = configCache.hideProgressbar
	self.SV.Progressbar.hideInPVP = configCache.hideCMInPVP
	self.SV.Progressbar.xOffset = configCache.xOffset
	self.SV.Progressbar.yOffset = configCache.yOffset
	self.SV.Progressbar.width = configCache.width
	self.SV.Progressbar.height = configCache.height
	self.SV.Progressbar.dontHide = configCache.dontHide
	self.SV.Progressbar.dontShowPing = configCache.dontShowPing
	self.SV.Progressbar.lastBackgroundColor = configCache.lastBackgroundColor
	self.SV.Progressbar.backgroundColor = configCache.backgroundColor
	self.SV.Progressbar.progressColor = configCache.progressColor
	self.SV.Progressbar.pingColor = configCache.pingColor
	self.SV.Progressbar.channelColor = configCache.channelColor
	self.SV.Progressbar.colorCache = configCache.colorCache
	self.SV.Progressbar.changeOnChanneled = configCache.changeOnChanneled
	self.SV.Progressbar.gcdAdjust = configCache.gcdAdjust
	self.SV.Progressbar.barAlign = configCache.barAlign
	self.SV.Progressbar.labelFont = configCache.labelFont
	self.SV.Progressbar.fontStyle = configCache.fontStyle
	self.SV.Progressbar.trackGCD = configCache.trackGCD
	self.SV.Progressbar.displayPingOnHeavy = configCache.displayPingOnHeavy
	self.SV.Progressbar.spellSize = configCache.spellSize
	self.SV.Progressbar.globalHeavyAdjust = configCache.globalHeavyAdjust
	self.SV.Progressbar.globalAbilityAdjust = configCache.globalAbilityAdjust
	self.SV.Progressbar.abilityAdjusts = configCache.abilityAdjusts
	self.SV.Progressbar.showSpell = configCache.showSpell
	self.SV.Progressbar.showTimeRemaining = configCache.showTimeRemaining
	self.SV.Progressbar.soundTickEnabled = configCache.soundTickEnabled
	self.SV.Progressbar.tickVolume = configCache.tickVolume
	self.SV.Progressbar.soundTickEffect = configCache.soundTickEffect
	self.SV.Progressbar.soundTickOffset = configCache.soundTickOffset
	self.SV.Progressbar.soundTockEnabled = configCache.soundTockEnabled
	self.SV.Progressbar.soundTockEffect = configCache.soundTockEffect
	self.SV.Progressbar.soundTockOffset = configCache.soundTockOffset
	self.SV.Progressbar.stopHATracking = configCache.stopHATracking
	self.SV.Progressbar.makeItFancy = configCache.makeItFancy
	self.SV.Progressbar.maxLatency = configCache.maxLatency
	self.SV.Progressbar.trackCollectibles = configCache.trackCollectibles
	self.SV.Progressbar.trackMounting = configCache.trackMounting
	self.SV.Progressbar.showMountNick = configCache.showMountNick
	self.SV.Progressbar.trackItems = configCache.trackItems
	self.SV.Progressbar.trackRolldodge = configCache.trackRolldodge
	self.SV.Progressbar.trackKillingActions = configCache.trackKillingActions
	self.SV.Progressbar.trackBreakingFree = configCache.trackBreakingFree
	self.SV.Progressbar.showPingOnGCD = true
	
	self.SV.Resources = { }
	self.SV.Resources.anchorResourcesToProgressbar = configCache.anchorResourcesToProgressbar
	self.SV.Resources.hideInPVP = configCache.hideResourcesInPVP
	self.SV.Resources.xOffset = configCache.labelFrameXOffset
	self.SV.Resources.yOffset = configCache.labelFrameYOffset
	self.SV.Resources.width = configCache.labelFrameWidth
	self.SV.Resources.height = configCache.labelFrameHeight
	self.SV.Resources.showResources = configCache.showResources
	self.SV.Resources.showUltimate = configCache.showUltimate
	self.SV.Resources.showStamina = configCache.showStamina
	self.SV.Resources.showMagicka = configCache.showMagicka
	self.SV.Resources.showHealth = configCache.showHealth
	self.SV.Resources.ultColor = configCache.ultColor
	self.SV.Resources.magColor = configCache.magColor
	self.SV.Resources.stamColor = configCache.stamColor
	self.SV.Resources.healthColor = configCache.healthColor
	self.SV.Resources.healthHighligtColor = configCache.healthHighligtColor
	self.SV.Resources.stamSize = configCache.stamSize
	self.SV.Resources.magSize = configCache.magSize
	self.SV.Resources.ultSize = configCache.ultSize
	self.SV.Resources.healthSize = configCache.healthSize
	self.SV.Resources.showResourcesForGuard = configCache.showResourcesForGuard
	self.SV.Resources.hpHighlightThreshold = configCache.hpHighlightThreshold
	self.SV.Resources.reticleHp = configCache.reticleHp
	
	self.SV.StackTracker = { }
	self.SV.StackTracker.isUnlocked = configCache.trackerIsUnlocked
	self.SV.StackTracker.hideInPVP = configCache.hideTrackerInPVP
	self.SV.StackTracker.trackMW = configCache.trackMW
	self.SV.StackTracker.trackBA = configCache.trackBA
	self.SV.StackTracker.trackGF = configCache.trackGF
	self.SV.StackTracker.trackCrux = configCache.trackCrux
	self.SV.StackTracker.trackFS = configCache.trackFS
	self.SV.StackTracker.indicatorSize = configCache.indicatorSize
	self.SV.StackTracker.xOffset = configCache.trackerX
	self.SV.StackTracker.yOffset = configCache.trackerY
	self.SV.StackTracker.hideTracker = configCache.hideTracker
	self.SV.StackTracker.playSound = configCache.trackerPlaySound
	self.SV.StackTracker.volume = configCache.trackerVolume
	self.SV.StackTracker.hightlightOnFullStacks = configCache.hightlightOnFullStacks
	self.SV.StackTracker.sound = configCache.trackerSound
	
	self.SV.LATracker = { }
	self.SV.LATracker.xOffset = configCache.LATrackerXOffset
	self.SV.LATracker.yOffset = configCache.LATrackerYOffset
	self.SV.LATracker.width = configCache.LATrackerWidth
	self.SV.LATracker.height = configCache.LATrackerHeight
	self.SV.LATracker.choice = configCache.laTrackerChoice
	self.SV.LATracker.timeTilHiding = configCache.timeTilHidingLATracker
	self.SV.LATracker.isUnlocked = configCache.laTrackerIsUnlocked
	self.SV.LATracker.hideInPVP	= configCache.hideLATrackerInPVP
	
	self.SV.debug = { }
	self.SV.debug.enabled = false
	self.SV.debug.triggers = false
	self.SV.debug.currentEvent = false
	self.SV.debug.triggerTimer = 170
	
	return self.SV
end
