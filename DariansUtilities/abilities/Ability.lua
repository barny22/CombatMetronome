-- local Util = DAL:Ext("DariansUtilities")
local Util = DariansUtilities
Util.Ability = Util.Ability or { }
Util.Stacks = Util.Stacks or {}
Util.Text = Util.Text or {}
local Ability = Util.Ability
Ability.cache = { }
Ability.nameCache = { }
-- Util.language = GetCVar("Language.2")

local invalidLocation = {
    displayName = "Invalid location",
    icon = "/esoui/art/icons/icon_missing.dds",
    clearSynergy = false,
}

-- local effectFaded = {
    -- displayName = "Effect faded",
    -- icon = "/esoui/art/icons/servicemappins/servicepin_transmute.dds",
    -- clearSynergy = false,
-- }

local targetDied = {
    displayName = "Target dead",
    icon = "/esoui/art/targetmarkers/gamepad/target_white_skull.dds",
    clearSynergy = false,
}

local silenced = {
    displayName = "Silenced",
    icon = "/esoui/art/icons/ability_debuff_silence.dds",
    clearSynergy = false,
}

local immune = {
    displayName = "Target immune",
    icon = "/esoui/art/icons/death_recap_void_dot_heavy.dds", --/esoui/art/icons/death_recap_necro_dot_heavy2.dds
    clearSynergy = false,
}

local GRACE_PERIOD = 500

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

local jesusBeam = {
    [63029] = true,
    [63044] = true,
    [63046] = true,
}

-- local carverId = {
    -- ["mag"] = 183122,
    -- ["stam"] = 193397,
-- }
-- local CARVER_DELAY_PLACEHOLDER = 4500

local mendWoundsIds = {
        [107579]=true,[107583]=true,[107629]=true,[107630]=true,[107636]=true,[107637]=true,[107638]=true,[114990]=true,[114991]=true,[114992]=true,[118617]=true,[118638]=true,[118645]=true
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
    [103665]=true, [103492]=true, [103652]=true
}

-- local function IsMeditate(cacheId)
    -- for _, id in ipairs(meditateIds) do
        -- if id == cacheId then
            -- return true
        -- end
    -- end
    -- return false
-- end

-- local function AbilityInList(cacheId, list)
    -- for _, id in ipairs(list) do
        -- if id == cacheId then
            -- return true
        -- end
    -- end
    -- return false
-- end

local SlotNumbers = {3,4,5,6,7,8}

local log = Util.log

function Ability:ForId(id)
    local o = self.cache[id]
    if (o) then 
        -- CombatMetronome.debug:Print(" Ability "..o.name.." is cached for id, "..id)
        -- o.slot = slot or o.slot
        -- o.hotbar = GetActiveHotbarCategory()
        return o 
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
    o.name = Util.Text.CropZOSString(GetAbilityName(id), "ability")
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
    
    o.isMendWounds = mendWoundsIds[id] or false
    o.isMeditate = meditateIds[id] or false
    if o.isMeditate then o.delay = 1000 end
    
    o.checkForDeadTarget = ((o.enemy or o.ally) and duration > 1000) or (o.isMendWounds)
    
    o.heavy = o.id == GetSlotBoundId(2) and not o.isMendWounds
    o.light = o.id == GetSlotBoundId(1) and not o.isMendWounds
    
    -- if o.heavy then o.delay = 1500 end

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

function Ability:UpdateScribedSkills()
    for i = 1, 12 do
        local abilityId = GetAbilityIdForCraftedAbilityId(i)
        self.cache[abilityId] = nil
        Ability:ForId(abilityId)
    end
end

-- -------- --
-- Tracking --
-- -------- --

-- HasTargetFailure(slotIndex) --> true if cannot use ability on target (or no target)

Ability.Tracker = Ability.Tracker or { }
Ability.Tracker.name = "Util.Ability.Tracker"
-- Ability.Tracker.GCD = {
    -- ["progress"] = 0,
    -- ["duration"] = 0,
    -- ["remaining"] = 0,
-- }
-- local GCD = Ability.Tracker.GCD

local EVENT_RECORD_DELAY = 10
local EVENT_FORCE_WAIT = 100
local DISMOUNT_PERIOD = 300
local SHEATHING_PERIOD = 800
-- local SWAP_PERIOD = 500

