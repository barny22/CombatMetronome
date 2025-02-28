-- local Util = DAL:Ext("DariansUtilities")
local Util = DariansUtilities
Util.Ability = Util.Ability or { }
Util.Stacks = Util.Stacks or {}
Util.Text = Util.Text or {}
local Ability = Util.Ability
Ability.cache = { }
Ability.nameCache = { }
-- Util.language = GetCVar("Language.2")

Ability.cache.invalidLocation = {
    ["name"] = "Invalid location",
    ["icon"] = "/esoui/art/icons/icon_missing.dds",
    ["delay"] = 1000,
    ["casted"] = true,
}

Ability.cache.effectFaded = {
    ["name"] = "Effect faded",
    ["icon"] = "/esoui/art/icons/servicemappins/servicepin_transmute.dds",
    ["delay"] = 1000,
    ["casted"] = true,
}

Ability.cache.targetDied = {
    ["name"] = "Target dead",
    ["icon"] = "/esoui/art/targetmarkers/gamepad/target_white_skull.dds",
    ["delay"] = 1000,
    ["casted"] = true,
}

Ability.cache.silenced = {
    ["name"] = "Silenced",
    ["icon"] = "/esoui/art/icons/ability_debuff_silence.dds",
    ["delay"] = 1000,
    ["casted"] = true,
}

local Class = {
[1] = "DK",
[2] = "SORC",
[3] = "NB",
[4] = "DEN",
[5] = "CRO",
[6] = "PLAR",
[117] = "ARC",
}

local targetConstants = {
    ["ground"] = GetString(SI_ABILITY_TOOLTIP_TARGET_TYPE_GROUND),
    ["enemy"] = GetString(SI_TARGETTYPE0),
    ["ally"] = GetString(SI_TARGETTYPE1),
    ["self"] = GetString(SI_TARGETTYPE2)
}

local carverId = {
    ["mag"] = 183122,
    ["stam"] = 193397,
}
local CARVER_DELAY_PLACEHOLDER = 4500

local mendWoundsIds = {
        107579,107583,107629,107630,107636,107637,107638,114990,114991,114992,118617,118638,118645
    }

-- local function IsMendWounds(cacheId)
    -- for _, id in ipairs(mendWoundsIds) do
        -- if id == cacheId then
            -- return true
        -- end
    -- end
    -- return false
-- end

local meditateIds = {
    103665, 103492, 103652
}

-- local function IsMeditate(cacheId)
    -- for _, id in ipairs(meditateIds) do
        -- if id == cacheId then
            -- return true
        -- end
    -- end
    -- return false
-- end

local function AbilityInList(cacheId, list)
    for _, id in ipairs(list) do
        if id == cacheId then
            return true
        end
    end
    return false
end

local SlotNumbers = {3,4,5,6,7,8}

local log = Util.log

function Ability:ForId(id, isScribedAbility)
	if not isScribedAbility then
        local o = self.cache[id]
        if (o) then 
            -- CombatMetronome.debug:Print(" Ability "..o.name.." is cached for id, "..id)
            -- o.slot = slot or o.slot
            -- o.hotbar = GetActiveHotbarCategory()
            return o 
        end
    end

	o = { }
	setmetatable(o, self)
	self.__index = self

	-- local name, actionSlotType, passive
    -- for i = 1, 300000 do
        -- if (id == GetAbilityIdByIndex(i)) then
            -- name, _, _, actionSlotType, passive, _ = GetAbilityInfoByIndex(i)
            -- break
        -- end
    -- end

    o.id = id
    o.name = Util.Text.CropZOSString(GetAbilityName(id))
    local channeled, duration = GetAbilityCastInfo(id)
    o.channeled = channeled
    if channeled then
        o.channelTime = duration
        o.castTime = 0
    else
        o.castTime = duration
        o.channelTime = 0
    end
    -- end
    o.delay = duration or 0
    o.instant = not (o.castTime > 0 or (o.channeled and o.channelTime > 0))
    o.casted = not (o.instant or o.channeled)
    o.target = GetAbilityTargetDescription(id)
	o.icon = GetAbilityIcon(id)

    o.duration = GetAbilityDuration(id)
    o.buffType = GetAbilityBuffType(id)
    o.isTankAbility, 
    o.isHealerAbility, 
    o.isDamageAbility = GetAbilityRoles(id)

    o.ground = o.target == targetConstants.ground
    o.enemy = o.target == targetConstants.enemy
    o.ally = o.target == targetConstants.ally
    
    o.isMendWounds = AbilityInList(id, mendWoundsIds)
    o.isMeditate = AbilityInList(id, meditateIds)
    if o.isMeditate then o.delay = 1000 end
    
    o.checkForDeadTarget = ((o.enemy or o.ally) and duration > 1000) or (o.isMendWounds)
    
    o.heavy = o.id == GetSlotBoundId(2) and not o.isMendWounds
    o.light = o.id == GetSlotBoundId(1) and not o.isMendWounds
    
    if o.heavy then o.delay = 1500 end

    o.hasProgression,
    o.progressionIndex = GetAbilityProgressionXPInfoFromAbilityId(id)

    if o.hasProgression then
        o.baseName,
        o.morph,
        o.rank = GetAbilityProgressionInfo(o.progressionIndex)

        o.baseId = GetAbilityProgressionAbilityId(o.progressionIndex, 0, 1)
    end

    if (o.name) then
        -- CombatMetronome.debug:Print(" Caching from id! slot = "..tostring(o.slot))
        self.nameCache[o.name] = o
    end
    
    self.cache[id] = o

    return o
