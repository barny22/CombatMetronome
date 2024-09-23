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
    self.rollDodgeFinished = true
    self.lastBlockStatus = false
    self.cdUpdatedDuringHeavy = false
    self.heavyUsedDuringHeavy = false
    
    -- self.slotsUpdated = {}
    
    EVENT_MANAGER:RegisterForUpdate(self.name.."Update", 1000 / 30, function(...)
        self:Update()
    end)

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
	EVENT_MANAGER:RegisterForEvent(self.name.."RollDodge", EVENT_EFFECT_CHANGED, function(...)
        self:HandleRollDodge(...)
	end)
	EVENT_MANAGER:RegisterForEvent(self.name.."BarSwap", EVENT_ACTION_SLOTS_ACTIVE_HOTBAR_UPDATED, function(...)
        self:HandleBarSwap(...)
    end)
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

function Ability.Tracker:HandleRollDodge(_,changeType,_,_,_,_,_,_,_,_,_,_,_,_,_,abilityId,sourceType)
    if sourceType == COMBAT_UNIT_TYPE_PLAYER and abilityId == 29721 and changeType == EFFECT_RESULT_UPDATED then			--- 69143 is DodgeFatigue
        self.rollDodgeFinished = false
        local remaining = GetSlotCooldownInfo(3)
        zo_callLater(function() self.rollDodgeFinished = true end, remaining)
    end
    if not self.rollDodgeFinished and self.currentEvent then
        self.currentEvent = nil
        if self.CombatMetronome and CombatMetronome.currentEvent then
            CombatMetronome.currentEvent = nil
            CombatMetronome:SetIconsAndNamesNil()
        end
    end
end

function Ability.Tracker:HandleBarSwap(_, barswap, _, _)
    self.barswap = barswap == true
    if self.barswap and self.currentEvent and self.currentEvent.ability and self.currentEvent.ability.delay > 1000 then
        self.currentEvent = nil
        if self.CombatMetronome and CombatMetronome.currentEvent then
            CombatMetronome.currentEvent = nil
        end
        self.barswap = false
    end
end

function Ability.Tracker:Update()
    local time = GetFrameTimeMilliseconds()
    local gcdProgress = Ability.Tracker:GCDCheck()
    if (self.lastBlockStatus == false) and IsBlockActive() then
        self.currentEvent = nil
        if self.CombatMetronome and CombatMetronome.currentEvent then
            CombatMetronome.currentEvent = nil
        end
    end

    -- Fire off late events if no UPDATE_COOLDOWNS events
    if self.queuedEvent and self.queuedEvent.castDuringRollDodge and self.rollDodgeFinished and not self.currentEvent and gcdProgress > 0 then
        if time > self.queuedEvent.recorded then
            self.eventStart = time
            self:AbilityUsed()
        end
    elseif (not self.eventStart and self.queuedEvent and self.queuedEvent.allowForce and not self.queuedEvent.castDuringRollDodge and not self.currentEvent) then
        if (time > self.queuedEvent.recorded) then
            -- _=self.log and d("Event force "..tostring(time - self.queuedEvent.recorded).."ms ago")
            self.eventStart = self.queuedEvent.recorded
            self:AbilityUsed()
        end
    end
    
    -- Fire off events if all the triggers failed
    if self.queuedEvent and gcdProgress > 0.97 and not self.currentEvent then 
        if not (self.queuedEvent.recorded + math.max(self.queuedEvent.ability.delay,1000) > time) then
            self.eventStart = time
            Ability.Tracker:AbilityUsed()
        end
    end

    if (self.currentEvent and self.currentEvent.start) then
        local event = self.currentEvent
        local ability = event.ability
        
        if (time > event.start + ability.delay) then
            -- d("Event over!")
            -- self.eventStart = nil
            self.currentEvent = nil

            if (event.channeled) then
                Ability.Tracker:CallbackAbilityCancelled(event)
            else
                Ability.Tracker:CallbackAbilityActivated(event)
            end
        end
        if gcdProgress == 0 and not self.currentEvent.ability.heavy then
            self.currentEvent = nil
            if self.CombatMetronome and CombatMetronome.currentEvent then
                CombatMetronome.currentEvent = nil
            end
        end
    end
    if ArePlayerWeaponsSheathed() then
        self.weaponLastSheathed = time
    end
    self.lastBlockStatus = IsBlockActive()
    self.cdUpdatedDuringHeavy = false
    self.heavyUsedDuringHeavy = false