function Ability.Tracker:Start()
    if self.started then return end

    --CombatMetronome.debug:Print("Ability Tracker Started!")

    self.started = true
    self.lastAbilityFinished = 0

    self.log = false
    self.class = Class[GetUnitClassId("player")]
    self.cdTriggerTime = 0
    self.lastMounted = 0
    self.weaponLastSheathed = 0
    -- self.weaponSwap = 0
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
    EVENT_MANAGER:RegisterForEvent(self.name.."PlayerDead", EVENT_PLAYER_DEAD, function()
        self:CancelCurrentEvent("Player dead")
        self:CancelEvent("Player dead")
    end)
    
    EVENT_MANAGER:RegisterForEvent(self.name.."IncomingCombatEvent", EVENT_COMBAT_EVENT, function(...)
        self:HandleIncomingCombatEvent(...) 
    end)
    EVENT_MANAGER:AddFilterForEvent(self.name.."IncomingCombatEvent", EVENT_COMBAT_EVENT, REGISTER_FILTER_TARGET_COMBAT_UNIT_TYPE, COMBAT_UNIT_TYPE_PLAYER)
    
    EVENT_MANAGER:RegisterForEvent(self.name.."OutgoingCombatEvent", EVENT_COMBAT_EVENT, function(...)
        self:HandleOutgoingCombatEvent(...) 
    end)
    EVENT_MANAGER:AddFilterForEvent(self.name.."OutgoingCombatEvent", EVENT_COMBAT_EVENT, REGISTER_FILTER_SOURCE_COMBAT_UNIT_TYPE, COMBAT_UNIT_TYPE_PLAYER)
    
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
    EVENT_MANAGER:RegisterForEvent(self.name.."UpdateScribedSkills", EVENT_END_CRAFTING_STATION_INTERACT, function(_, craftType, _)
        if craftType == CRAFTING_TYPE_SCRIBING then Ability:UpdateScribedSkills() end
    end)
end

function Ability.Tracker:GCDCheck()
    local sR, sD, global
    local j = 1
    local cdInfo = {[1] = { ["sR"] = 0, ["sD"] = 0 }, [2] = { ["sR"] = 0, ["sD"] = 0 }}
    for i = 3, 7 do
        sR, sD, global, _ = GetSlotCooldownInfo(i)
        if j == 3 then break end
        if global then
            cdInfo[j] = { ["sR"] = sR, ["sD"] = sD }
            j = j+1
        end
    end

    if (cdInfo[1].sR > cdInfo[2].sR) or (cdInfo[1].sD > cdInfo[2].sD) then
        cdInfo[2].sR = cdInfo[1].sR
        cdInfo[2].sD = cdInfo[1].sD
    end
    
    local slotRemaining = cdInfo[2].sR
    local slotDuration = cdInfo[2].sD
    if slotDuration < 1 then slotDuration = 1 end
    -- local slotRemaining, slotDuration, global, _ = GetSlotCooldownInfo(3)
    -- local sR, sD, g, _ = GetSlotCooldownInfo(4)
    -- if not global then
        -- slotRemaining, slotDuration, _, _ = GetSlotCooldownInfo(5)
    -- elseif not g then
        -- sR, sD, _, _ = GetSlotCooldownInfo(5)
    -- end
    -- if (sR > slotRemaining) or ( sD > slotDuration ) then
        -- slotRemaining = sR
        -- slotDuration = sD
    -- end
    -- if slotDuration < 1 then
        -- slotDuration = 1
    -- end
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
    -- self.weaponSwap = time
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
    if CombatMetronome.currentEvent and CombatMetronome.currentEvent.ability.heavy then
        return true
    elseif (time >= DariansUtilities.Ability.Tracker.lastAbilityFinished and time >= CombatMetronome.gcdEvent.finished) then 
        return true
    end
    return false
end