end

-- -------- --
-- Tracking --
-- -------- --

-- HasTargetFailure(slotIndex) --> true if cannot use ability on target (or no target)

Ability.Tracker = Ability.Tracker or { }
Ability.Tracker.name = "Util.Ability.Tracker"
Ability.Tracker.GCD = {
    ["progress"] = 0,
    ["duration"] = 0,
    ["remaining"] = 0,
}
local GCD = Ability.Tracker.GCD

local EVENT_RECORD_DELAY = 10
local EVENT_FORCE_WAIT = 100
local DISMOUNT_PERIOD = 300
local SHEATHING_PERIOD = 800

function Ability.Tracker:Start()
    if self.started then return end

    --CombatMetronome.debug:Print("Ability Tracker Started!")

    self.started = true
    self.lastAbilityFinished = 0

    self.log = false
    self.adjustedGCD = 1000
    self.class = Class[GetUnitClassId("player")]
    self.cdTriggerTime = 0
    self.lastMounted = 0
    self.weaponLastSheathed = 0
    self.eventStart = 0
    self.lastLightAttack = 0
    self.rollDodgeFinished = true
    self.lastBlockStatus = false
    -- self.meditating = false
    -- self.heavyUsedDuringHeavy = false
    
    self.abilityTriggerCounters = {}
    self.abilityTriggerCounters.direct = 0
    self.abilityTriggerCounters.normal = 0
    self.abilityTriggerCounters.late = 0
    -- self.abilityTriggerCounters.extra = 0
    
    -- self.slotsUpdated = {}
    
    EVENT_MANAGER:RegisterForUpdate(self.name.."Update", 1000 / 30, function(...)
        self:Update()
    end)
    
    -- EVENT_MANAGER:RegisterForUpdate(self.name.."GCD", 10, function()
        -- GCD.progress, GCD.remaining, GCD.duration = self:GCDCheck()
    -- end)

    -- EVENT_MANAGER:RegisterForEvent(self.name.."SlotUpdated", EVENT_ACTION_SLOT_STATE_UPDATED, function(_, slot) 
        -- if slot > 2 and slot < 9 then self:HandleSlotUpdated(_, slot) end
    -- end)
    EVENT_MANAGER:RegisterForEvent(self.name.."SlotUsed", EVENT_ACTION_SLOT_ABILITY_USED, function(_, slot)
        if slot >1 and slot < 9 then self:HandleSlotUsed(_, slot) end
    end)
    EVENT_MANAGER:RegisterForEvent(self.name.."CombatEvent", EVENT_COMBAT_EVENT, function(...)
        self:HandleCombatEvent(...) 
    end)
    EVENT_MANAGER:RegisterForEvent(self.name.."MountedState", EVENT_MOUNTED_STATE_CHANGED, function(_, mounted)
        self.mountedState = mounted
        if not mounted then self.lastMounted = GetFrameTimeMilliseconds() end
    end)
    EVENT_MANAGER:RegisterForEvent(self.name.."CooldownsUpdated", EVENT_ACTION_UPDATE_COOLDOWNS, function()
        self:HandleCooldownsUpdated()
    end)
	-- EVENT_MANAGER:RegisterForEvent(self.name.."Meditate", EVENT_EFFECT_CHANGED, function(...)
        -- self:HandleMeditate(...)
	-- end)
	EVENT_MANAGER:RegisterForEvent(self.name.."BarSwap", EVENT_ACTION_SLOTS_ACTIVE_HOTBAR_UPDATED, function(...)
        self:HandleBarSwap(...)
    end)
    EVENT_MANAGER:RegisterForEvent(self.name.."CombatStateChange", EVENT_PLAYER_COMBAT_STATE, function(_, inCombat)
		Ability.Tracker:ResetDebugCount(inCombat)
    end)
    EVENT_MANAGER:RegisterForEvent(self.name.."WeaponLockChange", EVENT_WEAPON_PAIR_LOCK_CHANGED, function(_, locked)
		Ability.Tracker:HandleWeaponLockChange(locked)
    end)
