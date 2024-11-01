local LAM = LibAddonMenu2
local Util = DariansUtilities
CombatMetronome.SV = CombatMetronome.SV or {}
-- local healthColor = {}

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

        if showResources and CombatMetronome.SV.Resources.showStamina then
            local stam, _, maxStam = GetUnitPower("player", POWERTYPE_STAMINA)
            self.Resources.stamLabel:SetText(stam == maxStam and "100%" or string.format("%i%%", 100 * stam / maxStam))
            self.Resources.stamLabel:SetHidden(false)
        else
            self.Resources.stamLabel:SetHidden(true)
        end
        
        if showResources and CombatMetronome.SV.Resources.showMagicka then
            local mag, _, maxMag = GetUnitPower("player", POWERTYPE_MAGICKA)
            self.Resources.magLabel:SetText(mag == maxMag and "100%" or string.format("%i%%", 100 * mag / maxMag))
            self.Resources.magLabel:SetHidden(false)
        else
            self.Resources.magLabel:SetHidden(true)
        end

        local hp, _, maxHp = GetUnitPower("reticleover", POWERTYPE_HEALTH)
        if showResources and CombatMetronome.SV.Resources.showHealth and hp > 0 then
            local showAbsolute = not self.inCombat or hp == maxHp

            if 100 * (hp / maxHp) < CombatMetronome.SV.Resources.hpHighlightThreshold then
                self.Resources.hpLabel:SetColor(unpack(CombatMetronome.SV.Resources.healthColor))
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
    end
end
