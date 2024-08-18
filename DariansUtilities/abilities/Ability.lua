-- local Util = DAL:Ext("DariansUtilities")
local Util = DariansUtilities
Util.Ability = Util.Ability or { }
Util.Text = Util.Text or {}
local Ability = Util.Ability
Ability.cache = { }
Ability.nameCache = { }
Util.language = GetCVar("Language.2")

local TargetGround = {
["en"] = "Ground";
["de"] = "Bodenziel";
["es"] = "Suelo";
["fr"] = "Sol";
["ru"] = "Указанная область";
["zh"] = "地面";
}
local SlotNumbers = {3,4,5,6,7,8}

local log = Util.log

function Ability:ForId(id)
    -- local APIVersion = GetAPIVersion()
	local o = self.cache[id]
	if (o) then 
        -- d(" Ability "..o.name.." is cached for id, "..id)
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

    o.ground = o.target == TargetGround[Util.language]
    o.heavy = o.id == GetSlotBoundId(2)
    o.light = o.id == GetSlotBoundId(1)

    o.hasProgression,
    o.progressionIndex = GetAbilityProgressionXPInfoFromAbilityId(id)

    if o.hasProgression then
        o.baseName,
        o.morph,
        o.rank = GetAbilityProgressionInfo(o.progressionIndex)

        o.baseId = GetAbilityProgressionAbilityId(o.progressionIndex, 0, 1)
    end

    if (name) then
        -- d(" Caching from id! slot = "..tostring(o.slot))
        self.nameCache[name] = o
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

local EVENT_RECORD_DELAY = 10
local EVENT_FORCE_WAIT = 100
local DISMOUNT_PERIOD = 300
local SHEATHING_PERIOD = 250