end

function Ability.Tracker:NewEvent(ability, slot, start)
    -- d("creating new event -"..ability.name)
    local time = GetFrameTimeMilliseconds()

    local event = { }

    event.ability = ability
    event.recorded = start
    if not self.rollDodgeFinished then event.castDuringRollDodge = true end
    -- event.recorded = time - EVENT_RECORD_DELAY

    local isMounted = time < self.lastMounted + DISMOUNT_PERIOD
    local weaponSheathed = time < self.weaponLastSheathed + SHEATHING_PERIOD
    event.allowForce = ability.casted and not (isMounted or weaponSheathed or ability.ground)
    
    event.slot = slot
    event.hotbar = GetActiveHotbarCategory()

    self.queuedEvent = event
        
    if self.cdTriggerTime == start and not self.currentEvent and self.rollDodgeFinished and not event.castDuringRollDodge then
        self.eventStart = start
        self:AbilityUsed()
    end
    -- d("  Allow force = "..tostring(self.queuedEvent.allowForce))
end

function Ability.Tracker:CancelEvent()
    -- self.eventStart = nil
    if not (self.queuedEvent and self.queuedEvent.allowForce) then
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

function Ability.Tracker:AbilityUsed()
    local gcdProgress, slotRemaining, slotDuration = Ability.Tracker:GCDCheck()
    local event = self.queuedEvent
    event.start = self.eventStart
    self.queuedEvent = nil
    self.gcd = slotDuration
    self:CallbackAbilityUsed(event)

    if (event.ability.instant or event.ability.channeled) then
        self:CallbackAbilityActivated(event)
    end

    if (not event.ability.instant) then
        -- d("Putting "..event.ability.name.." on current")
        self.currentEvent = event
    end
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
    if not (self.cdTriggerTime == self.heavyUsedDuringHeavy) then
        self.currentEvent = nil
        self.gcd = 0
        -- d("cancelling heavy")
        Ability.Tracker:CallbackAbilityUsed("cancel heavy")
    end
end

function Ability.Tracker:CallbackAbilityCancelled(event)
    -- DAL:Log("EVENT - "..event.ability.name.." ended!")
    -- for name, callback in pairs(self.callbacks[self.CALLBACK_ABILITY_CANCELLED]) do
    --     callback(event)
    -- end
end

-- function Ability.Tracker:HandleSlotUpdated(_, slot)
    
    -- local time = GetFrameTimeMilliseconds()
    
    -- table.insert(self.slotsUpdated, slot)
    -- zo_callLater(function(slot)
        -- if #self.slotsUpdated == 1 then
            -- local slotRemaining = GetSlotCooldownInfo(slot)
            -- if not self.currentEvent and slotRemaining > 0 then
                -- local ability = Ability:ForId(GetSlotBoundId(slot))
                -- self:NewEvent(ability, slot, time)
                -- self.eventStart = time
                -- self:AbilityUsed()
                -- self.slotsUpdated = {}
            -- end
        -- end
    -- end,
    -- 50)
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
-- end

function Ability.Tracker:HandleCooldownsUpdated()
    self.cdTriggerTime = GetFrameTimeMilliseconds()
    
    local gcdProgress, slotRemaining, slotDuration = self:GCDCheck()
    self.gcd = slotDuration
    -- local oldStart = self.eventStart or 0
    
    if self.queuedEvent and self.rollDodgeFinished and not self.queuedEvent.castDuringRollDodge then
        self.eventStart = self.cdTriggerTime - slotDuration + slotRemaining
        if self.eventStart + ((CombatMetronome.config.triggerDebug and CombatMetronome.config.triggerTimer) or 170) >= self.cdTriggerTime then
            self:AbilityUsed()
        end
    end
