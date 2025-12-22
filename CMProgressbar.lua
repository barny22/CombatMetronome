local Util = DariansUtilities
Util.Ability = Util.Ability or {}
Util.Ability.Tracker = Util.Ability.Tracker or {}
Util.Text = Util.Text or {}
CombatMetronome.SV = CombatMetronome.SV or {}

-- local INTERVAL = 200

local function AnchorSpellIcon(dynamic)
	if dynamic and not CombatMetronome.Progressbar.spellIconAnchoredDynamically then
		CombatMetronome.Progressbar.spellIcon:ClearAnchors()
		CombatMetronome.Progressbar.spellIcon:SetAnchor(RIGHT, CombatMetronome.Progressbar.bar.segments[2].bars[1], RIGHT, -(CombatMetronome.SV.Progressbar.height/10), 0)
		CombatMetronome.Progressbar.spellIconAnchoredDynamically = true
	elseif CombatMetronome.Progressbar.spellIconAnchoredDynamically and not dynamic then
		CombatMetronome.Progressbar.spellIcon:ClearAnchors()
		CombatMetronome.Progressbar.spellIcon:SetAnchor(RIGHT, CombatMetronome.Progressbar.frame, LEFT, -(CombatMetronome.SV.Progressbar.height/10), 0)
		CombatMetronome.Progressbar.spellIconAnchoredDynamically = false
	end
end

	--------------------------
	---- Cast Bar Updater ----
	--------------------------