end

function Ability.Tracker:GCDCheck()
    -- local slotRemaining, slotDuration, global
    -- local cdInfo = {}
    -- for i = 3, 7 do
        -- slotRemaining, slotDuration, global, _ = GetSlotCooldownInfo(i)
        -- if global then
            -- local o = {}
            -- o.sR = slotRemaining
            -- o.sD = slotDuration
            -- table.insert(cdInfo, o)
        -- end
        -- if #cdInfo == 2 then break end
    -- end

    -- if cdInfo[1].sR > cdInfo[2].sR or cdInfo[1].sD > cdInfo[2].sD then
        -- cdInfo[2].sR = cdInfo[1].sR
        -- cdInfo[2].sD = cdInfo[1].sD
    -- end
    
    -- slotRemaining = cdInfo[2].sR
    -- slotDuration = cdInfo[2].sD
    -- if slotDuration < 1 then slotDuration = 1 end
    local slotRemaining, slotDuration, global, _ = GetSlotCooldownInfo(3)
    local sR, sD, g, _ = GetSlotCooldownInfo(4)
    if not global then
        slotRemaining, slotDuration, _, _ = GetSlotCooldownInfo(5)
    elseif not g then
        sR, sD, _, _ = GetSlotCooldownInfo(5)
    end
    if (sR > slotRemaining) or ( sD > slotDuration ) then
        slotRemaining = sR
        slotDuration = sD
    end
    if slotDuration < 1 then
        slotDuration = 1
    end
    local gcdProgress = slotRemaining/slotDuration
    return gcdProgress, slotRemaining, slotDuration
end

-- function Ability.Tracker:HandleRollDodge(_,changeType,_,name,_,_,_,_,icon,_,_,_,statusEffectType,_,_,abilityId,sourceType)
    -- if sourceType == COMBAT_UNIT_TYPE_PLAYER and abilityId == 29721 and changeType == EFFECT_RESULT_UPDATED then			--- 69143 is DodgeFatigue
        -- self.rollDodgeFinished = false
        -- local remaining = GetSlotCooldownInfo(3)
        -- zo_callLater(function() self.rollDodgeFinished = true end, remaining)
        -- self:CancelEvent("Rolldodge")
        -- if self.currentEvent then
            -- self:CancelCurrentEvent("Rolldodge")
        -- end
    -- end
-- end

-- function Ability.Tracker:HandleMeditate(_,changeType,_,name,_,_,_,_,icon,_,_,_,statusEffectType,_,_,abilityId,sourceType)
    -- if IsMeditate(abilityId) then
        -- if changeType == EFFECT_RESULT_GAINED then
            -- self.meditating = true
        -- elseif changeType == EFFECT_RESULT_FADED then
            -- self.meditating = false
        -- end
    -- end
-- end

function Ability.Tracker:HandleBarSwap(_, barswap, _, _)
    if self.barswap == barswap then return end
    self.barswap = barswap == true
    if self.barswap and self.currentEvent and self.currentEvent.ability and self.currentEvent.ability.delay > 1000 then
        self:CancelCurrentEvent("Barswap")
        self.barswap = false
    end
    self:CancelEvent("Barswap")
end

local function CanAbilityFire()
    local time = GetFrameTimeMilliseconds()
    -- if DariansUtilities.Ability.Tracker.meditating then
        -- return false
    if time >= DariansUtilities.Ability.Tracker.lastAbilityFinished then 
        return true
    end
    return false
end