end

function Ability.Tracker:HandleSlotUsed(_, slot)

    local time = GetFrameTimeMilliseconds()
    
    if slot == 2 and self.currentEvent and self.currentEvent.ability.heavy then
        self.heavyUsedDuringHeavy = time
        self:CallbackCancelHeavy()
        return
    elseif slot == 2 then
        -- local heavy = Util.Ability:ForId(GetSlotBoundId(2))
        -- d("New Heavy")
        -- self:NewEvent(heavy, 2, time)
        return
    end

    local ability = {}
    local actionType = GetSlotType(slot)
    if actionType == ACTION_TYPE_CRAFTED_ABILITY then
        ability = Util.Ability:ForId(GetAbilityIdForCraftedAbilityId(GetSlotBoundId(slot)))
    else
        ability = Util.Ability:ForId(GetSlotBoundId(slot))
    end
    
    self:CancelEvent()
    
    -- if slot == 2 then return end

    -- _=self.log and d(""..GetFrameTimeMilliseconds().." : New ability - "..ability.name)
    self:NewEvent(ability, slot, time)
end

--                                      (a)bility | (d)amage | (p)ower | (t)arget | (s)ource | (h)it
--                                      ------------------------------------------------------------
--                                         1      2     3      4     5  	6      7      8      9
--                                         10     11    12     13    14 	15     16     17     18
function Ability.Tracker:HandleCombatEvent(_,     res,  err,   aName, _, aSlotType, sName, sType, tName, 
                                           tType, hVal, pType, dType, _, sUId, tUId,  aId, overflow)
    if (not err and Util.Targeting.isUnitPlayer(tName, tUId)) then
        if (   res == ACTION_RESULT_KNOCKBACK
            or res == ACTION_RESULT_PACIFIED
            or res == ACTION_RESULT_STAGGERED
            or res == ACTION_RESULT_STUNNED
            or res == ACTION_RESULT_INTERRUPT)
            and not (IsUnitInAir("player") and self.currentEvent) then
            self:CancelEvent()
            self.currentEvent = nil
            return
        end
    end
    
    local time = GetFrameTimeMilliseconds()

    -- log("Checking combat event")
    -- log("sName = ", sName, ", sUId = ", sUId)

    if (Util.Targeting.isUnitPlayer(sName, sUId)) then
        -- log("Source is player")

        if (res == ACTION_RESULT_CANNOT_USE and self.queuedEvent and not self.queuedEvent.allowForce) then
            self:CancelEvent()
            return
        end

        if err then return end

        -- log("Not error!")

        -- local heavyId = GetSlotBoundId(2)
        -- if (heavyId == aId and res == 2200) then
		if (aSlotType == ACTION_SLOT_TYPE_HEAVY_ATTACK and res == 2200) then
            -- d("Heavy ability is current combat event")
            if (self.currentEvent and self.currentEvent.ability.id == aId) then
                return
            elseif aId ~= GetSlotBoundId(2) then
                return
            end

            local heavy = Util.Ability:ForId(aId)
            -- _=self.log and d("New heavy ability - "..heavy.name)
            self:NewEvent(heavy, 2, time)
            
            -- self.eventStart = self.queuedEvent.recorded
            -- self:AbilityUsed()
        end
        -- local lightId = GetSlotBoundId(1)
        if aSlotType == ACTION_SLOT_TYPE_LIGHT_ATTACK --[[and res == 2240 and time ~= self.lastLightAttack ]]then
            if res == 2240 and time ~= self.lastLightAttack then
                Ability.Tracker:CallbackLightAttackUsed(time)
            end
            -- d(res.." - "..hVal.." - "..overflow)
        end
        self.lastLightAttack = time
    end
end