function Ability.Tracker:Start()
    if self.started then return end

    -- d("Ability Tracker Started!")

    self.started = true

    self.log = false
    self.cdTriggerTime = 0
    self.lastMounted = 0
    self.weaponLastSheathed = 0
    self.eventStart = 0
    self.lastSlotRemaining = 0
    self.lastLightAttack = 0
    
    self.slotsUpdated = {}
    
    EVENT_MANAGER:RegisterForUpdate(self.name.."Update", 1000 / 30, function(...)
        self:Update()
    end)

    EVENT_MANAGER:RegisterForEvent(self.name.."SlotUpdated", EVENT_ACTION_SLOT_STATE_UPDATED, function(_, slot) 
        if slot == 1 or (slot > 2 and slot < 9) then self:HandleSlotUpdated(_, slot) end
    end)
    EVENT_MANAGER:RegisterForEvent(self.name.."SlotUsed", EVENT_ACTION_SLOT_ABILITY_USED, function(_, slot)
        if slot > 1 and slot < 9 then self:HandleSlotUsed(_, slot) end
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
end

function Ability.Tracker:Update()
    local time = GetFrameTimeMilliseconds()
    local gcdProgress = Ability.Tracker:GCDCheck()

    -- Fire off late events if no SLOT_UPDATE events
    -- if (not self.eventStart and self.queuedEvent and self.queuedEvent.allowForce) then
        -- if (time > self.queuedEvent.recorded + EVENT_FORCE_WAIT) then
            -- _=self.log and d("Event force "..tostring(time - self.queuedEvent.recorded).."ms ago")
            -- self.eventStart = self.queuedEvent.recorded
            -- self:AbilityUsed()
        -- end
    -- end

    if (self.currentEvent and self.eventStart) then
        local event = self.currentEvent
        local ability = event.ability

        if (time > self.eventStart + math.max(ability.delay, 1000)) and gcdProgress <= 0 then
            -- d("Event over!")
            self.eventStart = nil
            self.currentEvent = nil

            if (event.channeled) then
                Ability.Tracker:CallbackAbilityCancelled(event)
            else
                Ability.Tracker:CallbackAbilityActivated(event)
            end
        end
    end
    if ArePlayerWeaponsSheathed() then
        self.weaponLastSheathed = time
    end
    -- self.slotsNotUpdated = {3,4,5,6,7,8}
end

function Ability.Tracker:NewEvent(ability, slot, start)
    -- d("creating new event -"..ability.name)
    local time = GetFrameTimeMilliseconds()

    local event = { }

    event.ability = ability
    event.recorded = start
    self.eventStart = start
    -- event.recorded = time - EVENT_RECORD_DELAY

    local isMounted = time < self.lastMounted + DISMOUNT_PERIOD
    local weaponSheathed = time < self.weaponLastSheathed + SHEATHING_PERIOD
    event.allowForce = ability.casted and not (isMounted or weaponSheathed or ability.ground)
    
    event.slot = slot
    event.hotbar = GetActiveHotbarCategory()

    self.queuedEvent = event
        
    if self.cdTriggerTime == start then
        self:AbilityUsed()
    end
    -- d("  Allow force = "..tostring(self.queuedEvent.allowForce))
end

function Ability.Tracker:CancelEvent()
    -- self.eventStart = nil
    self.queuedEvent = nil

    if (self.currentEvent) then
        local ability = self.currentEvent.ability
        if (ability.heavy) then
            self:CallbackAbilityActivated(self.currentEvent)
        else
            self:CallbackAbilityCancelled(self.currentEvent)
        end
    end

    self.currentEvent = nil
end

function Ability.Tracker:AbilityUsed()
    -- d("trying to use ability - "..self.queuedEvent.ability.name)
    -- local gcdProgress, slotRemaining, slotDuration = Ability.Tracker:GCDCheck()
    -- local abilityMayBeTriggered1 = self.currentEvent and self.currentEvent.ability.id == self.queuedEvent.ability.id and self.currentEvent.start + self.lastSlotRemaining < self.eventStart and gcdProgress > 0.7
    -- local abilityMayBeTriggered2 = self.currentEvent and self.currentEvent.ability.id == not self.queuedEvent.ability.id and not (self.queuedEvent.ability.heavy and self.currentEvent.start + self.lastSlotRemaining > self.eventStart) and gcdProgress > 0.7
    -- local abilityMayBeTriggered3 = self.currentEvent and self.currentEvent.start + self.lastSlotRemaining < self.eventStart and gcdProgress > 0.7
    
    -- if abilityMayBeTriggered1 or abilityMayBeTriggered2 or abilityMayBeTriggered3 or not self.currentEvent or gcdProgress == 0 then
    -- d("using ability - "..self.queuedEvent.ability.name)
        local event = self.queuedEvent
        event.start = self.eventStart
        self.queuedEvent = nil
        self.gcd = slotDuration
        self:CallbackAbilityUsed(event)

        if (event.ability.instant or event.ability.channeled) then
            self:CallbackAbilityActivated(event)
        end

    -- if (not event.ability.instant) then
        -- d("Putting "..event.ability.name.." on current")
        self.currentEvent = event
        -- self.lastSlotRemaining = slotRemaining
    -- end
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

function Ability.Tracker:CallbackAbilityCancelled(event)
    -- DAL:Log("EVENT - "..event.ability.name.." ended!")
    -- for name, callback in pairs(self.callbacks[self.CALLBACK_ABILITY_CANCELLED]) do
    --     callback(event)
    -- end
end

function Ability.Tracker:HandleSlotUpdated(_, slot)
    
    local time = GetFrameTimeMilliseconds()
    
    if slot == 1 then 
        Ability.Tracker:CallbackLightAttackUsed(time)
        return
    end
    
    table.insert(self.slotsUpdated, slot)
    zo_callLater(function(slot)
        if #self.slotsUpdated == 1 then
            local slotRemaining = GetSlotCooldownInfo(slot)
            if not self.currentEvent and slotRemaining > 0 then
                local ability = Ability:ForId(GetSlotBoundId(slot))
                self:NewEvent(ability, slot, time)
                self.eventStart = time
                self:AbilityUsed()
                self.slotsUpdated = {}
            end
        end
    end,
    50)
    -- trigger for only elemental explosion
    -- for i, num in ipairs(self.slotsNotUpdated) do
        -- if num == slot then
            -- table.remove(self.slotsNotUpdated, i)
            -- break
        -- end
    -- end
    -- if #self.slotsNotUpdated == 1 then
        -- if GetSlotBoundId(self.slotsNotUpdated[1]) == 5 and self.queuedEvent and self.queuedEvent.ability.id == GetAbilityIdForCraftedAbilityId(GetSlotBoundId(self.slotsNotUpdated[1])) and self.triggerForEleExplosionAllowed then
            -- self.triggerForEleExplosion = true
            -- self.triggerForEleExplosionAllowed = false
            -- zo_callLater(function() self.triggerForEleExplosionAllowed = true end, 500)
        -- end
    -- elseif #self.slotsNotUpdated == 0 then
        -- self:CancelEvent()
    -- end
    -- trigger is finished here
    
    -- local remaining, duration, global, t = GetSlotCooldownInfo(slot)
    -- local gcdProgress, remaining, duration = Ability.Tracker:GCDCheck()
    -- local time = GetFrameTimeMilliseconds()

    -- local abilityUsed = (duration > 0 and remaining > 0)
    
    -- if self.triggerForEleExplosion then self.triggerForEleExplosion = false end

    -- if abilityUsed then
        -- self.gcd = remaining

        -- local oldStart = self.eventStart or 0
        -- self.eventStart = time + remaining - duration 

        -- if (oldStart ~= self.eventStart) then
            -- _=self.log and d(""..time.." : Event start "..tostring(duration - remaining).."ms ago")
        -- end
        
        -- if (self.queuedEvent and self.eventStart > oldStart + 100) then
            -- _=self.log and d(""..time.." : Moved queued "..self.queuedEvent.ability.name.." to current") 
            -- log("  Dispatching ", self.queuedEvent.ability.name)
            -- log("    oldStart = ", oldStart)
            -- log("    newStart = ", self.eventStart)
            -- log("    current  = ", GetFrameTimeMilliseconds())
            -- self:AbilityUsed()
        -- end
    -- end
end

function Ability.Tracker:HandleCooldownsUpdated()
    self.cdTriggerTime = GetFrameTimeMilliseconds()
    
    local gcdProgress, slotRemaining, slotDuration = self:GCDCheck()
    self.gcd = slotDuration
    -- local oldStart = self.eventStart or 0
    
    if self.queuedEvent then
        self.eventStart = self.cdTriggerTime - slotDuration + slotRemaining
        if self.eventStart + 100 >= self.cdTriggerTime then
            self:AbilityUsed()
        end
    end
end

function Ability.Tracker:HandleSlotUsed(_, slot)

    local time = GetFrameTimeMilliseconds()

    local ability = {}
    local actionType = GetSlotType(slot)
    if actionType == ACTION_TYPE_CRAFTED_ABILITY then
        ability = Util.Ability:ForId(GetAbilityIdForCraftedAbilityId(GetSlotBoundId(slot)))
    else
        ability = Util.Ability:ForId(GetSlotBoundId(slot))--, slot)
    end
    
    -- if not (ability) then return end

    -- if (ability.light) then return end

    self:CancelEvent()

    if (slot == 2) then return end

    -- _=self.log and d(""..GetFrameTimeMilliseconds().." : New ability - "..ability.name)
    self:NewEvent(ability, slot, time)