function Ability.Tracker:Update()
    local time = GetFrameTimeMilliseconds()
    local gcdProgress, sR, sD
    if self.queuedEvent and self.queuedEvent.ability.heavy then
        sR, sD, _, _ = GetSlotCooldownInfo(2)
    else
        gcdProgress, sR, sD = Ability.Tracker:GCDCheck()
    end
    self.adjustedGCD = 1000 - GetLatency()
    if (self.lastBlockStatus == false) and IsBlockActive() and self.currentEvent then
        self:CancelCurrentEvent("Blocked")
        self:CancelEvent("Blocked")
    end

    -- Fire off late events if no UPDATE_COOLDOWNS events
    if self.queuedEvent or (self.queuedEvent and self.queuedEvent.castDuringRollDodge and self.rollDodgeFinished) and not self.currentEvent and gcdProgress > (CombatMetronome.SV.debug.triggers and ((self.adjustedGCD - CombatMetronome.SV.debug.triggerTimer)/1000) or 0.9) and CanAbilityFire() then
        -- if time > self.queuedEvent.recorded then
            self.eventStart = time + sR - sD
            self:AbilityUsed("late")
            self.abilityTriggerCounters.late = self.abilityTriggerCounters.late + 1
        -- end
    -- elseif (not self.eventStart and self.queuedEvent and self.queuedEvent.allowForce and not self.queuedEvent.castDuringRollDodge and not self.currentEvent) and CanAbilityFire() then
        -- if (time > self.queuedEvent.recorded) then
            -- _=self.log and CombatMetronome.debug:Print("Event force "..tostring(time - self.queuedEvent.recorded).."ms ago")
            -- self.eventStart = time + sR - sD
            -- self:AbilityUsed()
            -- self.abilityTriggerCounters.late = self.abilityTriggerCounters.late + 1
        -- end
    -- Fire off events if all the triggers failed
    -- elseif self.queuedEvent and gcdProgress > (CombatMetronome.SV.debug.triggers and ((self.adjustedGCD - CombatMetronome.SV.debug.triggerTimer)/1000) or 0.92) and not self.currentEvent and CanAbilityFire() then
        -- if not (self.queuedEvent.recorded + math.max(self.queuedEvent.ability.delay,self.adjustedGCD) > time) then
            -- self.eventStart = time + sR - sD
            -- Ability.Tracker:AbilityUsed()
            -- if CanAbilityFire() then self.abilityTriggerCounters.extra = self.abilityTriggerCounters.extra + 1 end
        -- end
    end
    
    -- delete queued Events, if they weren't fired and also shouldn't be
    if not self.currentEvent and self.queuedEvent and math.max(self.queuedEvent.recorded, self.weaponLastSheathed + SHEATHING_PERIOD, self.lastMounted + DISMOUNT_PERIOD) + math.max(self.queuedEvent.ability.delay, self.adjustedGCD) < time then
        -- if CombatMetronome.SV.denug.triggers then CombatMetronome.debug:Print("Canceled "..self.queuedEvent.ability.name) end
        self:CancelEvent("Event over")
    end

    if (self.currentEvent and self.currentEvent.start) then
        local event = self.currentEvent
        local ability = event.ability
        
        if (time > event.start + math.max(ability.delay, sD)) then
            -- CombatMetronome.debug:Print("Event over!")
            -- self.eventStart = nil
            self:CancelCurrentEvent("Event over")

            if (event.channeled) then
                Ability.Tracker:CallbackAbilityCancelled(event)
            else
                Ability.Tracker:CallbackAbilityActivated(event)
            end
        end
        
        -- if gcdProgress == 0 and not self.currentEvent.ability.heavy then
            -- self.currentEvent = nil
            -- if self.CombatMetronome and CombatMetronome.currentEvent then
                -- CombatMetronome.currentEvent = nil
            -- end
        -- end
        if IsUnitDead("player") and self.currentEvent then
            self:CancelCurrentEvent("Player dead")
            self:CancelEvent("Player dead")
        end
    end
    
    -- reset for fatecarver delay
    -- if (self.currentEvent and not self.currentEvent.ability.id == carverId.mag and not self.currentEvent.ability.id == carverId.stam) or not self.currentEvent then
        -- if Ability.cache[carverId.mag] and Ability.cache[carverId.mag].delay > 4500 then
            -- Ability.cache[carverId.mag].delay = 4500
            -- CombatMetronome.debug:Print("Magicka atecarver delay reset")
        -- end
        -- if Ability.cache[carverId.stam] and Ability.cache[carverId.stam].delay > 4500 then
            -- Ability.cache[carverId.stam].delay = 4500
            -- CombatMetronome.debug:Print("Stamina fatecarver delay reset")
        -- end
    -- end
    
    if ArePlayerWeaponsSheathed() then
        self.weaponLastSheathed = time
    end
    self.lastBlockStatus = IsBlockActive()
    -- self.heavyUsedDuringHeavy = false
    
    if gcdProgress == 0 then self.lastAbilityFinished = 0 end
end

