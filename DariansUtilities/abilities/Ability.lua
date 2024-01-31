-- local Util = DAL:Ext("DariansUtilities")
local Util = DariansUtilities
Util.Ability = Util.Ability or { }
local Ability = Util.Ability
Ability.cache = { }
Ability.nameCache = { }

local log = Util.log

function Ability:ForId(id)
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

	local name, actionSlotType, passive
    for i = 1, 100000 do
        if (id == GetAbilityIdByIndex(i)) then
            name, _, _, actionSlotType, passive, _ = GetAbilityInfoByIndex(i)
            break
        end
    end

    o.id = id
    o.name = GetAbilityName(id)
    o.channeled, 
    o.castTime, 
    o.channelTime = GetAbilityCastInfo(id)
    o.delay = math.max(o.castTime, o.channelTime)
    o.instant = not (o.castTime > 0 or (o.channeled and o.channelTime > 0))
    o.casted = not (o.instant or o.channeled)
    o.passive = passive
    o.target = GetAbilityTargetDescription(id)
    o.type = actionSlotType
	o.icon = GetAbilityIcon(id)

    o.duration = GetAbilityDuration(id)
    o.buffType = GetAbilityBuffType(id)
    o.isTankAbility, 
    o.isHealerAbility, 
    o.isDamageAbility = GetAbilityRoles(id)

    o.ground = o.target == "Ground"
    o.heavy = o.type == ACTION_SLOT_TYPE_HEAVY_ATTACK
    o.light = o.type == ACTION_SLOT_TYPE_LIGHT_ATTACK

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

function Ability:ForName(name)
    local o = self.nameCache[name]
    if (o) then
        -- d(" Ability "..o.id.." is cached for name, "..name)
        return o 
    end

    return self:ForId(Ability.getIdFromName(name))
end

function Ability.getIdFromName(name)
    local hotbar = GetActiveHotbarCategory()
    for i = 1, 100000 do
        if (CanAbilityBeUsedFromHotbar(i, hotbar) and name == GetAbilityName(i)) then
            return i
        end
    end

    return nil
end

-- -------- --
-- Tracking --
-- -------- --

-- HasTargetFailure(slotIndex) --> true if cannot use ability on target (or no target)

Ability.Tracker = Ability.Tracker or { }
Ability.Tracker.name = "Util.Ability.Tracker"

local EVENT_RECORD_DELAY = 10
local EVENT_FORCE_WAIT = 100
local DISMOUNT_PERIOD = 500

function Ability.Tracker:Start()
    if self.started then return end

    -- d("Abiilty Tracker Started!")

    self.started = true

    self.log = false
    self.lastMounted = 0

    EVENT_MANAGER:RegisterForUpdate(self.name.."Update", 1000 / 30, function(...)
        self:Update()
    end)

    EVENT_MANAGER:RegisterForEvent(self.name.."SlotUpdated", EVENT_ACTION_SLOT_STATE_UPDATED, function(...) 
        self:HandleSlotUpdated(...) 
    end)
    EVENT_MANAGER:RegisterForEvent(self.name.."SlotUsed", EVENT_ACTION_SLOT_ABILITY_USED, function(...)
        self:HandleSlotUsed(...) 
    end)
    EVENT_MANAGER:RegisterForEvent(self.name.."CombatEvent", EVENT_COMBAT_EVENT, function(...)
        self:HandleCombatEvent(...) 
    end)
end

function Ability.Tracker:Update()
    local time = GetFrameTimeMilliseconds()

    -- Fire off late events if no SLOT_UPDATE events
    if (not self.eventStart and self.queuedEvent and self.queuedEvent.allowForce) then
        if (time > self.queuedEvent.recorded + EVENT_FORCE_WAIT) then
            -- _=self.log and d("Event force "..tostring(time - self.queuedEvent.recorded).."ms ago")
            self.eventStart = self.queuedEvent.recorded
            self:AbilityUsed()
        end
    end

    if (self.currentEvent and self.eventStart) then
        local event = self.currentEvent
        local ability = event.ability

        if (time > self.eventStart + ability.delay) then
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

    if (IsMounted()) then
        self.lastMounted = time
    end
