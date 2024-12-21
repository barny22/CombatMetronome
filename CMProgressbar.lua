local Util = DariansUtilities
Util.Ability = Util.Ability or {}
Util.Ability.Tracker = Util.Ability.Tracker or {}
Util.Text = Util.Text or {}
CombatMetronome.SV = CombatMetronome.SV or {}

local INTERVAL = 200

	--------------------------
	---- Cast Bar Updater ----
	--------------------------

function CombatMetronome:Update()

	local latency, cdTimer

	------------------------
	---- Sample Section ----
	------------------------

	if self.Progressbar.showSample then
		self.Progressbar.bar.segments[2].progress = 0.7
		self.Progressbar.bar.backgroundTexture:SetWidth(0.7*CombatMetronome.SV.Progressbar.width)
		if CombatMetronome.SV.Progressbar.dontShowPing then
			self.Progressbar.bar.segments[1].progress = 0
		else
			self.Progressbar.bar.segments[1].progress = 0.071
		end
		if CombatMetronome.SV.Progressbar.showSpell then
			self.Progressbar.spellLabel:SetText("Generic sample text")
			self.Progressbar.spellLabel:SetHidden(false)
			self.Progressbar.spellIcon:SetTexture("/esoui/art/icons/ability_dualwield_002_b.dds")
			self.Progressbar.spellIcon:SetHidden(false)
			self.Progressbar.spellIconBorder:SetHidden(false)
		else
			self.Progressbar.spellLabel:SetHidden(true)
			self.Progressbar.spellIcon:SetHidden(true)
			self.Progressbar.spellIconBorder:SetHidden(true)
		end
		if CombatMetronome.SV.Progressbar.showTimeRemaining then
			self.Progressbar.timeLabel:SetText("7.8s")
			self.Progressbar.timeLabel:SetHidden(false)
		else
			self.Progressbar.timeLabel:SetHidden(true)
		end
		if CombatMetronome.SV.Progressbar.changeOnChanneled then
			self.Progressbar.bar.segments[2].color = CombatMetronome.SV.Progressbar.channelColor
		else
			self.Progressbar.bar.segments[2].color = CombatMetronome.SV.Progressbar.progressColor
		end
		self.Progressbar.bar:Update()
	else
	
	-------------------------
	---- Actual Updating ----
	-------------------------

		if CombatMetronome.SV.Progressbar.dontShowPing then
			latency = 0
		else
			latency = math.min(GetLatency(), CombatMetronome.SV.Progressbar.maxLatency)
		end
		
		local time = GetFrameTimeMilliseconds()
		
		-- this is important for GCD Tracking
		local gcdProgress, slotRemaining, slotDuration = Util.Ability.Tracker:GCDCheck()

		local interval = false
		if time > self.Progressbar.lastInterval + INTERVAL then
			self.Progressbar.lastInterval = time
			interval = true
		end
		
			---------------------
			---- GCD Tracker ----
			---------------------
		
		if CombatMetronome.SV.Progressbar.soundTockEnabled then
			-- self:OnCDStop()
			-- self.Progressbar.bar:Update()
			if (self.inCombat or (CombatMetronome.SV.Progressbar.showOOC and CombatMetronome.SV.Progressbar.playSoundsOOC)) and not self.Progressbar.soundTockPlayed then --and time > start + (length / 2) - CombatMetronome.SV.Progressbar.soundTockOffset then
				local timeToPlayTock = (self.abilityFinished or 0) + CombatMetronome.SV.Progressbar.soundTockOffset
				local timeToForceTock = (self.lastAbilityFinished or 0) + CombatMetronome.SV.Progressbar.soundTockOffset
				if time >= timeToPlayTock or (CombatMetronome.SV.Progressbar.forceSoundTock and self.currentEvent and time >= timeToForceTock and timeToForceTock >= self.currentEvent.start) then
				
					if CombatMetronome.SV.Progressbar.forceSoundTock and self.currentEvent and time >= timeToForceTock and timeToForceTock >= self.currentEvent.start then		-- kill self.lastAbilityFinished so the statement will not be true in the future
						self.lastAbilityFinished = self.abilityFinished
					else
						self.Progressbar.soundTockPlayed = true
					end
										
					local uiVolume = GetSetting(SETTING_TYPE_AUDIO, AUDIO_SETTING_UI_VOLUME)
					local tockQueue = ZO_QueuedSoundPlayer:New(0)
					tockQueue:SetFinishedAllSoundsCallback(function()
						SetSetting(SETTING_TYPE_AUDIO, AUDIO_SETTING_UI_VOLUME, uiVolume)
					end)
					SetSetting(SETTING_TYPE_AUDIO, AUDIO_SETTING_UI_VOLUME, CombatMetronome.SV.Progressbar.tickVolume)
					tockQueue:PlaySound(CombatMetronome.SV.Progressbar.soundTockEffect, 250)
				end
			end
		end
		
		if CombatMetronome.SV.Progressbar.trackGCD and not self.currentEvent then
			self.Progressbar.bar.segments[1].progress = (CombatMetronome.SV.Progressbar.showPingOnGCD and latency/1000) or 0
			self.Progressbar.bar.segments[2].progress = gcdProgress
			if not Util.Ability.Tracker.rollDodgeFinished and CombatMetronome.SV.Progressbar.trackRolldodge then
				CombatMetronome:GCDSpecifics("Dodgeroll", "/esoui/art/icons/ability_rogue_035.dds", gcdProgress, false)
			end
			if self.Progressbar.activeMount.action ~= "" and CombatMetronome.SV.Progressbar.trackMounting then
				if CombatMetronome.SV.Progressbar.showMountNick then
					CombatMetronome:GCDSpecifics(tostring(self.Progressbar.activeMount.action.." "..self.Progressbar.activeMount.name), self.Progressbar.activeMount.icon, gcdProgress, false)
				else
					CombatMetronome:GCDSpecifics(self.Progressbar.activeMount.action, self.Progressbar.activeMount.icon, gcdProgress, false)
				end
			end
			if self.Progressbar.collectibleInUse and CombatMetronome.SV.Progressbar.trackCollectibles then
				CombatMetronome:GCDSpecifics(self.Progressbar.collectibleInUse.name, self.Progressbar.collectibleInUse.icon, gcdProgress, false)
				-- self.Progressbar.nonAbilityGCDRunning = true
			end
			if self.Progressbar.itemUsed and CombatMetronome.SV.Progressbar.trackItems then
				CombatMetronome:GCDSpecifics(self.Progressbar.itemUsed.name, self.Progressbar.itemUsed.icon, gcdProgress, false)
				-- self.Progressbar.nonAbilityGCDRunning = true
			end
			-- if self.Progressbar.killingAction and CombatMetronome.SV.Progressbar.trackKillingActions and not self.Progressbar.nonAbilityGCDRunning then
				-- CombatMetronome:GCDSpecifics(self.Progressbar.killingAction.name, self.Progressbar.killingAction.icon, gcdProgress)
				-- self.Progressbar.nonAbilityGCDRunning = true
			-- end
			if self.Progressbar.breakingFree and CombatMetronome.SV.Progressbar.trackBreakingFree then
				CombatMetronome:GCDSpecifics(self.Progressbar.breakingFree.name, self.Progressbar.breakingFree.icon, gcdProgress, false)
				-- self.Progressbar.nonAbilityGCDRunning = true
			end
			if self.Progressbar.synergy and CombatMetronome.SV.Progressbar.trackSynergies and self.Progressbar.synergy.wasUsed then
				CombatMetronome:GCDSpecifics(self.Progressbar.synergy.name, self.Progressbar.synergy.icon, gcdProgress, true)
				-- self.Progressbar.nonAbilityGCDRunning = true
			end
			
			if gcdProgress <= 0 then
				CombatMetronome:SetIconsAndNamesNil()
				self:OnCDStop()
			else
				self:HideBar(false)
				self.Progressbar.bar.backgroundTexture:SetWidth(gcdProgress*CombatMetronome.SV.Progressbar.width)
			end
			self.Progressbar.bar:Update()
		elseif self.currentEvent then
			-- if CombatMetronome.SV.debug.triggers then CombatMetronome.debug:Print(slotRemaining) end
			CombatMetronome:SetIconsAndNamesNil()
			if gcdProgress <= 0 and self.currentEvent.ability.delay <= 1000 and not self.currentEvent.ability.channeled then
				self:OnCDStop()
				return
			end
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
						
			-- local playerDidBlock = (self.lastBlockStatus == false) and IsBlockActive()
			-- if playerDidBlock and self.SV.debug.enabled then CombatMetronome.debug:Print("Player blocked") end
			
			if ability.heavy then
				if CombatMetronome.SV.Progressbar.displayPingOnHeavy then
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
				if (self.inCombat or (CombatMetronome.SV.Progressbar.showOOC and CombatMetronome.SV.Progressbar.playSoundsOOC)) and not self.Progressbar.soundTickPlayed and CombatMetronome.SV.Progressbar.soundTickEnabled then --and time > start + length - CombatMetronome.SV.Progressbar.soundTickOffset then
					if (not CombatMetronome.SV.Progressbar.soundTickMidAbility and time >= start + self.SV.Progressbar.soundTickOffset) or (CombatMetronome.SV.Progressbar.soundTickMidAbility and time >= start + duration/2 + self.SV.Progressbar.soundTickOffset) then
						if not (ability.heavy and CombatMetronome.SV.Progressbar.noTickOnHeavy) then
							self.Progressbar.soundTickPlayed = true
							local uiVolume = GetSetting(SETTING_TYPE_AUDIO, AUDIO_SETTING_UI_VOLUME)
							local tickQueue = ZO_QueuedSoundPlayer:New(0)
							tickQueue:SetFinishedAllSoundsCallback(function()
								SetSetting(SETTING_TYPE_AUDIO, AUDIO_SETTING_UI_VOLUME, uiVolume)
								-- if self.SV.debug.enabled then CombatMetronome.debug:Print("Sound is finished playing. Volume adjusted. Volume is now "..GetSetting(SETTING_TYPE_AUDIO, AUDIO_SETTING_UI_VOLUME)) end
							end)
							SetSetting(SETTING_TYPE_AUDIO, AUDIO_SETTING_UI_VOLUME, CombatMetronome.SV.Progressbar.tickVolume)
							tickQueue:PlaySound(CombatMetronome.SV.Progressbar.soundTickEffect, 250)
						end
					end
				end
			------------------------------------------------
			---- Switching Color on channeled abilities ----
			------------------------------------------------
				if CombatMetronome.SV.Progressbar.changeOnChanneled then
					if not ability.instant and ability.delay <= 1000 then
						-- self.SV.debug.enabled then CombatMetronome.debug:Print("Ability with cast time < 1s detected") end
						if timeRemaining >= 0 then
							if self.Progressbar.bar.segments[2].color == CombatMetronome.SV.Progressbar.progressColor then
								self.Progressbar.bar.segments[2].color = CombatMetronome.SV.Progressbar.channelColor
								--if self.SV.debug.enabled then CombatMetronome.debug:Print("Trying to update Channel Color") end
							end
						elseif timeRemaining <= 0 then
							if self.Progressbar.bar.segments[2].color == CombatMetronome.SV.Progressbar.channelColor then
								self.Progressbar.bar.segments[2].color = CombatMetronome.SV.Progressbar.progressColor
								--if self.SV.debug.enabled then CombatMetronome.debug:Print("Turning back to Progress Color") end
							end
						end
					else
						if self.Progressbar.bar.segments[2].color == CombatMetronome.SV.Progressbar.channelColor then
							self.Progressbar.bar.segments[2].color = CombatMetronome.SV.Progressbar.progressColor
						end
					end
				end
				
				self.Progressbar.bar.segments[2].progress = 1 - (cdTimer/duration)
				self.Progressbar.bar.segments[1].progress = latency / duration
				if cdTimer >= (duration+latency) then
					self:OnCDStop()
				else
					self:HideBar(false)
					self.Progressbar.bar.backgroundTexture:SetWidth((1 - (cdTimer/duration))*CombatMetronome.SV.Progressbar.width)
				end
				self.Progressbar.bar:Update()
			end
			------------------------------
			---- Spell Label and Icon ----					--Spell Label on Castbar by barny
			------------------------------
			if CombatMetronome.SV.Progressbar.showSpell and ((ability.delay > 0 and timeRemaining >= 0) or self.SV.Progressbar.alwaysShowSpell) and not ability.heavy then
				local spellName = Util.Text.CropZOSString(ability.name)
				self.Progressbar.spellLabel:SetText(spellName)
				self.Progressbar.spellLabel:SetHidden(false)
			--Spell Icon next to Castbar
				self.Progressbar.spellIcon:SetTexture(ability.icon)
				self.Progressbar.spellIcon:SetHidden(false)
				self.Progressbar.spellIconBorder:SetHidden(false)
			else
				self.Progressbar.spellLabel:SetHidden(true)
				self.Progressbar.spellIcon:SetHidden(true)
				self.Progressbar.spellIconBorder:SetHidden(true)
			end
				
			--Remaining time on Castbar by barny
			if CombatMetronome.SV.Progressbar.showTimeRemaining and ((ability.delay > 0 and timeRemaining >= 0) or self.SV.Progressbar.alwaysShowTimeRemaining) and not ability.heavy then
				-- to have timers at least at 1 second
				if self.SV.Progressbar.alwaysShowTimeRemaining and ability.delay < 1000 then
					timeRemaining = gcdProgress
				end
				self.Progressbar.timeLabel:SetText(string.format("%.1fs", timeRemaining))
				self.Progressbar.timeLabel:SetHidden(false)
			else
				self.Progressbar.timeLabel:SetHidden(true)
			end
			--------------------
			---- Interrupts ----							-- check for interrupts by dodge, barswap or block -- moved to DariansUtilities.Ability.Tracker
			--------------------
			-- if not Util.Ability.Tracker.rollDodgeFinished and CombatMetronome.SV.Progressbar.trackGCD then
				-- self:OnCDStop()
				-- if self.SV.debug.enabled then CombatMetronome.debug:Print("dodge should be interrupting now") end
				-- if CombatMetronome.SV.Progressbar.showSpell then
					-- self.Progressbar.spellLabel:SetHidden(false)
					-- self.Progressbar.spellIcon:SetHidden(false)
					-- self.Progressbar.spellIconBorder:SetHidden(false)
					-- self.Progressbar.spellIcon:SetTexture("/esoui/art/icons/ability_rogue_035.dds")
					-- self.Progressbar.spellLabel:SetText("Dodgeroll")
				-- else
					-- self.Progressbar.spellLabel:SetHidden(true)
					-- self.Progressbar.spellIcon:SetHidden(true)
					-- self.Progressbar.spellIconBorder:SetHidden(true)
				-- end
				-- if CombatMetronome.SV.Progressbar.showTimeRemaining then
					-- self.Progressbar.timeLabel:SetHidden(false)
					-- self.Progressbar.timeLabel:SetText(string.format("%.1fs", gcdProgress))
				-- else
					-- self.Progressbar.timeLabel:SetHidden(true)
				-- end
				-- self.Progressbar.bar.segments[1].progress = (CombatMetronome.SV.Progressbar.showPingOnGCD and latency/1000) or 0
				-- self.Progressbar.bar.segments[2].progress = gcdProgress
				-- if gcdProgress == 0 then
					-- self:OnCDStop()
				-- else
					-- self:HideBar(false)
					-- self.Progressbar.bar.backgroundTexture:SetWidth(gcdProgress*CombatMetronome.SV.Progressbar.width)
				-- end
				-- self.Progressbar.bar:Update()
			-- elseif playerDidBlock then
				-- local eventAdjust = 0
				-- if self.currentEvent then
					-- if self.currentEvent.adjust then
						-- eventAdjust = self.currentEvent.adjust
					-- end
				-- end
				-- if duration > 1000+latency+eventAdjust then
					-- Util.Ability.Tracker.currentEvent = nil
					-- self:OnCDStop()
					-- self.Progressbar.bar:Update()
				-- end
			-- end
		else
			self:OnCDStop()
			self.Progressbar.bar:Update()
		end
		-- self.lastBlockStatus = IsBlockActive()
	end
end