function Ability.Tracker:NewEvent(ability, slot, start)
    -- CombatMetronome.debug:Print("creating new event -"..ability.name)
    local time = GetFrameTimeMilliseconds()
    local gcdProgress, sR, sD
    if slot == 2 then
        sR, sD, _, _ = GetSlotCooldownInfo(2)
        gcdProgress = sR/sD
    else
        gcdProgress, sR, sD = self:GCDCheck()
        -- gcdProgress = GCD.progress
        -- sR = GCD.remaining
        -- sD = GCD.duration
    end

    local event = { }

    event.ability = ability
        
    event.recorded = start
    if not self.rollDodgeFinished then event.castDuringRollDodge = true end
    -- event.recorded = time - EVENT_RECORD_DELAY

    local isMounted = time < self.lastMounted + DISMOUNT_PERIOD
    local weaponSheathed = time < self.weaponLastSheathed + SHEATHING_PERIOD
    event.allowForce = ability.casted and ability.instant and not (isMounted or weaponSheathed or ability.ground)
    
    event.slot = slot
    event.hotbar = GetActiveHotbarCategory()

    self.queuedEvent = event
        
    if self.cdTriggerTime == start and gcdProgress > 0 and not self.currentEvent and self.rollDodgeFinished and not event.castDuringRollDodge then
        self.eventStart = start + sR - sD
        self:AbilityUsed("direct")
        self.abilityTriggerCounters.direct = self.abilityTriggerCounters.direct + 1
    end
    -- if CombatMetronome.SV.debug.abilityUsed then CombatMetronome.debug:Print("New event "..event.ability.name) end
    -- CombatMetronome.debug:Print("  Allow force = "..tostring(self.queuedEvent.allowForce))
end

function Ability.Tracker:CancelEvent(reason)
    -- self.eventStart = nil
    local time = GetFrameTimeMilliseconds()
    
    if self.queuedEvent and not self.queuedEvent.allowForce and self.lastAbilityFinished < time then
        if CombatMetronome.SV.debug.eventCancel and self.queuedEvent and self.queuedEvent.ability and not self.queuedEvent.ability.heavy then CombatMetronome.debug:Print("Canceled queued ability "..self.queuedEvent.ability.name..". Reason: "..reason) end
        self.queuedEvent = nil
    end

    if (self.currentEvent) then
        local ability = self.currentEvent.ability
        if (ability.heavy) then
            self:CallbackAbilityActivated(self.currentEvent)
        else
            self:CallbackAbilityCancelled(self.currentEvent)
        end
    end
    
    -- self.currentEvent = nil
end

function Ability.Tracker:AbilityUsed(trigger)

    if not CanAbilityFire() then 
        if CombatMetronome.SV.debug.abilityUsed then CombatMetronome.debug:Print("Couldn't fire ability") end
        return
    end
    
    local gcdProgress, sR, sD
    if self.queuedEvent and self.queuedEvent.ability.heavy then
        sR, sD, _, _ = GetSlotCooldownInfo(2)
        gcdProgress = sR/sD
    else
        gcdProgress, sR, sD = Ability.Tracker:GCDCheck()
    end
    
    if gcdProgress > 0.92 or (self.queuedEvent and self.queuedEvent.ability.heavy) then
    
        -- killing old self.currentEvent since new event is coming
        if self.currentEvent then self:CancelCurrentEvent("Old event over, new event coming") end
        
        local event = self.queuedEvent
        event.start = self.eventStart
        
        -- CombatMetronome.debug:Print("Ability used "..event.ability.name.." - Id: "..event.ability.id)
        
        self.queuedEvent = nil
        
        if event.ability.id == carverId.mag or event.ability.id == carverId.stam then
            local cruxes = Util.Stacks:GetCurrentNumCruxOnPlayer()
            event.ability.delay = CARVER_DELAY_PLACEHOLDER + (338 * cruxes)
            -- CombatMetronome.debug:Print(string.format("Fatecarver duration succesfully adjusted with %d crux(es)", cruxes))
        end
        
        self.gcd = sD
        if CombatMetronome.SV.debug.abilityUsed then CombatMetronome.debug:Print("New ability used "..event.ability.name.." - Trigger: "..trigger) end
        self:CallbackAbilityUsed(event)

        if (event.ability.instant or event.ability.channeled) then
            self:CallbackAbilityActivated(event)
        end

        if (not event.ability.instant or event.ability.heavy) then
            -- CombatMetronome.debug:Print("Putting "..event.ability.name.." on current")
            self.currentEvent = event
        end
        
        self.lastAbilityFinished = event.start + math.max(event.ability.delay, self.adjustedGCD)
    end
end

function Ability.Tracker:CallbackAbilityUsed(event)
    -- DAL:Log("EVENT - "..event.ability.name.." used!")
    -- for name, callback in pairs(self.callbacks[self.CALLBACK_ABILITY_USED]) do
    --     callback(event)
    -- end
    if self.CombatMetronome then self.CombatMetronome:HandleAbilityUsed(event) end 