end

function Ability.Tracker:NewEvent(ability, slot, start)
    local time = GetFrameTimeMilliseconds()

    local event = { }

    event.ability = ability
    event.recorded = time - EVENT_RECORD_DELAY

    local isMounted = time < self.lastMounted + DISMOUNT_PERIOD
    event.allowForce = ability.casted and not (isMounted or ability.ground)

    -- event.triggerOnCombatEvent = true
    event.triggerOnSlotUpdated = true
    -- event.triggerOnSlotUpdated = not ability.ground

    event.slot = slot
    event.hotbar = GetActiveHotbarCategory()

    self.queuedEvent = event

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
    local event = self.queuedEvent
    event.start = self.eventStart
    self.queuedEvent = nil
    self:CallbackAbilityUsed(event)

    if (event.ability.instant or event.ability.channeled) then
        self:CallbackAbilityActivated(event)
    end

    if (not event.ability.instant) then
        -- d("Putting "..event.ability.name.." on current")
        self.currentEvent = event
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

function Ability.Tracker:CallbackAbilityCancelled(event)
    -- DAL:Log("EVENT - "..event.ability.name.." ended!")
    -- for name, callback in pairs(self.callbacks[self.CALLBACK_ABILITY_CANCELLED]) do
    --     callback(event)
    -- end
end

function Ability.Tracker:HandleSlotUpdated(e, slot)
    if (slot < 3) then return end

    local remaining, duration, global, t = GetSlotCooldownInfo(slot)
    local time = GetFrameTimeMilliseconds()

    if (duration > 0 and remaining > 0) then
        self.gcd = duration

        local oldStart = self.eventStart or 0
        self.eventStart = time + remaining - duration 

        if (oldStart ~= self.eventStart) then
            -- _=self.log and d(""..time.." : Event start "..tostring(duration - remaining).."ms ago")
        end
        
        if (self.queuedEvent and self.queuedEvent.triggerOnSlotUpdated and self.eventStart > oldStart + 100) then
            -- _=self.log and d(""..time.." : Moved queued "..self.queuedEvent.ability.name.." to current") 
            -- log("  Dispatching ", self.queuedEvent.ability.name)
            -- log("    oldStart = ", oldStart)
            -- log("    newStart = ", self.eventStart)
            -- log("    current  = ", GetFrameTimeMilliseconds())
            self:AbilityUsed()
        end
    end
end

function Ability.Tracker:HandleSlotUsed(e, slot)
    if (slot > 8) then return end

    local ability = Util.Ability:ForId(GetSlotBoundId(slot), slot)
    -- Util.log("SLOT NAME = ", GetSlotName(slot))
    -- local ability = Util.Ability:ForName(GetSlotName(slot), slot)
    if not (ability) then return end

    if (ability.light) then return end

    self:CancelEvent()

    if (ability.heavy) then return end

    -- _=self.log and d(""..getFrameTimeMilliseconds().." : New ability - "..ability.name)
    self:NewEvent(ability, slot)
end

local CHECK_PLAYER_UNIT_ID_INTERVAL = 5000

--                                      (a)bility | (d)amage | (p)ower | (t)arget | (s)ource | (h)it
--                                      ------------------------------------------------------------
--                                         1      2     3      4     5  6      7      8      9
--                                         10     11    12     13    14 15     16     17     18
function Ability.Tracker:HandleCombatEvent(_,     res,  err,   aName, _, _,    sName, sType, tName, 
                                           tType, hVal, pType, dType, _, sUId, tUId,  aId,   _     )
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

    -- log("Checking combat event")
    -- log("sName = ", sName, ", sUId = ", sUId)

    if (Util.Targeting.isUnitPlayer(sName, sUId)) then
        -- log("Source is player")

        if (res == COMBAT_RESULT_CANNOT_USE and not self.abilityAllowForce) then
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
            self:NewEvent(heavy, 2)
            self.eventStart = self.queuedEvent.recorded
            self:AbilityUsed()
        end
    end
end