local function RegisterJesusBeam(id)
    local t = DariansUtilities.Ability.Tracker
    if not t.jesusBeamRegistered then
        EVENT_MANAGER:RegisterForEvent(t.name.."HandleJesusBeam", EVENT_EFFECT_CHANGED, function(_,changeType, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _)
            if changeType == EFFECT_RESULT_FADED and t.currentEvent and t.currentEvent.ability.Id == id then t:CancelCurrentEvent("Jesus beam finished") end
        end)
        EVENT_MANAGER:AddFilterForEvent(t.name.."HandleJesusBeam", EVENT_EFFECT_CHANGED, REGISTER_FILTER_ABILITY_ID, id)
        EVENT_MANAGER:AddFilterForEvent(t.name.."HandleJesusBeam", EVENT_EFFECT_CHANGED, REGISTER_FILTER_SOURCE_COMBAT_UNIT_TYPE , COMBAT_UNIT_TYPE_PLAYER)
        t.jesusBeamRegistered = true
        t:PrintDebugNotes("abilityUsed", id, "Jesus beam tracker has been registered")
    end
end

local function UnregisterJesusBeam(id)
    local t = DariansUtilities.Ability.Tracker
    if t.jesusBeamRegistered then
        EVENT_MANAGER:UnregisterForEvent(t.name.."HandleJesusBeam")
        t.jesusBeamRegistered = true
        t:PrintDebugNotes("abilityUsed", id, "Jesus beam tracker hast been unregistered")
    end
end