end

function Ability.Tracker:CallbackAbilityActivated(event)
    -- DAL:Log("EVENT - "..event.ability.name.." activated!")
    -- for name, callback in pairs(self.callbacks[self.CALLBACK_ABILITY_ACTIVATED]) do
    --     callback(event)
    -- end
    if self.CombatAuras then self.CombatAuras:HandleAbilityActivated(event) end
end

function Ability.Tracker:CallbackLightAttackUsed(time)
    if self.CombatMetronome.LATracker then self.CombatMetronome.LATracker:HandleLightAttacks(time) end
end

function Ability.Tracker:CallbackCancelHeavy()
    -- if not (self.cdTriggerTime == self.heavyUsedDuringHeavy) then
        self.currentEvent = nil
        if CombatMetronome.SV.debug.currentEvent then CombatMetronome.debug:Print("Canceled heavy") end
        self.gcd = 0
        -- CombatMetronome.debug:Print("cancelling heavy")
        Ability.Tracker:CallbackAbilityUsed("cancel heavy")
    -- end
end

function Ability.Tracker:CallbackAbilityCancelled(event)
    -- DAL:Log("EVENT - "..event.ability.name.." ended!")
    -- for name, callback in pairs(self.callbacks[self.CALLBACK_ABILITY_CANCELLED]) do
    --     callback(event)
    -- end
end

function Ability.Tracker:HandleCooldownsUpdated()
    self.cdTriggerTime = GetFrameTimeMilliseconds()
    
    local gcdProgress, sR, sD = self:GCDCheck()
    -- gcdProgress = GCD.progress
    -- sR = GCD.remaining
    -- sD = GCD.duration
    self.gcd = sD
    -- local oldStart = self.eventStart or 0
    
    local heavySR = GetSlotCooldownInfo(2)
    if heavySR > 0 then
        self.heavyOnCooldown = true
    else
        self.heavyOnCooldown = false
    end
    
    if self.queuedEvent and self.rollDodgeFinished and not self.queuedEvent.castDuringRollDodge then
        self.eventStart = self.cdTriggerTime + sR - sD
        if self.eventStart + (CombatMetronome.SV.debug.triggers and CombatMetronome.SV.debug.triggerTimer or 170) >= self.cdTriggerTime then
            -- CombatMetronome.debug:Print("Firing "..self.queuedEvent.ability.name)
            self:AbilityUsed("normal")
            self.abilityTriggerCounters.normal = self.abilityTriggerCounters.normal + 1
        end
    end
end

function Ability.Tracker:HandleSlotUsed(_, slot)

    local time = GetFrameTimeMilliseconds()
    
    if slot == 2 and self.currentEvent and self.currentEvent.ability.heavy then
        local _,possibleCancelTime = GetAbilityCastInfo(GetSlotBoundId(2))
        -- self.heavyUsedDuringHeavy = time
        -- CombatMetronome.debug:Print("Heavy slot was used "..(time-self.currentEvent.start).."ms after heavy started")
        if self.currentEvent.start + possibleCancelTime > time and not self.heavyOnCooldown then
            self:CallbackCancelHeavy()
        end
        return
    elseif slot == 2 then
        return
    end

    local ability = {}
    local actionType = GetSlotType(slot)
    if actionType == ACTION_TYPE_CRAFTED_ABILITY then
        local isScribedAbility = true
        ability = Util.Ability:ForId(GetAbilityIdForCraftedAbilityId(GetSlotBoundId(slot)), isScribedAbility)
    else
        local isScribedAbility = false
        ability = Util.Ability:ForId(GetSlotBoundId(slot), isScribedAbility)
    end
    
    -- if ability.isMeditate then return end
        
    if self.queuedEvent then self:CancelEvent("Overwrite") end
    
    -- if slot == 2 then return end

    -- _=self.log and CombatMetronome.debug:Print(""..GetFrameTimeMilliseconds().." : New ability - "..ability.name)
    self:NewEvent(ability, slot, time)
    -- CombatMetronome.debug:Print("New Event "..ability.name)
end