end

--                                      (a)bility | (d)amage | (p)ower | (t)arget | (s)ource | (h)it
--                                      ------------------------------------------------------------
--                                         1      2     3      4     5  6      7      8      9
--                                         10     11    12     13    14 15     16     17     18
function Ability.Tracker:HandleCombatEvent(_,     res,  err,   aName, _, _,    sName, sType, tName, 
                                           tType, hVal, pType, dType, _, sUId, tUId,  aId, overflow)
    if (not err and Util.Targeting.isUnitPlayer(tName, tUId)) then
        if (   res == ACTION_RESULT_KNOCKBACK
            or res == ACTION_RESULT_PACIFIED
            or res == ACTION_RESULT_STAGGERED
            or res == ACTION_RESULT_STUNNED
            or res == ACTION_RESULT_INTERRUPTED) then
            self:CancelEvent()
            return
        end
    end
    
    local time = GetFrameTimeMilliseconds()

    -- log("Checking combat event")
    -- log("sName = ", sName, ", sUId = ", sUId)

    if (Util.Targeting.isUnitPlayer(sName, sUId)) then
        -- log("Source is player")

        if (res == COMBAT_RESULT_CANNOT_USE and not self.queuedEvent.allowForce) then
            self:CancelEvent()
            return
        end

        if err then return end

        -- log("Not error!")

        local heavyId = GetSlotBoundId(2)
        if (heavyId == aId) then
            -- d("Heavy ability is current combat event")
            if (self.currentEvent and self.currentEvent.ability.id == heavyId) then
                return
            end

            local heavy = Util.Ability:ForId(heavyId)
            -- _=self.log and d("New heavy ability - "..heavy.name)
            self:NewEvent(heavy, 2, time)
            
            -- self.eventStart = self.queuedEvent.recorded
            -- self:AbilityUsed()
        end
        -- local lightId = GetSlotBoundId(1)
        -- if lightId == aId and res ~= 2350 and self.lastLightAttack ~= time then
            -- Ability.Tracker:CallbackLightAttackUsed(time)
            -- self.lastLightAttack = time
        -- end
    end
end

function Ability.Tracker:GCDCheck()
    local slotRemaining, slotDuration, _, _ = GetSlotCooldownInfo(3)
    local sR, sD, _, _ = GetSlotCooldownInfo(4)
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