function CombatMetronome:Update()

	local latency, cdTimer
	local sv = CombatMetronome.SV.Progressbar
	local progressbar = CombatMetronome.Progressbar

	------------------------
	---- Sample Section ----
	------------------------

	if progressbar.showSample then
		progressbar.bar.segments[2].progress = 0.7
		progressbar.bar.backgroundTexture:SetWidth(0.7*sv.width)
		if sv.dontShowPing then
			progressbar.bar.segments[1].progress = 0
		else
			progressbar.bar.segments[1].progress = 0.071
		end
		if sv.showSpell then
			progressbar.spellLabel:SetText("Generic sample text")
			progressbar.spellIcon:SetTexture("/esoui/art/icons/ability_dualwield_002_b.dds")
		end
		if sv.showTimeRemaining then
			progressbar.timeLabel:SetText("7.8s")
		end
		if sv.changeOnChanneled then
			progressbar.bar.segments[2].color = sv.channelColor
		else
			progressbar.bar.segments[2].color = sv.progressColor
		end
		progressbar.bar:Update()
		progressbar.UI.HiddenStates()
	else
	
	-------------------------
	---- Actual Updating ----
	-------------------------
	
		-- reset channeled color --
		if not (self.currentEvent and self.currentEvent.ability and ((not self.currentEvent.ability.instant and self.currentEvent.ability.delay <= 1000) or self.currentEvent.ability.delay > 1000)) and progressbar.bar.segments[2].color ~= sv.progressColor then
			progressbar.bar.segments[2].color = sv.progressColor
		elseif not self.currentEvent and progressbar.bar.segments[2].color ~= sv.progressColor then
			progressbar.bar.segments[2].color = sv.progressColor
		end
		
		if sv.dontShowPing then
			latency = 0
		else
			latency = math.min(GetLatency(), sv.maxLatency)
		end
		
		local time = GetFrameTimeMilliseconds()
		
		-- this is important for GCD Tracking
		local gcdProgress, slotRemaining, slotDuration = Util.Ability.Tracker:GCDCheck()
				
		-- local interval = false
		-- if time > progressbar.lastInterval + INTERVAL then
			-- progressbar.lastInterval = time
			-- interval = true
		-- end
		
			---------------------
			---- GCD Tracker ----
			---------------------
		
		if sv.soundTockEnabled then
			if (self.inCombat or (sv.showOOC and sv.playSoundsOOC)) and not progressbar.soundTockPlayed then --and time > start + (length / 2) - sv.soundTockOffset then
				local timeToPlayTock = (self.abilityFinished or 0) + sv.soundTockOffset
				local timeToForceTock = (self.lastAbilityFinished or 0) + sv.soundTockOffset
				if time >= timeToPlayTock or (sv.forceSoundTock and self.currentEvent and time >= timeToForceTock and timeToForceTock >= self.currentEvent.start) then
				
					if sv.forceSoundTock and self.currentEvent and time >= timeToForceTock and timeToForceTock >= self.currentEvent.start then		-- kill self.lastAbilityFinished so the statement will not be true in the future
						self.lastAbilityFinished = self.abilityFinished
					else
						progressbar.soundTockPlayed = true
					end
										
					local uiVolume = GetSetting(SETTING_TYPE_AUDIO, AUDIO_SETTING_UI_VOLUME)
					local tockQueue = ZO_QueuedSoundPlayer:New(0)
					tockQueue:SetFinishedAllSoundsCallback(function()
						SetSetting(SETTING_TYPE_AUDIO, AUDIO_SETTING_UI_VOLUME, uiVolume)
					end)
					SetSetting(SETTING_TYPE_AUDIO, AUDIO_SETTING_UI_VOLUME, sv.tickVolume)
					tockQueue:PlaySound(sv.soundTockEffect, 250)
				end
			end
		end
		
		if sv.trackGCD and not self.currentEvent then
			
			--reset spellIcon anchor
			if progressbar.spellIconAnchoredDynamically then
				AnchorSpellIcon(false)
			end
			
			progressbar.bar.background:SetWidth(sv.width)
			progressbar.bar.borderL:SetWidth(sv.width/2)
			progressbar.bar.borderR:SetWidth(sv.width/2)
			
			progressbar.bar.segments[1].progress = (sv.showPingOnGCD and latency/1000) or 0
			progressbar.bar.segments[2].progress = gcdProgress
			if not Util.Ability.Tracker.rollDodgeFinished and sv.trackRolldodge then
				self:GCDSpecifics(Util.Text.CropZOSString(GetAbilityName(28549), "ability"), "/esoui/art/icons/ability_rogue_035.dds", gcdProgress, false)
			elseif progressbar.activeMount.action ~= "" and sv.trackMounting then
				if sv.showMountNick then
					self:GCDSpecifics(tostring(progressbar.activeMount.action.." "..progressbar.activeMount.name), progressbar.activeMount.icon, gcdProgress, false)
				else
					self:GCDSpecifics(progressbar.activeMount.action, progressbar.activeMount.icon, gcdProgress, false)
				end
			elseif progressbar.collectibleInUse and sv.trackCollectibles then
				self:GCDSpecifics(progressbar.collectibleInUse.name, progressbar.collectibleInUse.icon, gcdProgress, false)
				-- progressbar.nonAbilityGCDRunning = true
			elseif progressbar.synergy and sv.trackSynergies and progressbar.synergy.wasUsed then
				self:GCDSpecifics(progressbar.synergy.name, progressbar.synergy.icon, gcdProgress, true)
				-- progressbar.nonAbilityGCDRunning = true
			elseif progressbar.itemUsed and sv.trackItems then
				self:GCDSpecifics(progressbar.itemUsed.name, progressbar.itemUsed.icon, gcdProgress, false)
				-- progressbar.nonAbilityGCDRunning = true
			elseif progressbar.breakingFree and sv.trackBreakingFree then
				self:GCDSpecifics(progressbar.breakingFree.name, progressbar.breakingFree.icon, gcdProgress, false)
				-- progressbar.nonAbilityGCDRunning = true
			elseif progressbar.festivalGCD then
				self:GCDSpecifics(self.FESTIVAL_IDS[progressbar.festivalGCD].name, self.FESTIVAL_IDS[progressbar.festivalGCD].icon, gcdProgress, false)
			end
			
			if gcdProgress <= 0 then
				self:SetIconsAndNamesNil()
				self:OnCDStop()
			else
				self:HideBar(false)
				progressbar.bar.backgroundTexture:SetWidth(gcdProgress*sv.width)
			end
			progressbar.bar:Update()
		elseif self.currentEvent then
			-- if CombatMetronome.SV.debug.triggers then CombatMetronome.debug:Print(remaining) end
			self:SetIconsAndNamesNil()
			if gcdProgress <= 0 and self.currentEvent.ability.delay <= 1000 and not self.currentEvent.ability.channeled then
				self:OnCDStop()
				return
			end
			local ability = self.currentEvent.ability
			
			if not ability.name or ability.name == "" then
				self:OnCDStop()
				return
			end
			
			local start = self.currentEvent.start
			if time - start < 0 then
				cdTimer = 0
			else
				cdTimer = time - start
			end
			
			local duration = math.max(ability.heavy and sv.stopHATracking and 0 or (self.gcd or 1000), ability.delay) + (self.currentEvent.adjust or 0)
			-- local timeRemaining = ((start + duration + latency) - time) / 1000 or ((start + channelTime + latency) - time) < 0 and 0
			local timeRemaining = (duration - cdTimer) / 1000
			local castProgress = timeRemaining/(duration/1000)
			
			local dynamicProgress = sv.expandDynamically and sv.dynamicExpansionMultiplyer*duration/10000 > 1
			-- local multiplyerCheck = sv.dynamicExpansionMultiplyer*math.max(duration, timeRemaining*1000)/10000 > 1
						
			-- local playerDidBlock = (self.lastBlockStatus == false) and IsBlockActive()
			-- if playerDidBlock and self.SV.debug.enabled then CombatMetronome.debug:Print("Player blocked") end
			
			if ability.heavy then
				if sv.displayPingOnHeavy then
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
				return
			else
				local length = duration - latency
				
				-- Sound contributed to by Seltiix --
				if (self.inCombat or (sv.showOOC and sv.playSoundsOOC)) and not progressbar.soundTickPlayed and sv.soundTickEnabled then --and time > start + length - sv.soundTickOffset then
					if (not sv.soundTickMidAbility and time >= start + sv.soundTickOffset) or (sv.soundTickMidAbility and time >= start + duration/2 + sv.soundTickOffset) then
						if not (ability.heavy and sv.noTickOnHeavy) then
							progressbar.soundTickPlayed = true
							local uiVolume = GetSetting(SETTING_TYPE_AUDIO, AUDIO_SETTING_UI_VOLUME)
							local tickQueue = ZO_QueuedSoundPlayer:New(0)
							tickQueue:SetFinishedAllSoundsCallback(function()
								SetSetting(SETTING_TYPE_AUDIO, AUDIO_SETTING_UI_VOLUME, uiVolume)
								-- if self.SV.debug.enabled then CombatMetronome.debug:Print("Sound is finished playing. Volume adjusted. Volume is now "..GetSetting(SETTING_TYPE_AUDIO, AUDIO_SETTING_UI_VOLUME)) end
							end)
							SetSetting(SETTING_TYPE_AUDIO, AUDIO_SETTING_UI_VOLUME, sv.tickVolume)
							tickQueue:PlaySound(sv.soundTickEffect, 250)
						end
					end
				end
			------------------------------------------------
			---- Switching Color on channeled abilities ----
			------------------------------------------------
				if sv.changeOnChanneled then
					if (not ability.instant and ability.delay <= 1000) or ability.delay > 1000 then
						local castIsFinished = ((ability.delay <= 1000) and (timeRemaining*1000 <= 1000 - ability.delay)) or (timeRemaining <= 0)
						-- self.SV.debug.enabled then CombatMetronome.debug:Print("Ability with cast time < 1s detected") end
						if not castIsFinished and progressbar.bar.segments[2].color == sv.progressColor then
							progressbar.bar.segments[2].color = sv.channelColor
							if self.SV.debug.enabled then CombatMetronome.debug:Print(zo_strformat("Trying to update Channel Color for event named <<1>>", ability.name)) end
						elseif castIsFinished  and progressbar.bar.segments[2].color == sv.channelColor then
							progressbar.bar.segments[2].color = sv.progressColor
							--if self.SV.debug.enabled then CombatMetronome.debug:Print("Turning back to Progress Color") end
						end
					else
						if progressbar.bar.segments[2].color == sv.channelColor then
							progressbar.bar.segments[2].color = sv.progressColor
						end
					end
				end
				if cdTimer >= (duration+latency) then
					self:OnCDStop()
				else
					self:HideBar(false)
					-- progressbar.bar.backgroundTexture:SetWidth((1 - (cdTimer/duration))*sv.width)
				end
				progressbar.bar:Update()
				
				if dynamicProgress then
					local multiplyer = sv.dynamicExpansionMultiplyer*duration/10000
					local isDynamic = castProgress*multiplyer > 1
					local dynamicBarWidth = isDynamic and sv.width*castProgress*multiplyer or sv.width
					progressbar.bar.segments[2].progress = isDynamic and 1 or castProgress*multiplyer
					progressbar.bar.segments[1].progress = isDynamic and multiplyer*latency / (1000*timeRemaining) or sv.dynamicExpansionMultiplyer*latency/duration
					progressbar.bar.background:SetWidth(dynamicBarWidth)
					progressbar.bar.backgroundTexture:SetWidth(sv.width*castProgress*multiplyer)
					progressbar.bar.borderL:SetWidth(dynamicBarWidth/2)
					progressbar.bar.borderR:SetWidth(dynamicBarWidth/2)
					local dynamicAnchor = sv.barAlign == "Center" and sv.moveIconDynamically and isDynamic
					AnchorSpellIcon(dynamicAnchor)
				else
					progressbar.bar.background:SetWidth(sv.width)
					progressbar.bar.segments[2].progress = castProgress
					progressbar.bar.segments[1].progress = latency / duration
					progressbar.bar.backgroundTexture:SetWidth(castProgress*sv.width)
					self.Progressbar.bar.borderL:SetWidth(sv.width/2)
					self.Progressbar.bar.borderR:SetWidth(sv.width/2)
					AnchorSpellIcon(false)
				end
			end
			------------------------------
			---- Spell Label and Icon ----
			------------------------------	
			
			--Remaining time on Castbar by barny
			if sv.showTimeRemaining and ((ability.delay > 0 and timeRemaining >= 0) or sv.alwaysShowTimeRemaining) and not ability.heavy then
				-- to have timers at least at 1 second
				if sv.alwaysShowTimeRemaining and ability.delay < 1000 then
					timeRemaining = gcdProgress
				end
				progressbar.timeLabel:SetText(string.format("%.1fs", timeRemaining))
				progressbar.timeLabel:SetHidden(false)
			else
				progressbar.timeLabel:SetHidden(true)
			end
			
			--Spell Label on Castbar by barny
			if sv.showSpell and ((ability.delay > 0 and timeRemaining >= 0) or sv.alwaysShowSpell) and not ability.heavy then
				if not ability.displayName or dynamicProgress then
					progressbar.spellLabel:SetText(ability.name)
					local barSpace = sv.width - (sv.showTimeRemaining and 2.5*progressbar.timeLabel:GetWidth() or 0)
					if progressbar.spellLabel:GetWidth() > barSpace then
						for i = #ability.name, 1, -1 do
							local shortName =  string.sub(ability.name, 1, i):gsub("%s+$", "") .. ".."
							progressbar.spellLabel:SetText(shortName)
							if progressbar.spellLabel:GetWidth() <= barSpace then
								ability.displayName = shortName
								break
							end
						end
					else
						ability.displayName = ability.name
					end
				end
				progressbar.spellLabel:SetText(ability.displayName)
				progressbar.spellLabel:SetHidden(false)
				
			--Spell Icon next to Castbar
				progressbar.spellIcon:SetTexture(ability.icon)
				progressbar.spellIcon:SetHidden(false)
				progressbar.spellIconBorder:SetHidden(false)
			else
				progressbar.spellLabel:SetHidden(true)
				progressbar.spellIcon:SetHidden(true)
				progressbar.spellIconBorder:SetHidden(true)
			end
		else
			self:OnCDStop()
			progressbar.bar:Update()
		end
	end
end