--                                      (a)bility | (d)amage | (p)ower | (t)arget | (s)ource | (h)it
--                                      ------------------------------------------------------------
--                                         1      2     3      4     5  	6      7      8      9
--                                         10     11    12     13    14 	15     16     17     18
function Ability.Tracker:HandleCombatEvent(_,     res,  err,   aName, _, aSlotType, sName, sType, tName, 
                                           tType, hVal, pType, dType, _, sUId, tUId,  aId, overflow)
    if Util.Targeting.isUnitPlayer(tName, tUId) then
        if (   res == ACTION_RESULT_KNOCKBACK
            or res == ACTION_RESULT_PACIFIED
            or res == ACTION_RESULT_STAGGERED
            or res == ACTION_RESULT_STUNNED
            or res == ACTION_RESULT_INTERRUPT) then
            -- and not (IsUnitInAir("player") and self.currentEvent) then
            self:CancelCurrentEvent("CC")
            self:CancelEvent("CC")
            return
        elseif res == ACTION_RESULT_SILENCED and CombatMetronome and CombatMetronome.currentEvent and CombatMetronome.currentEvent.ability.id == aId then
            local start = CombatMetronome.currentEvent.start
            self:CancelCurrentEvent("Silenced")
            CombatMetronome.currentEvent = {
                ["start"] = start,
                ["ability"] = Ability.cache.silenced,
            }
            return
        -- elseif IsMeditate(aId) then
            -- if res == ACTION_RESULT_EFFECT_GAINED then
                -- self.meditating = true
            -- elseif res == ACTION_RESULT_EFFECT_FADED then
                -- self.meditating = false
            -- end
        end
    end
    
    local time = GetFrameTimeMilliseconds()
    
    --------------------------------
    -- not sure about this here.. --
    --------------------------------
    
    -- if self.currentEvent and self.currentEvent.ability.id == aId and self.currentEvent.ability.checkForDeadTarget and CombatMetronome.currentEvent.target == tUId and res == ACTION_RESULT_EFFECT_FADED then
        -- local remaining = self:GCDCheck()
        -- if remaining > 0 then
            -- local start = CombatMetronome.currentEvent.start
            -- self:CancelCurrentEvent("Effect faded but GCD > 0")
            -- if CombatMetronome then
                -- CombatMetronome.currentEvent = {
                    -- ["start"] = start,
                    -- ["ability"] = Ability.cache.effectFaded,
                -- }
            -- end
        -- else
            -- self:CancelEvent()
            -- self:CancelCurrentEvent("Effect faded")
        -- end
        -- if CombatMetronome.SV.debug.currentEvent then
            -- for i=3,7 do
                -- CombatMetronome.debug:Print(i..": "..GetSlotCooldownInfo(i))
            -- end
        -- end
        -- return
    -- end
    
    -----------------------------------------------------------------
    -- This does happen too often and in the wrong cases sometimes --
    -----------------------------------------------------------------
        
    aName = Util.Text.CropZOSString(aName)

    -- log("Checking combat event")
    -- log("sName = ", sName, ", sUId = ", sUId)

    if (Util.Targeting.isUnitPlayer(sName, sUId)) then
        if CombatMetronome and CombatMetronome.currentEvent and CombatMetronome.currentEvent.ability.id == aId and CombatMetronome.currentEvent.ability.checkForDeadTarget then
            CombatMetronome.currentEvent.target = tUId
        end
        
        -- log("Source is player")

        -- if res == ACTION_RESULT_CANNOT_USE then
            -- CombatMetronome.debug:Print("Cannot use")
            -- self:CancelEvent()
            -- return
        -- end
        -- CombatMetronome.debug:Print("Got an event that might kill currentEvent. Name: "..aName.." - Id: "..aId)
        if res == ACTION_RESULT_DIED and CombatMetronome and CombatMetronome.currentEvent and CombatMetronome.currentEvent.ability.checkForDeadTarget and CombatMetronome.currentEvent.target == tUId then -- ACTION_RESULT_TARGET_DEAD
            if CombatMetronome.SV.debug.currentEvent then CombatMetronome.debug:Print("Target dead. Cancelling: "..aName.." - Id: "..aId) end
            local remaining = self:GCDCheck()
            if remaining > 0 then
                local start = CombatMetronome.currentEvent.start
                self:CancelCurrentEvent("Target died but GCD > 0")
                if CombatMetronome then
                    CombatMetronome.currentEvent = {
                        ["start"] = start,
                        ["ability"] = Ability.cache.targetDied,
                    }
                end
            else
                self:CancelEvent()
                self:CancelCurrentEvent("Target died")
            end
            self.currentTarget = nil
            return
        -- elseif CombatMetronome and CombatMetronome.currentEvent and CombatMetronome.currentEvent.ability.checkForDeadTarget and CombatMetronome.currentEvent.ability.name == aName then
            -- self.currentTarget = {
                -- ["tId"] = tUId,
                -- ["aId"] = aId,
                -- ["eId"] = CombatMetronome.currentEvent.ability.id,
            -- }
            -- return
        elseif res == ACTION_RESULT_NO_LOCATION_FOUND and CombatMetronome and CombatMetronome.currentEvent and CombatMetronome.currentEvent.ability.id == aId then --ACTION_RESULT_NO_LOCATION_FOUND
            -- if CombatMetronome.SV.debug.currentEvent then CombatMetronome.debug:Print("No location for currentEvent. Name: "..aName.." - Id: "..aId) end
            local start = CombatMetronome.currentEvent.start
            self:CancelCurrentEvent("Invalid location")
            CombatMetronome.currentEvent = {
                ["start"] = start,
                ["ability"] = Ability.cache.invalidLocation,
            }
            return
                    -- rolldodge
        elseif aId == 28549 and res == ACTION_RESULT_EFFECT_GAINED then
            self.rollDodgeFinished = false
            local remaining = GetSlotCooldownInfo(3)
            zo_callLater(function() self.rollDodgeFinished = true end, remaining)
            self:CancelEvent("Rolldodge")
            if self.currentEvent then
                self:CancelCurrentEvent("Rolldodge")
            end
            return
        end

        if err then return end

        -- log("Not error!")

		if aSlotType == ACTION_SLOT_TYPE_HEAVY_ATTACK and (res == ACTION_RESULT_BEGIN or res == ACTION_RESULT_BEGIN_CHANNEL) then
            -- CombatMetronome.debug:Print("Heavy ability is current combat event")
            if (self.currentEvent and self.currentEvent.ability.id == aId) then
                return
            elseif aId ~= GetSlotBoundId(2) then
                return
            end

            local heavy = Util.Ability:ForId(aId, false)
            -- _=self.log and CombatMetronome.debug:Print("New heavy ability - "..heavy.name)
            self:NewEvent(heavy, 2, time)
            return
        end
        -- local lightId = GetSlotBoundId(1)
        if aSlotType == ACTION_SLOT_TYPE_LIGHT_ATTACK --[[and res == 2240 and time ~= self.lastLightAttack ]]then
            if res == ACTION_RESULT_EFFECT_GAINED and time ~= self.lastLightAttack then
                Ability.Tracker:CallbackLightAttackUsed(time)
            end
            --CombatMetronome.debug:Print(res.." - "..hVal.." - "..overflow)
        end
        self.lastLightAttack = time
    else
        return
    end
