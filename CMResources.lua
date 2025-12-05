local LAM = LibAddonMenu2
local Util = DariansUtilities
CombatMetronome.SV = CombatMetronome.SV or {}
-- local healthColor = {}
local coralThreshold, mkThreshold, bahseiThreshold = 50, 50, 50

function CombatMetronome:UpdateLabels()
    
    ------------------------
	---- Sample Section ----
	------------------------

   if self.showSampleResources then
        if CombatMetronome.SV.Resources.showUltimate then
            self.Resources.ultLabel:SetText("171")
            self.Resources.ultLabel:SetHidden(false)
        else
            self.Resources.ultLabel:SetHidden(true)
        end
        if CombatMetronome.SV.Resources.showStamina then
            self.Resources.stamLabel:SetText("62%")
            self.Resources.stamLabel:SetHidden(false)
        else
            self.Resources.stamLabel:SetHidden(true)
        end
        if CombatMetronome.SV.Resources.showMagicka then
            self.Resources.magLabel:SetText("75%")
            self.Resources.magLabel:SetHidden(false)
        else
            self.Resources.magLabel:SetHidden(true)
        end
        if CombatMetronome.SV.Resources.showHealth then
            self.Resources.hpLabel:SetText("51%")
            self.Resources.hpLabel:SetHidden(false)
        else
            self.Resources.hpLabel:SetHidden(true)
        end
        if not CombatMetronome.SV.Resources.unlockExecuteReminder then
            self.Resources.executeLabel:SetHidden(false)
        else
            self.Resources.executeLabel:SetHidden(true)
        end
        
	-------------------------
	---- Actual Updating ----
	-------------------------
    
    else
        local time = GetFrameTimeMilliseconds()
        -- healthColor = CombatMetronome.SV.Resources.healthColor
        
        local showResources = Util.Targeting.isUnitValidCombatTarget("reticleover", CombatMetronome.SV.Resources.showResourcesForGuard)
                              or IsUnitInCombat("player")
                              or self.force
                              or CombatMetronome.SV.Resources.showResources

        if showResources and CombatMetronome.SV.Resources.showUltimate then        
            local ult = GetUnitPower("player", POWERTYPE_ULTIMATE)
            self.Resources.ultLabel:SetText(ult)
            self.Resources.ultLabel:SetHidden(false)
        else
            self.Resources.ultLabel:SetHidden(true)
        end
        
        local coral = CombatMetronome.SV.Resources.coralBahsei and CombatMetronome.Resources.coralActive
        local mk = CombatMetronome.SV.Resources.coralBahsei and CombatMetronome.Resources.mkActive
        local bahsei = CombatMetronome.SV.Resources.coralBahsei and CombatMetronome.Resources.bahseiActive

        -- if showResources and (CombatMetronome.SV.Resources.showStamina or (CombatMetronome.SV.Resources.coralBahsei and (CombatMetronome.Resources.coralActive or CombatMetronome.Resources.mkActive))) then
        if showResources and (CombatMetronome.SV.Resources.showStamina or coral or mk) then
            local stam, _, maxStam = GetUnitPower("player", POWERTYPE_STAMINA)
            local percentage = 100 * stam / maxStam
            local threshold = math.max((CombatMetronome.SV.Resources.highlightStam and CombatMetronome.SV.Resources.stamHighlightThreshold) or 0, (coral and coralThreshold) or 0, (mk and mkThreshold) or 0)
            
            if threshold ~= 0 and percentage < threshold then
                -- self.Resources.stamLabel:SetColor(unpack(CombatMetronome.SV.Resources.stamColor))
                -- self.Resources.stamLabel:SetAnchor(CENTER, GuiRoot, CENTER, 0, 50)
                -- self.Resources.stamLabel:SetFont(Util.Text.getFontString(CombatMetronome.SV.Resources.labelFont, (3*CombatMetronome.SV.Resources.stamSize/2), CombatMetronome.SV.Resources.fontStyle))

                local PERIOD = 1000

                local mix = (1 + math.sin(time * math.pi * 2 / PERIOD)) / 2
                local color = Util.Vectors.mix(CombatMetronome.SV.Resources.stamColor, CombatMetronome.SV.Resources.stamHighligtColor, mix)

                self.Resources.stamLabel:SetColor(unpack(color))
            else
                self.Resources.stamLabel:SetColor(unpack(CombatMetronome.SV.Resources.stamColor))
                -- self.Resources.stamLabel:SetAnchor(BOTTOMRIGHT, self.frame.body, TOPRIGHT, 0, 0)
                -- self.Resources.stamLabel:SetFont(Util.Text.getFontString(CombatMetronome.SV.Resources.labelFont, CombatMetronome.SV.Resources.stamSize, CombatMetronome.SV.Resources.fontStyle))
            end
            
            self.Resources.stamLabel:SetText(stam == maxStam and "100%" or string.format("%i%%", percentage))
            self.Resources.stamLabel:SetHidden(false)
        else
            self.Resources.stamLabel:SetHidden(true)
        end
        
        if showResources and (CombatMetronome.SV.Resources.showMagicka or bahsei) then
            local mag, _, maxMag = GetUnitPower("player", POWERTYPE_MAGICKA)
            local percentage = 100 * mag / maxMag
            local threshold = math.max((CombatMetronome.SV.Resources.highlightMag and CombatMetronome.SV.Resources.magHighlightThreshold) or 0, (bahsei and bahseiThreshold) or 0)
            
            if threshold ~= 0 and percentage < threshold then
                -- self.Resources.magLabel:SetColor(unpack(CombatMetronome.SV.Resources.stamColor))
                -- self.Resources.magLabel:SetAnchor(CENTER, GuiRoot, CENTER, 0, 50)
                -- self.Resources.magLabel:SetFont(Util.Text.getFontString(CombatMetronome.SV.Resources.labelFont, (3*CombatMetronome.SV.Resources.magSize/2), CombatMetronome.SV.Resources.fontStyle))

                local PERIOD = 1000

                local mix = (1 + math.sin(time * math.pi * 2 / PERIOD)) / 2
                local color = Util.Vectors.mix(CombatMetronome.SV.Resources.magColor, CombatMetronome.SV.Resources.magHighligtColor, mix)

                self.Resources.magLabel:SetColor(unpack(color))
            else
                self.Resources.magLabel:SetColor(unpack(CombatMetronome.SV.Resources.magColor))
                -- self.Resources.magLabel:SetAnchor(BOTTOMRIGHT, self.frame.body, TOPRIGHT, 0, 0)
                -- self.Resources.magLabel:SetFont(Util.Text.getFontString(CombatMetronome.SV.Resources.labelFont, CombatMetronome.SV.Resources.magSize, CombatMetronome.SV.Resources.fontStyle))
            end
            
            self.Resources.magLabel:SetText(mag == maxMag and "100%" or string.format("%i%%", percentage))
            self.Resources.magLabel:SetHidden(false)
        else
            self.Resources.magLabel:SetHidden(true)
        end

        local hp, _, maxHp = GetUnitPower("reticleover", POWERTYPE_HEALTH)
        if showResources and CombatMetronome.SV.Resources.showHealth and hp > 0 then
            local showAbsolute = not self.inCombat or hp == maxHp

            if 100 * (hp / maxHp) < CombatMetronome.SV.Resources.hpHighlightThreshold then
                -- self.Resources.hpLabel:SetColor(unpack(CombatMetronome.SV.Resources.healthColor))
                -- self.Resources.hpLabel:SetAnchor(CENTER, GuiRoot, CENTER, 0, 50)
                self.Resources.hpLabel:SetFont(Util.Text.getFontString(CombatMetronome.SV.Resources.labelFont, (3*CombatMetronome.SV.Resources.healthSize/2), CombatMetronome.SV.Resources.fontStyle))

                local PERIOD = 1000

                local mix = (1 + math.sin(time * math.pi * 2 / PERIOD)) / 2
                local color = Util.Vectors.mix(CombatMetronome.SV.Resources.healthColor, CombatMetronome.SV.Resources.healthHighligtColor, mix)

                self.Resources.hpLabel:SetColor(unpack(color))

            else
                self.Resources.hpLabel:SetColor(unpack(CombatMetronome.SV.Resources.healthColor))
                -- self.Resources.hpLabel:SetAnchor(BOTTOMRIGHT, self.frame.body, TOPRIGHT, 0, 0)
                self.Resources.hpLabel:SetFont(Util.Text.getFontString(CombatMetronome.SV.Resources.labelFont, CombatMetronome.SV.Resources.healthSize, CombatMetronome.SV.Resources.fontStyle))
            end

            self.Resources.hpLabel:SetText((showAbsolute or self.force)
                and Util.Text.formatNumberCompact(hp)
                or  string.format("%i%%", 100 * hp / maxHp)
            )
            self.Resources.hpLabel:SetHidden(false)
        else
            self.Resources.hpLabel:SetHidden(true)
        end
        if not CombatMetronome.SV.Resources.unlockExecuteReminder and CombatMetronome.Resources.executeThreshold then
            if not IsUnitDead("reticleover") and showResources and CombatMetronome.SV.Resources.showExecuteReminder and hp~=1 and 100 * (hp / maxHp) <= CombatMetronome.Resources.executeThreshold and CombatMetronome.Resources.executeThreshold ~= 0 then
                self.Resources.executeLabel:SetHidden(false)
            else
                self.Resources.executeLabel:SetHidden(true)
            end
        end
    end
end