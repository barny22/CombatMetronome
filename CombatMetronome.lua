-- local Util = DAL:Use("DariansUtilities", 6)
-- CombatMetronome = DAL:Def("CombatMetronome", 4, 1, {
--     onLoad = function(self) self:Init() end,
-- })

CombatMetronome = {
    name = "CombatMetronome",
    major = 6,
    minor = 7,
    version = "1.6.7"
}

-- local LAM = LibAddonMenu2
local Util = DariansUtilities

Util.onLoad(CombatMetronome, function(self) self:Init() end)

ZO_CreateStringId("SI_BINDING_NAME_COMBATMETRONOME_FORCE", "Force display")

	-------------------------------------
	---- Initialize Combat Metronome ----
	-------------------------------------

function CombatMetronome:Init()
    self.config = ZO_SavedVars:NewCharacterIdSettings("CombatMetronomeSavedVars", 1, nil, CM_DEFAULT_SAVED_VARS)
    if self.config.global then
        self.config = ZO_SavedVars:NewAccountWide("CombatMetronomeSavedVars", 1, nil, CM_DEFAULT_SAVED_VARS)
        self.config.global = true
    end
	
	self.currentCharacterName = CombatMetronome:CropZOSString(GetUnitName("player"))
		
	self.classId = GetUnitClassId("player")
	self.class = CM_CLASS[self.classId]
	self.activeMount = {}
	self.activeMount.name = CombatMetronome:CropZOSString(GetCollectibleNickname(GetActiveCollectibleByType(COLLECTIBLE_CATEGORY_TYPE_MOUNT,GAMEPLAY_ACTOR_CATEGORY_PLAYER)))
	self.activeMount.icon = GetCollectibleIcon(GetActiveCollectibleByType(COLLECTIBLE_CATEGORY_TYPE_MOUNT,GAMEPLAY_ACTOR_CATEGORY_PLAYER))
	self.activeMount.action = ""
	-- self.collectibleInUse = {}

    self.log = self.config.debug

    self.inCombat = IsUnitInCombat("player")
    self.currentEvent = nil
	self.rollDodgeFinished = true

    self.gcd = 1000

    self.unlocked = false
    self.progressbar = CombatMetronome:BuildProgressBar()
    CombatMetronome:BuildMenu()
	-- CombatMetronome:UpdateAdjustChoices()

    self.lastInterval = 0
	self.actionSlotCache = CombatMetronome:StoreAbilitiesOnActionBar()

	self:RegisterMetadata()
	
	Util.Ability.Tracker.CombatMetronome = self
    Util.Ability.Tracker:Start()
	
	----------------------------------
	---- Initialize Stack Tracker ----
	----------------------------------
	
	if CM_TRACKER_CLASS_ATTRIBUTES[self.class] then
		self.stackTracker = CombatMetronome:BuildStackTracker()
		self.stackTracker.indicator.ApplyDistance(self.config.indicatorSize/5, self.config.indicatorSize)
		self.stackTracker.indicator.ApplySize(self.config.indicatorSize)
		self.stackTracker.indicator.ApplyIcon()
	
		self:RegisterTracker()
		self.showSampleTracker = false
	end	
end

-- LOAD HOOK

-- EVENT_MANAGER:RegisterForEvent(CombatMetronome.name.."Load", EVENT_ADD_ON_LOADED, function(...)
--     if (CombatMetronome.loaded) then return end
--     CombatMetronome.loaded = true

--     CombatMetronome:Init()
-- end)

	-----------------------------
	---- Register/Unregister ----
	-----------------------------

function CombatMetronome:RegisterMetadata()
	EVENT_MANAGER:RegisterForEvent(
        self.name.."CurrentActionslotsOnHotbar",
        EVENT_ACTION_SLOT_UPDATED,
        function()
			self.actionSlotCache = CombatMetronome:StoreAbilitiesOnActionBar()
			-- self.menu.abilityAdjustChoices = CombatMetronome:BuildListForAbilityAdjusts()
        end
    )
	
	EVENT_MANAGER:RegisterForEvent(
		self.name.."CharacterLoaded",
		EVENT_PLAYER_ACTIVATED,
		function(_,_)
			self.inPVPZone = self:IsInPvPZone()
			self:CMPVPSwitch()
			self:TrackerPVPSwitch()
			self:ResourcesPVPSwitch()
		end
	)

    EVENT_MANAGER:RegisterForEvent(
        self.name.."CombatStateChange",
        EVENT_PLAYER_COMBAT_STATE,
        function(_, inCombat) 
            self.inCombat = inCombat == true
            -- self.stamGradient:Reset()
        end
    )		
end