function Ability.Tracker:Update()
    local time = GetFrameTimeMilliseconds()
    -- local gcdProgress, sR, sD
    -- if self.queuedEvent and self.queuedEvent.ability.heavy then
        -- sR, sD, _, _ = GetSlotCooldownInfo(2)
        -- CombatMetronome.debug:Print(string.format("Slot 2 remaining: %d, duration: %d", sR, sD))
    -- else
    local gcdProgress, sR, sD = Ability.Tracker:GCDCheck()
    -- end
    
    if (self.lastBlockStatus == false) and IsBlockActive() and self.currentEvent then
        self:CancelCurrentEvent("Blocked")
        self:CancelEvent("Blocked")
    end
    
    if sR > 0 and self.currentEvent and self.currentEvent.ability.heavy then self:CallbackCancelHeavy() end

    -- Fire off late events if no UPDATE_COOLDOWNS events
    if ((self.queuedEvent and self.queuedEvent.castDuringRollDodge and self.rollDodgeFinished) or self.queuedEvent) and not self.currentEvent and gcdProgress > (CombatMetronome.SV.debug.triggers and ((self.gcd - CombatMetronome.SV.debug.triggerTimer)/1000) or 0.9) and CanAbilityFire() then
        -- if self.queuedEvent.ability and time < self.queuedEvent.recorded + math.max(self.queuedEvent.ability.duration, 1000) + GRACE_PERIOD then 
            self.eventStart = time + sR - sD
            -- self.queuedEvent.start = time + sR - sD
            self:AbilityUsed("late")
            self.abilityTriggerCounters.late = self.abilityTriggerCounters.late + 1
        -- else
            -- self:CancelEvent("Not fired")
        -- end
    -- elseif (not self.eventStart and self.queuedEvent and self.queuedEvent.allowForce and not self.queuedEvent.castDuringRollDodge and not self.currentEvent) and CanAbilityFire() then
        -- if (time > self.queuedEvent.recorded) then
            -- _=self.log and CombatMetronome.debug:Print("Event force "..tostring(time - self.queuedEvent.recorded).."ms ago")
            -- self.eventStart = time + sR - sD
            -- self:AbilityUsed()
            -- self.abilityTriggerCounters.late = self.abilityTriggerCounters.late + 1
        -- end
    -- Fire off events if all the triggers failed
    -- elseif self.queuedEvent and gcdProgress > (CombatMetronome.SV.debug.triggers and ((self.gcd - CombatMetronome.SV.debug.triggerTimer)/1000) or 0.92) and not self.currentEvent and CanAbilityFire() then
        -- if not (self.queuedEvent.recorded + math.max(self.queuedEvent.ability.delay,self.gcd) > time) then
            -- self.eventStart = time + sR - sD
            -- Ability.Tracker:AbilityUsed()
            -- if CanAbilityFire() then self.abilityTriggerCounters.extra = self.abilityTriggerCounters.extra + 1 end
        -- end
    end
    
    -- delete queued Events, if they weren't fired and also shouldn't be
    if not self.currentEvent and self.queuedEvent and math.max(self.queuedEvent.recorded, self.weaponLastSheathed + SHEATHING_PERIOD, self.lastMounted + DISMOUNT_PERIOD) + math.max(self.queuedEvent.ability.delay,1000) < time then
        -- if CombatMetronome.SV.denug.triggers then CombatMetronome.debug:Print("Canceled "..self.queuedEvent.ability.name) end
        self:CancelEvent("Event over")
    end

    if self.currentEvent and self.currentEvent.start then
        local event = self.currentEvent
        local ability = event.ability
        
        if time > event.start + math.max(ability.delay, sD) then
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
        -- if IsUnitDead("player") and self.currentEvent then
            -- self:CancelCurrentEvent("Player dead")
            -- self:CancelEvent("Player dead")
        -- end
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
        -- CombatMetronome.debug:Print(string.format("Slot 2 remaining: %d, duration: %d", sR, sD))
        gcdProgress = sR/sD
    else
        gcdProgress, sR, sD = self:GCDCheck()
        -- gcdProgress = GCD.progress
        -- sR = GCD.remaining
        -- sD = GCD.duration
    end

    local event = { }

    event.ability = ZO_ShallowTableCopy(ability)
        
    event.recorded = start
    -- event.needsCallLater = true
    if not self.rollDodgeFinished then event.castDuringRollDodge = true end
    -- event.recorded = time - EVENT_RECORD_DELAY

    local isMounted = time < self.lastMounted + DISMOUNT_PERIOD
    local weaponSheathed = time < self.weaponLastSheathed + SHEATHING_PERIOD
    -- local weaponSwap = time < self.weaponSwap + SWAP_PERIOD
    event.allowForce = ability.casted and ability.instant and not (isMounted or weaponSheathed or ability.ground)
    
    event.slot = slot
    event.hotbar = GetActiveHotbarCategory()

    self.queuedEvent = event
        
    if self.queuedEvent.ability.heavy then
        self.eventStart = start
        self:AbilityUsed("direct")
    elseif self.cdTriggerTime == start and gcdProgress > 0 and not self.currentEvent and self.rollDodgeFinished and not event.castDuringRollDodge then
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
        if self.queuedEvent and self.queuedEvent.ability and not self.queuedEvent.ability.heavy then
            self:PrintDebugNotes("eventCancel", self.queuedEvent.ability.id, string.format("Canceled queued ability '%s'. Reason: %s", self.queuedEvent.ability.name, reason))
        end
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
    local time = GetFrameTimeMilliseconds()

    if not self.queuedEvent then
        self:PrintDebugNotes("abilityUsed", nil, "What ability do you want me to use? There is none!")
        return
    elseif not CanAbilityFire() then
        self:PrintDebugNotes("abilityUsed", self.queuedEvent.ability.id, string.format("Ability '%s' triggered by '%s' but couldn't fire", self.queuedEvent.ability.name, trigger))
        return
    elseif not (self.queuedEvent.ability and time < self.queuedEvent.recorded + math.max(self.queuedEvent.ability.duration, 1000) + GRACE_PERIOD) then
        self:CancelEvent("Not fired")
        return
    end
    
    local gcdProgress, sR, sD = Ability.Tracker:GCDCheck()
    
    -- if gcdProgress > 0.92 or (self.queuedEvent and self.queuedEvent.ability.heavy) then
    
    -- if (self.queuedEvent and self.queuedEvent.ability.heavy) or self.abilityTrigger == time then
    
        -- killing old self.currentEvent since new event is coming
        if self.currentEvent or CombatMetronome.currentEvent then self:CancelCurrentEvent("Old event over, new event coming") end
        
        local event = self.queuedEvent
        event.start = self.eventStart
        
        -- CombatMetronome.debug:Print("Ability used "..event.ability.name.." - Id: "..event.ability.id)
        
        self:PrintDebugNotes("eventCancel", self.queuedEvent.ability.id, string.format("Queued ability '%s' is about to be fired. Setting queuedEvent 'nil'", self.queuedEvent.ability.name))
        self.queuedEvent = nil
        
        -- if event.ability.id == carverId.mag or event.ability.id == carverId.stam then
            -- local cruxes = Util.Stacks:GetCurrentNumStacksOnPlayer("Crux")
            -- event.ability.delay = CARVER_DELAY_PLACEHOLDER + (338 * cruxes)
            -- CombatMetronome.debug:Print(string.format("Fatecarver duration succesfully adjusted with %d crux(es)", cruxes))
        -- end
        
        self.gcd = sD
        self:PrintDebugNotes("abilityUsed", event.ability.id, string.format("New ability used '%s' - Trigger: %s - Remaining: %d", event.ability.name, trigger, sR))
        if jesusBeam[event.ability.id] then RegisterJesusBeam(event.ability.id) end
        self:CallbackAbilityUsed(event)

        if (event.ability.instant or event.ability.channeled) then
            self:CallbackAbilityActivated(event)
        end

        if (not event.ability.instant or event.ability.heavy) then
            -- CombatMetronome.debug:Print("Putting "..event.ability.name.." on current")
            self.currentEvent = event
        end
        
        self.lastAbilityFinished = event.start + math.max(event.ability.delay, self.gcd)
        
        if trigger == "Slot updated" or trigger == "CD updated" then
            self.abilityTriggerCounters.normal = self.abilityTriggerCounters.normal + 1
        end
    -- else
        -- self.abilityTrigger = time
    -- end
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
        local heavyID = self.currentEvent and self.currentEvent.ability and self.currentEvent.ability.id or nil
        self.currentEvent = nil
        self:PrintDebugNotes("currentEvent", heavyID, "Canceled heavy")
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

