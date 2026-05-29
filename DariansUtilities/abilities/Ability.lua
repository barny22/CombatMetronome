local Util = DariansUtilities
Util.Ability = Util.Ability or { }
Util.Stacks = Util.Stacks or {}
Util.Text = Util.Text or {}
local Ability = Util.Ability
Ability.cache = { }
Ability.nameCache = { }

local invalidLocation = {
    displayName = "Invalid location",
    icon = "/esoui/art/icons/icon_missing.dds",
    clearSynergy = false,
}

local effectFaded = {
    displayName = "Effect faded",
    icon = "/esoui/art/icons/servicemappins/servicepin_transmute.dds",
    clearSynergy = false,
}

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

local abilityOnCooldown = {
    displayName = "Error",
    icon = "/esoui/art/icons/icon_missing.dds",
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

local mendWoundsIds = {
        [107579]=true,[107583]=true,[107629]=true,[107630]=true,[107636]=true,[107637]=true,[107638]=true,[114990]=true,[114991]=true,[114992]=true,[118617]=true,[118638]=true,[118645]=true
    }

local meditateIds = {
    [103665]=true, [103492]=true, [103652]=true
}

local SlotNumbers = {3,4,5,6,7,8}

local log = Util.log

function Ability:ForId(id)
    local o = self.cache[id]
    if (o) then
        return o 
    end

	o = { }
	setmetatable(o, self)
	self.__index = self

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
    
    o.hasProgression,
    o.progressionIndex = GetAbilityProgressionXPInfoFromAbilityId(id)

    if o.hasProgression then
        o.baseName,
        o.morph,
        o.rank = GetAbilityProgressionInfo(o.progressionIndex)

        o.baseId = GetAbilityProgressionAbilityId(o.progressionIndex, 0, 1)
    end

    if (o.name) then
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

Ability.Tracker = Ability.Tracker or { }
Ability.Tracker.name = "Util.Ability.Tracker"

local EVENT_RECORD_DELAY = 10
local EVENT_FORCE_WAIT = 100
local DISMOUNT_PERIOD = 300
local SHEATHING_PERIOD = 800
-- local SWAP_PERIOD = 250

function Ability.Tracker:Start()
    if self.started then return end

    self.started = true
    self.lastAbilityFinished = 0

    self.log = false
    self.class = Class[GetUnitClassId("player")]
    self.cdTriggerTime = 0
    self.lastMounted = 0
    self.weaponLastSheathed = 0
    self.eventStart = 0
    self.lastLightAttack = 0
    self.rollDodgeFinished = 0
    self.lastBlockStatus = false
    
    self.abilityTriggerCounters = {}
    self.abilityTriggerCounters.direct = 0
    self.abilityTriggerCounters.normal = 0
    self.abilityTriggerCounters.late = 0
    
    EVENT_MANAGER:RegisterForUpdate(self.name.."Update", 1000 / 30, function(...)
        self:Update()
    end)
    
    -- EVENT_MANAGER:RegisterForEvent(self.name.."SlotUpdated", EVENT_ACTION_SLOT_STATE_UPDATED, function(_, slot) 
        -- if slot > 2 and slot < 9 then self:HandleSlotUpdated(_, slot) end
    -- end)
    EVENT_MANAGER:RegisterForEvent(self.name.."SlotUsed", EVENT_ACTION_SLOT_ABILITY_USED, function(_, slot)
        if slot >2 and slot < 9 then self:HandleSlotUsed(_, slot) end
    end)
    EVENT_MANAGER:RegisterForEvent(self.name.."PlayerDead", EVENT_PLAYER_DEAD, function()
        self:CancelCurrentEvent("Player dead")
        self:CancelEvent(GetFrameTimeMilliseconds(), "Player dead")
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
    -- local sR, sD, global
    -- local j = 1
    -- local cdInfo = {[1] = { sR = 0, sD = 0 }, [2] = { sR = 0, sD = 0 }}
    -- for i = 3, 7 do
        -- sR, sD, global, _ = GetSlotCooldownInfo(i)
        -- if j == 3 then break end
        -- if global then
            -- cdInfo[j] = { sR = sR, sD = sD }
            -- j = j+1
        -- end
    -- end

    -- if (cdInfo[1].sR > cdInfo[2].sR) or (cdInfo[1].sD > cdInfo[2].sD) then
        -- cdInfo[2].sR = cdInfo[1].sR
        -- cdInfo[2].sD = cdInfo[1].sD
    -- end
    
    -- local slotRemaining = cdInfo[2].sR
    -- local slotDuration = cdInfo[2].sD
    
    for i = 3, 8 do
        local slotRemaining, slotDuration, global = GetSlotCooldownInfo(i)
        
        if global then
            local gcdProgress = slotDuration > 0 and slotRemaining/slotDuration or 0
            return gcdProgress, slotRemaining, slotDuration
        end
    end
    return 0, 0, 0
end

function Ability.Tracker:HandleBarSwap(_, barswap, _, _)
    if self.barswap == barswap then return end
    self.barswap = barswap == true
    if self.barswap and self.currentEvent and self.currentEvent.ability and self.currentEvent.ability.delay > 1000 then
        self:CancelCurrentEvent("Barswap")
        self.barswap = false
    end
    self:CancelEvent(GetFrameTimeMilliseconds(), "Barswap")
end

local function CanAbilityFire(time)
    if CombatMetronome.currentEvent and CombatMetronome.currentEvent.ending <= time then
        Ability.Tracker:CancelCurrentEvent("Old event just finished.")
        return true
    elseif CombatMetronome.gcdEvent.clearSynergy then
        CombatMetronome.gcdEvent = { finished = 0 }
    end
    
    return Ability.Tracker.lastAbilityFinished <= time and CombatMetronome.gcdEvent.finished <= time
end

local function RegisterJesusBeam(id)
    local t = DariansUtilities.Ability.Tracker
    if not t.jesusBeamRegistered then
        EVENT_MANAGER:RegisterForEvent(t.name.."HandleJesusBeam", EVENT_EFFECT_CHANGED, function(_,changeType)
            if changeType == EFFECT_RESULT_FADED and t.currentEvent and t.currentEvent.ability.id == id and not t.skipNextEffectFaded then
                t:CancelCurrentEvent("Jesus beam finished")
            end
        end)
        EVENT_MANAGER:AddFilterForEvent(t.name.."HandleJesusBeam", EVENT_EFFECT_CHANGED, REGISTER_FILTER_ABILITY_ID, id)
        EVENT_MANAGER:AddFilterForEvent(t.name.."HandleJesusBeam", EVENT_EFFECT_CHANGED, REGISTER_FILTER_SOURCE_COMBAT_UNIT_TYPE , COMBAT_UNIT_TYPE_PLAYER)
        t.jesusBeamRegistered = true
        t:PrintDebugNotes("abilityUsed", id, "Jesus beam tracker has been registered")
    else
        t.skipNextEffectFaded = true
        t:PrintDebugNotes("abilityUsed", id, "Seems like like you casted a new beam. Will skip next effect faded")
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
    local gcdProgress, sR, sD = Ability.Tracker:GCDCheck()
    
    if (self.lastBlockStatus == false) and IsBlockActive() and self.currentEvent then
        self:CancelCurrentEvent("Blocked")
        self:CancelEvent(time, "Blocked")
    end
    
    -- Fire off late events if no UPDATE_COOLDOWNS events
    if ((self.queuedEvent and self.queuedEvent.castDuringRollDodge and self.rollDodgeFinished >= time) or self.queuedEvent) and not self.currentEvent and gcdProgress > (CombatMetronome.SV.debug.triggers and ((self.gcd - CombatMetronome.SV.debug.triggerTimer)/1000) or 0.9) and CanAbilityFire(time) then
        self.eventStart = time + sR - sD
        self:AbilityUsed("late")
        self.abilityTriggerCounters.late = self.abilityTriggerCounters.late + 1
    end
    
    -- delete queued Events, if they weren't fired and also shouldn't be
    if not self.currentEvent and self.queuedEvent and math.max(self.queuedEvent.recorded, self.weaponLastSheathed + SHEATHING_PERIOD, self.lastMounted + DISMOUNT_PERIOD) + math.max(self.queuedEvent.ability.delay,1000) < time then
        self:CancelEvent(time, "Event over")
    end
    
    if ArePlayerWeaponsSheathed() then
        self.weaponLastSheathed = time
    end
    self.lastBlockStatus = IsBlockActive()
end

function Ability.Tracker:NewEvent(ability, slot, start)
    local time = GetFrameTimeMilliseconds()
    
    local gcdProgress, sR, sD = self:GCDCheck()
    -- if slot == 2 then
        -- sR, sD, _, _ = GetSlotCooldownInfo(2)
        -- gcdProgress = sD > 0 and sR/sD or 0
    -- else
        -- gcdProgress, sR, sD = self:GCDCheck()
    -- end

    local event = { }

    event.ability = ZO_ShallowTableCopy(ability)
        
    event.recorded = start
    if self.rollDodgeFinished > time then event.castDuringRollDodge = true end

    local isMounted = time < self.lastMounted + DISMOUNT_PERIOD
    local weaponSheathed = time < self.weaponLastSheathed + SHEATHING_PERIOD
    event.allowForce = ability.instant and not (isMounted or weaponSheathed or ability.ground)
    
    event.slot = slot
    event.hotbar = GetActiveHotbarCategory()

    self.queuedEvent = event
        
    if self.queuedEvent.ability.heavy then
        self.eventStart = start
        self:AbilityUsed("direct")
    elseif self.cdTriggerTime == start and gcdProgress == 1 and self.rollDodgeFinished <= time and not event.castDuringRollDodge then
        if CombatMetronome.currentEvent then self:CancelCurrentEvent("Direct trigger detected") end
        self.eventStart = start
        self:AbilityUsed("direct")
        self.abilityTriggerCounters.direct = self.abilityTriggerCounters.direct + 1
    end
end

function Ability.Tracker:CancelEvent(time, reason)    
    if self.queuedEvent and not self.queuedEvent.allowForce and self.lastAbilityFinished <= time then
        if self.queuedEvent and self.queuedEvent.ability and not self.queuedEvent.ability.heavy then
            self:PrintDebugNotes("eventCancel", self.queuedEvent.ability.id, string.format("Canceled queued ability '%s'. Reason: %s", self.queuedEvent.ability.name, reason))
        end
        self.queuedEvent = nil
    end
end

function Ability.Tracker:AbilityUsed(trigger)
    
    local gcdProgress, sR, sD = Ability.Tracker:GCDCheck()
            
    local event = self.queuedEvent
    event.start = self.eventStart
    event.ending = self.eventStart + math.max(event.ability.delay, 1000)
    
    self:PrintDebugNotes("eventCancel", self.queuedEvent.ability.id, string.format("Queued ability '%s' is about to be fired. Setting queuedEvent 'nil'", self.queuedEvent.ability.name))
    self.queuedEvent = nil
    
    self.gcd = sD
    self:PrintDebugNotes("abilityUsed", event.ability.id, string.format("New ability used '%s' - Trigger: %s - Remaining: %d", event.ability.name, trigger, sR))
    if jesusBeam[event.ability.id] then RegisterJesusBeam(event.ability.id) end
    -- QueueClearCurrentEvent(event.start, math.max(sR, math.max(event.ability.delay, 1000)+sR-sD))
    self:CallbackAbilityUsed(event)

    if (event.ability.instant or event.ability.channeled) then
        self:CallbackAbilityActivated(event)
    end

    if (not event.ability.instant or event.ability.heavy) then
        self.currentEvent = event
    end
    
    self.lastAbilityFinished = event.ending
    
    if trigger == "Slot updated" or trigger == "CD updated" then
        self.abilityTriggerCounters.normal = self.abilityTriggerCounters.normal + 1
    end
end

function Ability.Tracker:CallbackAbilityUsed(event)
    if self.CombatMetronome then self.CombatMetronome:HandleAbilityUsed(event) end 
end

function Ability.Tracker:CallbackAbilityActivated(event)
    if self.CombatAuras then self.CombatAuras:HandleAbilityActivated(event) end
end

function Ability.Tracker:CallbackLightAttackUsed(time)
    if self.CombatMetronome.LATracker then self.CombatMetronome.LATracker:HandleLightAttacks(time) end
end

-- function Ability.Tracker:HandleSlotUpdated(e, slot)
    -- local time = GetFrameTimeMilliseconds()
    
    -- if self.lastLightAttack == time then return end
    
    -- if self.queuedEvent and self.queuedEvent.recorded == time and self.queuedEvent.slot == slot then
        -- self:CancelEvent(time, "Same slot updated")
    -- elseif CombatMetronome.currentEvent and CombatMetronome.currentEvent.slot == slot and CombatMetronome.currentEvent.recorded == time then
        -- self:CancelCurrentEvent("Same slot updated")
    -- end
    
    -- if not self.queuedEvent then return
    
    -- elseif self.currentEvent and self.currentEvent.slot == slot and self.eventStart == time then
        -- self:CancelCurrentEvent("Same slot updated")
    -- end
    
    -- local gcdProgress, sR, sD = self:GCDCheck()

    -- local oldStart = self.eventStart or 0
    -- if sR > 0 and sD > 0 then
        -- self.eventStart = time + sR - sD
    -- else
        -- self.eventStart = time
    -- end
    
    -- if self.eventStart >= oldStart then
        -- self:PrintDebugNotes("abilityUsed", self.queuedEvent.ability.id, string.format("Ability '%s' triggered. Firing ability", self.queuedEvent.ability.name))
        -- self:AbilityUsed("slotUpdated")
    -- end
-- end

function Ability.Tracker:HandleCooldownsUpdated()
    
    self.cdTriggerTime = GetFrameTimeMilliseconds()
    
    local gcdProgress, sR, sD = self:GCDCheck()
        
    if self.currentEvent and self.currentEvent.ability.heavy then
        if sR > 0 then
            self:CancelCurrentEvent("Heavy cancel - new GCD")
        else
            local hSR, hSD, global = GetSlotCooldownInfo(2)
            if not global and hSR == hSD then self:CancelCurrentEvent("Heavy cancel") end
        end
    end
    
    if not CanAbilityFire(self.cdTriggerTime) then return end
    
    if sR == 0 then return end
    self.gcd = sD
    
    -- local heavySR = GetSlotCooldownInfo(2)
    -- if heavySR > 0 then
        -- self.heavyOnCooldown = true
    -- else
        -- self.heavyOnCooldown = false
    -- end
    
    if self.queuedEvent and self.rollDodgeFinished <= self.cdTriggerTime and not self.queuedEvent.castDuringRollDodge then
        self.eventStart = self.cdTriggerTime + sR - sD
        if self.eventStart + (CombatMetronome.SV.debug.triggers and CombatMetronome.SV.debug.triggerTimer or GetLatency()) >= self.cdTriggerTime then
            self:AbilityUsed("CD updated")
        end
    end
end

function Ability.Tracker:HandleSlotUsed(_, slot)
    local ability = {}
    local actionType = GetSlotType(slot)
    if actionType == ACTION_TYPE_CRAFTED_ABILITY then
        local isScribedAbility = true
        ability = Util.Ability:ForId(GetAbilityIdForCraftedAbilityId(GetSlotBoundId(slot)), isScribedAbility)
    else
        local isScribedAbility = false
        ability = Util.Ability:ForId(GetSlotBoundId(slot), isScribedAbility)
    end
    
    local time = GetFrameTimeMilliseconds()
        
    if self.queuedEvent then self:CancelEvent(time, "Overwrite") end
    self:NewEvent(ability, slot, time)
end

--                                                 (a)bility | (d)amage | (p)ower | (t)arget | (s)ource | (h)it
--                                                 ------------------------------------------------------------
--                                                 1      2     3      4     5  	6      7      8      9
--                                                 10     11    12     13    14 	15     16     17     18
function Ability.Tracker:HandleIncomingCombatEvent(_,     res,  err,   aName, _, aSlotType, sName, sType, tName, 
                                                   tType, hVal, pType, dType, _, sUId, tUId,  aId, overflow)
    if CombatMetronome and CombatMetronome.currentEvent then
        local time = GetFrameTimeMilliseconds()
        if (   res == ACTION_RESULT_KNOCKBACK
            or res == ACTION_RESULT_PACIFIED
            or res == ACTION_RESULT_STAGGERED
            or res == ACTION_RESULT_STUNNED
            or res == ACTION_RESULT_INTERRUPT
            or res == ACTION_RESULT_FEARED
            or res == ACTION_RESULT_LEVITATED)
            and not sType == COMBAT_UNIT_TYPE_PLAYER and not CombatMetronome.currentEvent.allowForce then
            self:CancelCurrentEvent("CC")
            self:CancelEvent(time, "CC")
            return
        elseif res == ACTION_RESULT_EFFECT_FADED and self.currentEvent and self.currentEvent.ability.id == aId then
            self:CancelCurrentEvent("Effect faded, player is target")
        elseif sType == COMBAT_UNIT_TYPE_PLAYER and res == ACTION_RESULT_SILENCED and CombatMetronome.currentEvent.ability.id == aId then
            self:CancelCurrentEvent("Silenced")
            local _, remaining = self:GCDCheck()
            if remaining > 0 then
                CombatMetronome.gcdEvent = ZO_ShallowTableCopy(silenced)
                CombatMetronome.gcdEvent.finished = time + remaining
            end
            return
        end
    end
end


--                                                 (a)bility | (d)amage | (p)ower | (t)arget | (s)ource | (h)it
--                                                 ------------------------------------------------------------
--                                                 1      2     3      4     5  	6      7      8      9
--                                                 10     11    12     13    14 	15     16     17     18
function Ability.Tracker:HandleOutgoingCombatEvent(_,     res,  err,   aName, _, aSlotType, sName, sType, tName, 
                                                   tType, hVal, pType, dType, _, sUId, tUId,  aId, overflow)
    aName = Util.Text.CropZOSString(aName, "ability")
    local time = GetFrameTimeMilliseconds()
    if res ~= ACTION_RESULT_EFFECT_FADED and CombatMetronome and CombatMetronome.currentEvent and CombatMetronome.currentEvent.ability.id == aId and CombatMetronome.currentEvent.ability.checkForDeadTarget and not CombatMetronome.currentEvent.target then
        CombatMetronome.currentEvent.target = tUId
        self:PrintDebugNotes("currentEvent", aId, string.format("Ability needs to check for dead target. Adding target unit id '%d' to currentEvent", tUId))
    end
    
    if CombatMetronome.currentEvent and CombatMetronome.currentEvent.ability.id == aId and err and CombatMetronome.currentEvent.recorded + 100 > time and res == ACTION_RESULT_ABILITY_ON_COOLDOWN then
        self:CancelCurrentEvent("Error")
        local _, remaining = self:GCDCheck()
        if remaining > 0 then
            CombatMetronome.gcdEvent = ZO_ShallowTableCopy(abilityOnCooldown)
            CombatMetronome.gcdEvent.finished = time + remaining
        end        
        -- barnysDevTools.msg:Print(string.format("Got combat event regarding ability '%s' with an error and the following action result: '%d'", aName, res))
    elseif res == ACTION_RESULT_EFFECT_FADED and self.currentEvent and self.currentEvent.ability.id == aId then
        self:CancelCurrentEvent("Effect faded, player is source")
        local _, remaining = self:GCDCheck()
        if remaining > 0 then
            CombatMetronome.gcdEvent = ZO_ShallowTableCopy(effectFaded)
            CombatMetronome.gcdEvent.finished = time + remaining
        end
        
    elseif res == ACTION_RESULT_IMMUNE and CombatMetronome.currentEvent and CombatMetronome.currentEvent.ability.id == aId and CombatMetronome.currentEvent.ability.enemy then
        self:CancelCurrentEvent("Target immune")
        local _, remaining = self:GCDCheck()
        if remaining > 0 then
            CombatMetronome.gcdEvent = ZO_ShallowTableCopy(immune)
            CombatMetronome.gcdEvent.finished = time + remaining
        end
    
    elseif (res == ACTION_RESULT_DIED or res == ACTION_RESULT_DIED_XP or res == ACTION_RESULT_TARGET_DEAD) and CombatMetronome and CombatMetronome.currentEvent and CombatMetronome.currentEvent.ability.checkForDeadTarget and CombatMetronome.currentEvent.target == tUId then -- ACTION_RESULT_TARGET_DEAD
        self:PrintDebugNotes("currentEvent", aId, string.format("Target dead. Cancelling '%s' - Id: %d", aName, aId))
        local _, remaining = self:GCDCheck()
        if remaining > 0 then
            self:CancelCurrentEvent("Target died but GCD > 0")
            CombatMetronome.gcdEvent = ZO_ShallowTableCopy(targetDied)
            CombatMetronome.gcdEvent.finished = time + remaining
        else
            self:CancelEvent(time, "Leave him alone, he is already dead")
            self:CancelCurrentEvent("Target died")
        end
        return
    elseif res == ACTION_RESULT_NO_LOCATION_FOUND and CombatMetronome and CombatMetronome.currentEvent and CombatMetronome.currentEvent.ability.id == aId then
        self:CancelCurrentEvent("Invalid location")
        local _, remaining = self:GCDCheck()
        CombatMetronome.gcdEvent = ZO_ShallowTableCopy(invalidLocation)
        CombatMetronome.gcdEvent.finished = time + remaining
        
        return
                -- rolldodge
    elseif aId == 28549 and res == ACTION_RESULT_EFFECT_GAINED then
        local _, remaining = self:GCDCheck()
        self.rollDodgeFinished = time + remaining
        -- zo_callLater(function() self.rollDodgeFinished = true end, remaining)
        self:CancelEvent(time, "Rolldodge")
        if self.currentEvent or CombatMetronome.currentEvent then
            self:CancelCurrentEvent("Rolldodge")
        end
        
        
    elseif err then return
    
        -- Light and heavy attacks
    elseif aSlotType == ACTION_SLOT_TYPE_HEAVY_ATTACK and (res == ACTION_RESULT_BEGIN or res == ACTION_RESULT_BEGIN_CHANNEL) and sType == COMBAT_UNIT_TYPE_PLAYER then
        if (self.currentEvent and self.currentEvent.ability.id == aId) then
            return
        elseif aId ~= GetSlotBoundId(2) then
            return
        end
        local heavy = Util.Ability:ForId(aId, false)
        self:NewEvent(heavy, 2, time)
        return
    elseif aSlotType == ACTION_SLOT_TYPE_LIGHT_ATTACK or aSlotType == ACTION_SLOT_TYPE_WEAPON_ATTACK then
        if (res == ACTION_RESULT_EFFECT_GAINED or res == ACTION_RESULT_CRITICAL_DAMAGE or res == ACTION_RESULT_DAMAGE) and time ~= self.lastLightAttack then
            Ability.Tracker:CallbackLightAttackUsed(time)
            self.lastLightAttack = time
        end
    end
end

function Ability.Tracker:HandleWeaponLockChange(locked)
    local time = GetFrameTimeMilliseconds()
    if not locked and self.currentEvent and self.currentEvent.ability.casted and not self.currentEvent.ability.heavy and ((time-self.currentEvent.start) < self.currentEvent.ability.delay and self.currentEvent.start ~= time) then
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
        self.debugCountReset = true
    elseif inCombat and self.debugCountReset then
        self.debugCountReset = false
    end
end

-----------------------------------
---- Debug/Cancel currentEvent ----
-----------------------------------

function Ability.Tracker:CancelCurrentEvent(reason)
    local printDebug = false
    local ability
    if self.currentEvent then
        if self.currentEvent.ability then ability = self.currentEvent.ability end
        if jesusBeam[self.currentEvent.ability.id] then UnregisterJesusBeam(self.currentEvent.ability.id) end
        self.currentEvent = nil
        self.gcd = 1000
        printDebug = true
    end
        
    if self.CombatMetronome and CombatMetronome.currentEvent then
        ability = ability or CombatMetronome.currentEvent.ability
        CombatMetronome.currentEvent = nil
        CombatMetronome:OnCDStop("")
        printDebug = true
    end
    if printDebug and reason ~= "" then self:PrintDebugNotes("currentEvent", ability.id, string.format("Current event '%s' canceled by: %s", ability.name, reason)) end
    self.lastAbilityFinished = 0
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