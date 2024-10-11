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
			
		if CombatMetronome.SV.Progressbar.trackGCD and not self.currentEvent then
			self.Progressbar.bar.segments[1].progress = (CombatMetronome.SV.Progressbar.showPingOnGCD and latency/1000) or 0
			self.Progressbar.bar.segments[2].progress = gcdProgress
			if not Util.Ability.Tracker.rollDodgeFinished and CombatMetronome.SV.Progressbar.trackRolldodge then
				CombatMetronome:GCDSpecifics("Dodgeroll", "/esoui/art/icons/ability_rogue_035.dds", gcdProgress)
			end
			if self.Progressbar.activeMount.action ~= "" and CombatMetronome.SV.Progressbar.trackMounting then
				if CombatMetronome.SV.Progressbar.showMountNick then
					CombatMetronome:GCDSpecifics(tostring(self.Progressbar.activeMount.action.." "..self.Progressbar.activeMount.name), self.Progressbar.activeMount.icon, gcdProgress)
				else
					CombatMetronome:GCDSpecifics(self.Progressbar.activeMount.action, self.Progressbar.activeMount.icon, gcdProgress)
				end
			end
			if self.Progressbar.collectibleInUse and CombatMetronome.SV.Progressbar.trackCollectibles then
				CombatMetronome:GCDSpecifics(self.Progressbar.collectibleInUse.name, self.Progressbar.collectibleInUse.icon, gcdProgress)
			end
			if self.Progressbar.itemUsed and CombatMetronome.SV.Progressbar.trackItems then
				CombatMetronome:GCDSpecifics(self.Progressbar.itemUsed.name, self.Progressbar.itemUsed.icon, gcdProgress)
			end
			if self.killingAction and CombatMetronome.SV.Progressbar.trackKillingActions then
				CombatMetronome:GCDSpecifics(self.killingAction.name, self.killingAction.icon, gcdProgress)
			end
			if self.breakingFree and CombatMetronome.SV.Progressbar.trackBreakingFree then
				CombatMetronome:GCDSpecifics(self.breakingFree.name, self.breakingFree.icon, gcdProgress)
			end
			-- if self.otherSynergies and CombatMetronome.SV.Progressbar.trackOthers then
				-- CombatMetronome:GCDSpecifics(self.otherSynergies.name, self.otherSynergies.icon, gcdProgress)
			-- end
			
			if gcdProgress <= 0 then
				CombatMetronome:SetIconsAndNamesNil()
				self:OnCDStop()
			else
				self:HideBar(false)
				self.Progressbar.bar.backgroundTexture:SetWidth(gcdProgress*CombatMetronome.SV.Progressbar.width)
			end
			self.Progressbar.bar:Update()
		elseif self.currentEvent then
			CombatMetronome:SetIconsAndNamesNil()
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
			-- if playerDidBlock then d("Player blocked") end
			
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
			else
				-- Sound contributed to by Seltiix --

				local length = duration - latency

				if not self.Progressbar.soundTockPlayed and CombatMetronome.SV.Progressbar.soundTockEnabled and time > start + (length / 2) - CombatMetronome.SV.Progressbar.soundTockOffset then
					self.Progressbar.soundTockPlayed = true
					local uiVolume = GetSetting(SETTING_TYPE_AUDIO, AUDIO_SETTING_UI_VOLUME)
					local tockQueue = ZO_QueuedSoundPlayer:New(0)
					tockQueue:SetFinishedAllSoundsCallback(function()
						SetSetting(SETTING_TYPE_AUDIO, AUDIO_SETTING_UI_VOLUME, uiVolume)
					end)
					SetSetting(SETTING_TYPE_AUDIO, AUDIO_SETTING_UI_VOLUME, CombatMetronome.SV.Progressbar.tickVolume)
					tockQueue:PlaySound(CombatMetronome.SV.Progressbar.soundTockEffect, 250)
				end

				if not self.Progressbar.soundTickPlayed and CombatMetronome.SV.Progressbar.soundTickEnabled and time > start + length - CombatMetronome.SV.Progressbar.soundTickOffset then
					self.Progressbar.soundTickPlayed = true
					local uiVolume = GetSetting(SETTING_TYPE_AUDIO, AUDIO_SETTING_UI_VOLUME)
					local tickQueue = ZO_QueuedSoundPlayer:New(0)
					tickQueue:SetFinishedAllSoundsCallback(function()
						SetSetting(SETTING_TYPE_AUDIO, AUDIO_SETTING_UI_VOLUME, uiVolume)
						-- d("Sound is finished playing. Volume adjusted. Volume is now "..GetSetting(SETTING_TYPE_AUDIO, AUDIO_SETTING_UI_VOLUME))
					end)
					SetSetting(SETTING_TYPE_AUDIO, AUDIO_SETTING_UI_VOLUME, CombatMetronome.SV.Progressbar.tickVolume)
					tickQueue:PlaySound(CombatMetronome.SV.Progressbar.soundTickEffect, 250)
				end
			------------------------------------------------
			---- Switching Color on channeled abilities ----
			------------------------------------------------
				if CombatMetronome.SV.Progressbar.changeOnChanneled then
					if not ability.instant and ability.delay <= 1000 then
						-- d("Ability with cast time < 1s detected")
						if timeRemaining >= 0 then
							if self.Progressbar.bar.segments[2].color == CombatMetronome.SV.Progressbar.progressColor then
								self.Progressbar.bar.segments[2].color = CombatMetronome.SV.Progressbar.channelColor
								-- d("Trying to update Channel Color")
							end
						elseif timeRemaining <= 0 then
							if self.Progressbar.bar.segments[2].color == CombatMetronome.SV.Progressbar.channelColor then
								self.Progressbar.bar.segments[2].color = CombatMetronome.SV.Progressbar.progressColor
								-- d("Turning back to Progress Color")
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
			if CombatMetronome.SV.Progressbar.showSpell and ability.delay > 0 and timeRemaining >= 0 and not ability.heavy then
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
			if CombatMetronome.SV.Progressbar.showTimeRemaining and ability.delay > 0 and timeRemaining >= 0 and not ability.heavy then
				self.Progressbar.timeLabel:SetText(string.format("%.1fs", timeRemaining))
				self.Progressbar.timeLabel:SetHidden(false)
			else
				self.Progressbar.timeLabel:SetHidden(true)
			end
			--------------------
			---- Interrupts ----							-- check for interrupts by dodge, barswap or block
			--------------------
			if not Util.Ability.Tracker.rollDodgeFinished and CombatMetronome.SV.Progressbar.trackGCD then
				self:OnCDStop()
				-- d("dodge should be interrupting now")
				if CombatMetronome.SV.Progressbar.showSpell then
					self.Progressbar.spellLabel:SetHidden(false)
					self.Progressbar.spellIcon:SetHidden(false)
					self.Progressbar.spellIconBorder:SetHidden(false)
					self.Progressbar.spellIcon:SetTexture("/esoui/art/icons/ability_rogue_035.dds")
					self.Progressbar.spellLabel:SetText("Dodgeroll")
				else
					self.Progressbar.spellLabel:SetHidden(true)
					self.Progressbar.spellIcon:SetHidden(true)
					self.Progressbar.spellIconBorder:SetHidden(true)
				end
				if CombatMetronome.SV.Progressbar.showTimeRemaining then
					self.Progressbar.timeLabel:SetHidden(false)
					self.Progressbar.timeLabel:SetText(string.format("%.1fs", gcdProgress))
				else
					self.Progressbar.timeLabel:SetHidden(true)
				end
				self.Progressbar.bar.segments[1].progress = (CombatMetronome.SV.Progressbar.showPingOnGCD and latency/1000) or 0
				self.Progressbar.bar.segments[2].progress = gcdProgress
				if gcdProgress == 0 then
					self:OnCDStop()
				else
					self:HideBar(false)
					self.Progressbar.bar.backgroundTexture:SetWidth(gcdProgress*CombatMetronome.SV.Progressbar.width)
				end
				self.Progressbar.bar:Update()
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
			end
		else
			self:OnCDStop()
			self.Progressbar.bar:Update()
		end
		-- self.lastBlockStatus = IsBlockActive()
	end
end