end

function Ability.Tracker:HandleWeaponLockChange(locked)
    if not locked and self.currentEvent and self.currentEvent.ability.casted and not self.currentEvent.ability.heavy and ((GetFrameTimeMilliseconds()-self.currentEvent.start) < self.currentEvent.ability.delay and self.currentEvent.start ~= GetFrameTimeMilliseconds()) then
        self:CancelCurrentEvent("Weapon lock change")
    end
end

------------------------
---- Debug Triggers ----
------------------------

function Ability.Tracker:ResetDebugCount(inCombat)
    if not inCombat and not self.debugCountReset then
        if CombatMetronome.SV.debug.triggers then
           CombatMetronome.debug:Print("Normal triggers: "..self.abilityTriggerCounters.normal)
           CombatMetronome.debug:Print("Direct triggers: "..self.abilityTriggerCounters.direct)
           CombatMetronome.debug:Print("Late triggers: "..self.abilityTriggerCounters.late)
           -- CombatMetronome.debug:Print("Extra triggers: "..self.abilityTriggerCounters.extra)
           CombatMetronome.debug:Print("Combat ended")
        end
        self.abilityTriggerCounters.late = 0
        self.abilityTriggerCounters.normal = 0
        self.abilityTriggerCounters.direct = 0
        -- self.abilityTriggerCounters.extra = 0
        self.debugCountReset = true
    elseif inCombat and self.debugCountReset then
        self.debugCountReset = false
    end
end

-----------------------------------
---- Debug/Cancel currentEvent ----
-----------------------------------

function Ability.Tracker:CancelCurrentEvent(reason)
    if self.currentEvent then
        if self.CombatMetronome and CombatMetronome.currentEvent then
            CombatMetronome:OnCDStop()
            -- CombatMetronome.abilityFinished = GetFrameTimeMilliseconds()
            -- if CombatMetronome.SV.debug.currentEvent then CombatMetronome.debug:Print("Also reset CombatMetronome currentEvent") end
        end
        self.currentEvent = nil
        self.lastAbilityFinished = 0
        self.gcd = 1000
    end
    if CombatMetronome.SV.debug.currentEvent --[[and (self.currentEvent.ability.id == carverId.mag or self.currentEvent.ability.id == carverId.stam)]] then CombatMetronome.debug:Print("Current event cancel: "..reason) end
end