function CombatMetronome:RegisterCM()
	EVENT_MANAGER:RegisterForUpdate(
        self.name.."Update",
        1000 / 60,
        function(...) self:Update() end
    )
    
    EVENT_MANAGER:RegisterForEvent(
        self.name.."SlotUsed",
        EVENT_ACTION_SLOT_ABILITY_USED,
        function(e, slot)
			-- d(slot)
			local ability = {}
            local actionType = GetSlotType(slot)
			-- d(actionType)
			if actionType == ACTION_TYPE_CRAFTED_ABILITY then --3 then
				-- d("Crafted ability executed")
				ability = Util.Ability:ForId(GetAbilityIdForCraftedAbilityId(GetSlotBoundId(slot)))
				-- d("Ability used - "..ability.name..", ID: "..ability.id)
			else
				ability = Util.Ability:ForId(GetSlotBoundId(slot))
			end
						
			-- d("Slot used - Target: "..GetAbilityTargetDescription(GetSlotBoundId(slot)).." - "..ability.name)
            -- log("Abilty used - ", ability.name)
            if (ability and ability.heavy) then
                -- log("Cancelling heavy")
                self.currentEvent = nil
            end
        end
    )
	
	self.cmRegistered = true
	
	EVENT_MANAGER:RegisterForEvent(
		self.name.."BarSwap",
		EVENT_ACTION_SLOTS_ACTIVE_HOTBAR_UPDATED,
		function(_,barswap,_,category)
			self.barswap = barswap == true
			if self.barswap and self.currentEvent and self.currentEvent.ability and self.currentEvent.ability.delay > 1000 then
				self.currentEvent = nil
				self.barswap = false
				-- d("interrupted spell by barswap")
			end
		end
	)
	
	EVENT_MANAGER:RegisterForEvent(
		self.name.."RollDodge",
		EVENT_EFFECT_CHANGED,
		function(_,changeType,_,_,_,_,_,_,_,_,_,_,_,_,_,abilityId,sourceType)
			if sourceType == COMBAT_UNIT_TYPE_PLAYER and abilityId == 29721 and changeType == 3 then			--- 69143 is DodgeFatigue
				self.rollDodgeFinished = false
				zo_callLater(function () self.rollDodgeFinished = true end, 1000)
			end
			if not self.rollDodgeFinished and self.currentEvent then
				self.currentEvent = nil
				-- d("interrupted spell by dodgeroll")
			end
		end
	)
	
	EVENT_MANAGER:RegisterForEvent(
		self.name.."CollectibleUsed",
		EVENT_COLLECTIBLE_UPDATED,
		function(_, id)
			local name,_,icon,_,_,_,_,type,_ = GetCollectibleInfo(id)
			if type == COLLECTIBLE_CATEGORY_TYPE_ASSISTANT or type == COLLECTIBLE_CATEGORY_TYPE_COMPANION then
				self.collectibleInUse = {}
				self.collectibleInUse.name = CombatMetronome:CropZOSString(name)
				self.collectibleInUse.icon = icon
				zo_callLater(function()
					self.collectibleInUse = nil
					end, 1000)
			end
			if type == COLLECTIBLE_CATEGORY_TYPE_MOUNT then
				self.activeMount.name = CombatMetronome:CropZOSString(GetCollectibleNickname(id))
				self.activeMount.icon = icon
			end
		end
	)
			
			
	EVENT_MANAGER:RegisterForEvent(
		self.name.."Mounting",
		EVENT_COMBAT_EVENT,
--                (a)bility | (d)amage | (p)ower | (t)arget | (s)ource | (h)it
--                ------------------------------------------------------------
--                1      2     3      4     5  6      7      8      9
--                10     11    12     13    14 15     16     17     18
		function (_,     res,  err,   aName, _, _,    sName, sType, tName, 
					tType, hVal, pType, dType, _, sUId, tUId,  aId,   _     )
			if CombatMetronome:CropZOSString(sName) == self.currentCharacterName then
				if IsMounted() and aId == 36432 and self.activeMount.action ~= "Dismounting " then
					self.activeMount.action = "Dismounting "
				elseif not IsMounted() and aId == 36010 and self.activeMount.action ~= "Mounting " then
					self.activeMount.action = "Mounting "
				end
			end
			-- if CombatMetronome:CropZOSString(tName) == self.currentCharacterName then
				-- d(aName.." - "..aId.." - "..sUId)
			-- end
		end
	)	
	-- d("cm is registered")
end

function CombatMetronome:RegisterResourceTracker()
    EVENT_MANAGER:RegisterForUpdate(
        self.name.."UpdateLabels",
        1000 / 60,
        function(...) self:UpdateLabels() end
    )
	
	self.rtRegistered = true
end

function CombatMetronome:RegisterTracker()
	EVENT_MANAGER:RegisterForUpdate(
		self.name.."UpdateStacks",
		1000 / 60,
		function(...) CombatMetronome:TrackerUpdate() end
	)
	self.trackerRegistered = true
	-- d("tracker is registered")
end

function CombatMetronome:UnregisterCM()
	EVENT_MANAGER:UnregisterForUpdate(
        self.name.."Update")
		
	EVENT_MANAGER:UnregisterForEvent(
        self.name.."SlotUsed")
	
	self.cmRegistered = false
	
	EVENT_MANAGER:UnregisterForEvent(
		self.name.."BarSwap")
		
	EVENT_MANAGER:UnregisterForEvent(
		self.name.."RollDodge")
	-- d("cm is unregistered")
end

function CombatMetronome:UnregisterResourceTracker()
	EVENT_MANAGER:UnregisterForUpdate(
        self.name.."UpdateLabels")
		
	self.rtRegistered = false
end

function CombatMetronome:UnregisterTracker()
	EVENT_MANAGER:UnregisterForUpdate(
		self.name.."UpdateStacks")
	
	self.trackerRegistered = false
	-- d("tracker is unregistered")
	-- self.trackerWarning = false
end