function Ability.Tracker:HandleSlotUpdated(e, slot)
    local time = GetFrameTimeMilliseconds()
    
    if not self.queuedEvent then return
    -- elseif (slot < 3) then return
    -- elseif self.queuedEvent.slot == slot and not self.queuedEvent.needsCallLater then 
        -- self:CancelEvent("Same slot updated")
        -- return
    -- elseif not self.queuedEvent.needsCallLater then return
    elseif self.currentEvent and self.currentEvent.slot == slot and self.eventStart == time then
        self:CancelCurrentEvent("Same slot updated")
    end

    -- local remaining, duration, global, t = GetSlotCooldownInfo(slot)
    local gcdProgress, sR, sD = self:GCDCheck()
    -- local time = GetFrameTimeMilliseconds()

    -- if (sD > 0 and sR > 0) then
        -- self.gcd = sD

        local oldStart = self.eventStart or 0
        if sR > 0 and sD > 0 then
            self.eventStart = time + sR - sD
        else
            self.eventStart = time
        end

        -- if (oldStart ~= self.eventStart) then
            -- _=self.log and d(""..time.." : Event start "..tostring(duration - remaining).."ms ago")
        -- end
        
        if self.eventStart >= oldStart then
            -- _=self.log and d(""..time.." : Moved queued "..self.queuedEvent.ability.name.." to current") 
            -- log("  Dispatching ", self.queuedEvent.ability.name)
            -- log("    oldStart = ", oldStart)
            -- log("    newStart = ", self.eventStart
            -- log("    current  = ", GetFrameTimeMilliseconds())
            self:PrintDebugNotes("abilityUsed", self.queuedEvent.ability.id, string.format("Ability '%s' triggered. Firing ability", self.queuedEvent.ability.name))
            self:AbilityUsed("slotUpdated")
            -- self:PrintDebugNotes("abilityUsed", self.queuedEvent.ability.id, string.format("%d: Ability '%s' triggered. callLater is being called in 1ms", time, self.queuedEvent.ability.name))
            -- self.queuedEvent.needsCallLater = false
            -- local event = self.queuedEvent
            -- zo_callLater(function()
                    -- if self.queuedEvent then
                        -- self:AbilityUsed("Slot updated")
                    -- elseif self.currentEvent and self.currentEvent.ability == event.ability then 
                        -- self:PrintDebugNotes("abilityUsed", event.ability.id, string.format("Queued event '%s' already is current event. No need to trigger.", event.ability.name))
                    -- else
                        -- self:PrintDebugNotes("abilityUsed", event.ability.id, string.format("Queued event '%s' seems to have been set 'nil'", event.ability.name))
                    -- end
                -- end,
                -- 1
            -- )
            -- self.abilityTriggerCounters.normal = self.abilityTriggerCounters.normal + 1
        end
    -- end
end

function Ability.Tracker:HandleCooldownsUpdated()
    self.cdTriggerTime = GetFrameTimeMilliseconds()
    
    local gcdProgress, sR, sD = self:GCDCheck()
    
    if sR > 0 and self.currentEvent and self.currentEvent.ability.heavy then self:CallbackCancelHeavy() end
    if self.lastAbilityFinished > self.cdTriggerTime then return end
    
    local gcdProgress, sR, sD = self:GCDCheck()
    
    if sR == 0 then return end
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
            self:AbilityUsed("CD updated")
            -- self.abilityTriggerCounters.normal = self.abilityTriggerCounters.normal + 1
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

--                                                 (a)bility | (d)amage | (p)ower | (t)arget | (s)ource | (h)it
--                                                 ------------------------------------------------------------
--                                                 1      2     3      4     5  	6      7      8      9
--                                                 10     11    12     13    14 	15     16     17     18
function Ability.Tracker:HandleIncomingCombatEvent(_,     res,  err,   aName, _, aSlotType, sName, sType, tName, 
                                                   tType, hVal, pType, dType, _, sUId, tUId,  aId, overflow)
    -- if Util.Targeting.isUnitPlayer(tName, tUId) and CombatMetronome and CombatMetronome.currentEvent then
    if CombatMetronome and CombatMetronome.currentEvent and not CombatMetronome.currentEvent.ability.allowForce and not sType == COMBAT_UNIT_TYPE_PLAYER then
        if (   res == ACTION_RESULT_KNOCKBACK
            or res == ACTION_RESULT_PACIFIED
            or res == ACTION_RESULT_STAGGERED
            or res == ACTION_RESULT_STUNNED
            or res == ACTION_RESULT_INTERRUPT)
            or res == ACTION_RESULT_FEARED
            or res == ACTION_RESULT_LEVITATED then
            -- and not (IsUnitInAir("player") and self.currentEvent) then
            self:CancelCurrentEvent("CC")
            self:CancelEvent("CC")
            return
        elseif res == ACTION_RESULT_EFFECT_FADED and self.currentEvent and self.currentEvent.ability.id == aId then
            self:CancelCurrentEvent("Effect faded, player is target")
        elseif Util.Targeting.isUnitPlayer(sName, sUId) then
            if res == ACTION_RESULT_SILENCED and CombatMetronome.currentEvent.ability.id == aId then
                -- local start = CombatMetronome.currentEvent.start
                self:CancelCurrentEvent("Silenced")
                -- CombatMetronome.currentEvent = {
                    -- ["start"] = start,
                    -- ["ability"] = Ability.cache.silenced,
                -- }
                -- CombatMetronome.currentEvent.ability.delay = self:GCDCheck()
                local _, remaining = self:GCDCheck()
                CombatMetronome.gcdEvent = ZO_ShallowTableCopy(silenced)
                CombatMetronome.gcdEvent.finished = time + remaining
                return
            -- elseif IsMeditate(aId) then
                -- if res == ACTION_RESULT_EFFECT_GAINED then
                    -- self.meditating = true
                -- elseif res == ACTION_RESULT_EFFECT_FADED then
                    -- self.meditating = false
                -- end
            end
        end
    end
end


--                                                 (a)bility | (d)amage | (p)ower | (t)arget | (s)ource | (h)it
--                                                 ------------------------------------------------------------
--                                                 1      2     3      4     5  	6      7      8      9
--                                                 10     11    12     13    14 	15     16     17     18
function Ability.Tracker:HandleOutgoingCombatEvent(_,     res,  err,   aName, _, aSlotType, sName, sType, tName, 
                                                   tType, hVal, pType, dType, _, sUId, tUId,  aId, overflow)
    local time = GetFrameTimeMilliseconds()        
    aName = Util.Text.CropZOSString(aName, "ability")

    -- log("Checking combat event")
    -- log("sName = ", sName, ", sUId = ", sUId)

    -- if (Util.Targeting.isUnitPlayer(sName, sUId)) then
        if res ~= ACTION_RESULT_EFFECT_FADED and CombatMetronome and CombatMetronome.currentEvent and CombatMetronome.currentEvent.ability.id == aId and CombatMetronome.currentEvent.ability.checkForDeadTarget and not CombatMetronome.currentEvent.target then
            CombatMetronome.currentEvent.target = tUId
            self:PrintDebugNotes("currentEvent", aId, string.format("Ability needs to check for dead target. Adding target unit id '%d' to currentEvent", tUId))
            -- CombatMetronome.debug:Print(string.format("Current tUId = %d", tUId))
        end
        
        if res == ACTION_RESULT_EFFECT_FADED and self.currentEvent and self.currentEvent.ability.id == aId then
            self:CancelCurrentEvent("Effect faded, player is source")
        -- elseif res == ACTION_RESULT_DIED_XP and CombatMetronome and CombatMetronome.currentEvent and CombatMetronome.currentEvent.ability.checkForDeadTarget and CombatMetronome.currentEvent.target == tUId then 
            -- self:CancelCurrentEvent("Target died, check completed, currentEvent canceled")
        elseif res == ACTION_RESULT_IMMUNE and CombatMetronome.currentEvent and CombatMetronome.currentEvent.ability.id == aId and CombatMetronome.currentEvent.ability.enemy then
            d(self.currentEvent)
            self:CancelCurrentEvent("Target immune")
            local _, remaining = self:GCDCheck()
            CombatMetronome.gcdEvent = ZO_ShallowTableCopy(immune)
            CombatMetronome.gcdEvent.finished = time + remaining
        -- end
        
        -- log("Source is player")

        -- if res == ACTION_RESULT_CANNOT_USE then
            -- CombatMetronome.debug:Print("Cannot use")
            -- self:CancelEvent("")
            -- return
        -- end
        -- CombatMetronome.debug:Print("Got an event that might kill currentEvent. Name: "..aName.." - Id: "..aId)
        
        
        elseif (res == ACTION_RESULT_DIED or res == ACTION_RESULT_DIED_XP or res == ACTION_RESULT_TARGET_DEAD) and CombatMetronome and CombatMetronome.currentEvent and CombatMetronome.currentEvent.ability.checkForDeadTarget and CombatMetronome.currentEvent.target == tUId then -- ACTION_RESULT_TARGET_DEAD
            self:PrintDebugNotes("currentEvent", aId, string.format("Target dead. Cancelling '%s' - Id: %d", aName, aId))
            local _, remaining = self:GCDCheck()
            if remaining > 0 then
                -- local start = CombatMetronome.currentEvent.start
                self:CancelCurrentEvent("Target died but GCD > 0")
                -- CombatMetronome.currentEvent = {
                    -- ["start"] = start,
                    -- ["ability"] = Ability.cache.targetDied,
                -- }
                -- CombatMetronome.currentEvent.ability.delay = remaining
                CombatMetronome.gcdEvent = ZO_ShallowTableCopy(targetDied)
                CombatMetronome.gcdEvent.finished = time + remaining
            else
                self:CancelEvent("Leave him alone, he is already dead")
                self:CancelCurrentEvent("Target died")
            end
            -- self.currentTarget = nil
            return
        -- elseif CombatMetronome and CombatMetronome.currentEvent and CombatMetronome.currentEvent.ability.checkForDeadTarget and CombatMetronome.currentEvent.ability.id == aId then
            -- self.currentTarget = {
                -- ["tId"] = tUId,
                -- ["aId"] = aId,
                -- ["eId"] = CombatMetronome.currentEvent.ability.id,
            -- }
            -- return
        elseif res == ACTION_RESULT_NO_LOCATION_FOUND and CombatMetronome and CombatMetronome.currentEvent and CombatMetronome.currentEvent.ability.id == aId then --ACTION_RESULT_NO_LOCATION_FOUND
            -- if CombatMetronome.SV.debug.currentEvent then CombatMetronome.debug:Print("No location for currentEvent. Name: "..aName.." - Id: "..aId) end
            -- local start = CombatMetronome.currentEvent.start
            self:CancelCurrentEvent("Invalid location")
            -- CombatMetronome.currentEvent = {
                -- ["start"] = start,
                -- ["ability"] = Ability.cache.invalidLocation,
            -- }
            -- CombatMetronome.currentEvent.ability.delay = self:GCDCheck()
            local _, remaining = self:GCDCheck()
            CombatMetronome.gcdEvent = ZO_ShallowTableCopy(invalidLocation)
            CombatMetronome.gcdEvent.finished = time + remaining
            
            return
                    -- rolldodge
        elseif aId == 28549 and res == ACTION_RESULT_EFFECT_GAINED then
            self.rollDodgeFinished = false
            local _, remaining = self:GCDCheck()
            zo_callLater(function() self.rollDodgeFinished = true end, remaining)
            self:CancelEvent("Rolldodge")
            if self.currentEvent then
                self:CancelCurrentEvent("Rolldodge")
            end
            return
        end

        if err then return end

        -- log("Not error!")

		if aSlotType == ACTION_SLOT_TYPE_HEAVY_ATTACK and (res == ACTION_RESULT_BEGIN or res == ACTION_RESULT_BEGIN_CHANNEL) and sType == COMBAT_UNIT_TYPE_PLAYER then
            -- CombatMetronome.debug:Print("Heavy ability is current combat event")
            if (self.currentEvent and self.currentEvent.ability.id == aId) then
                return
            elseif aId ~= GetSlotBoundId(2) then
                return
            end

            local heavy = Util.Ability:ForId(aId, false)
            -- _=self.log and CombatMetronome.debug:Print("New heavy ability - "..heavy.name)
            self:NewEvent(heavy, 2, time)
            -- if not heavy.channeled or heavy.channeled and heavy.channelTime <= 1500 then self:NewEvent(heavy, 2, time) end
            return
        elseif aSlotType == ACTION_SLOT_TYPE_LIGHT_ATTACK or aSlotType == ACTION_SLOT_TYPE_WEAPON_ATTACK--[[and res == 2240 and time ~= self.lastLightAttack ]]then
            if (res == ACTION_RESULT_EFFECT_GAINED or res == ACTION_RESULT_CRITICAL_DAMAGE or res == ACTION_RESULT_DAMAGE) and time ~= self.lastLightAttack then
                Ability.Tracker:CallbackLightAttackUsed(time)
                self.lastLightAttack = time
            end
            --CombatMetronome.debug:Print(res.." - "..hVal.." - "..overflow)
        end
    -- end
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
        self:PrintDebugNotes("triggers", nil, string.format("Normal triggers: %d", self.abilityTriggerCounters.normal))
        self:PrintDebugNotes("triggers", nil, string.format("Direct triggers: %d", self.abilityTriggerCounters.direct))
        self:PrintDebugNotes("triggers", nil, string.format("Late triggers: %d", self.abilityTriggerCounters.late))
        self:PrintDebugNotes("triggers", nil, "Combat ended")
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
        if self.currentEvent.ability and reason ~= "" then self:PrintDebugNotes("currentEvent", self.currentEvent.ability.id, string.format("Current event '%s' canceled by: %s", self.currentEvent.ability.name, reason)) end
        if jesusBeam[self.currentEvent.ability.id] then UnregisterJesusBeam(self.currentEvent.ability.id) end
        self.currentEvent = nil
        self.lastAbilityFinished = 0
        self.gcd = 1000
    end
        
    if self.CombatMetronome and CombatMetronome.currentEvent then
        self:PrintDebugNotes("currentEvent", CombatMetronome.currentEvent.ability.id, string.format("Current event '%s' canceled by ability.lua: %s", CombatMetronome.currentEvent.ability.name, reason))
        CombatMetronome.currentEvent = nil
        CombatMetronome:OnCDStop("")
        -- CombatMetronome.abilityFinished = GetFrameTimeMilliseconds()
        -- if CombatMetronome.SV.debug.currentEvent then CombatMetronome.debug:Print("Also reset CombatMetronome currentEvent") end
    end
end

function Ability.Tracker:PrintDebugNotes(debugType, abilityID, message)
    local debugs = CombatMetronome.SV.debug
    
    if not debugs[debugType] then return end
        
    local printDebug = false
    if not abilityID or abilityID == nil then printDebug = true
    elseif not next(debugs.abilityWhitelist.ids) then printDebug = true
    elseif debugs.abilityWhitelist.ids[abilityID] then printDebug = true
    end
    
    if printDebug then
        CombatMetronome.debug:Print(message)
    end
end