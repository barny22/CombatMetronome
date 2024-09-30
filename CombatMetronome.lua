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
Util.Ability = Util.Ability or {}
Util.Text = Util.Text or {}
Util.Stacks = Util.Stacks or {}
CombatMetronome.LATracker = CombatMetronome.LATracker or {}
local LATracker = CombatMetronome.LATracker
LATracker.name = CombatMetronome.name.."LightAttackTracker"
CombatMetronome.CCTracker = CombatMetronome.CCTracker or {}
local CCTracker = CombatMetronome.CCTracker
CCTracker.name = CombatMetronome.name.."CCTracker"

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
	
	self.currentCharacterName = Util.Text.CropZOSString(GetUnitName("player"))
		
	self.classId = GetUnitClassId("player")
	self.class = CM_CLASS[self.classId]
	self.activeMount = {}
	self.activeMount.name = Util.Text.CropZOSString(GetCollectibleNickname(GetActiveCollectibleByType(COLLECTIBLE_CATEGORY_TYPE_MOUNT,GAMEPLAY_ACTOR_CATEGORY_PLAYER)))
	self.activeMount.icon = GetCollectibleIcon(GetActiveCollectibleByType(COLLECTIBLE_CATEGORY_TYPE_MOUNT,GAMEPLAY_ACTOR_CATEGORY_PLAYER))
	self.activeMount.action = ""
	self.itemUsed = nil
	self.collectibleInUse = nil
	
	CCTracker.cc = {}
	CCTracker.variables = {
	-- Effects Changed
	
	[32] = {"/esoui/art/icons/ability_debuff_disorient.dds", self.config.CC.Disoriented}, --ABILITY_TYPE_DISORIENT
	[27] = {"/esoui/art/icons/ability_debuff_fear.dds", self.config.CC.Fear}, --ABILITY_TYPE_FEAR
	[17] = {"/esoui/art/icons/ability_debuff_knockback.dds", self.config.CC.Knockback}, --ABILITY_TYPE_KNOCKBACK
	[48] = {"/esoui/art/icons/ability_debuff_levitate.dds", self.config.CC.Levitate}, --ABILITY_TYPE_LEVITATE
	[53] = {"/esoui/art/icons/ability_debuff_offbalance.dds", self.config.CC.Offbalance}, --ABILITY_TYPE_OFFBALANCE
	-- [2480] = {"/esoui/art/icons/ability_debuff_root.dds", self.config.CC.Root}, --ACTION_RESULT_ROOTED
	[11] = {"/esoui/art/icons/ability_debuff_silence.dds", self.config.CC.Silence}, --ABILITY_TYPE_SILENCE
	[10] = {"/esoui/art/icons/ability_debuff_snare.dds", self.config.CC.Snare}, --ABILITY_TYPE_SNARE
	[33] = {"/esoui/art/icons/ability_debuff_stagger.dds", self.config.CC.Stagger}, --ABILITY_TYPE_STAGGER
	[9] = {"/esoui/art/icons/ability_debuff_stun.dds", self.config.CC.Stun}, --ABILITY_TYPE_STUN
	
	
	-- Combat Events:
	
	-- [2340] = {"/esoui/art/icons/ability_debuff_disorient.dds", self.config.CC.Disoriented}, --ACTION_RESULT_DISORIENTED
	-- [2320] = {"/esoui/art/icons/ability_debuff_fear.dds", self.config.CC.Fear}, --ACTION_RESULT_FEARED
	-- [2475] = {"/esoui/art/icons/ability_debuff_knockback.dds", self.config.CC.Knockback}, --ACTION_RESULT_KNOCKBACK
	-- [2400] = {"/esoui/art/icons/ability_debuff_levitate.dds", self.config.CC.Levitate}, --ACTION_RESULT_LEVITATED
	-- [2440] = {"/esoui/art/icons/ability_debuff_offbalance.dds", self.config.CC.Offbalance}, --ACTION_RESULT_OFFBALANCE
	-- [2480] = {"/esoui/art/icons/ability_debuff_root.dds", self.config.CC.Root}, --ACTION_RESULT_ROOTED
	-- [2010] = {"/esoui/art/icons/ability_debuff_silence.dds", self.config.CC.Silence}, --ACTION_RESULT_SILENCED
	-- [2025] = {"/esoui/art/icons/ability_debuff_snare.dds", self.config.CC.Snare}, --ACTION_RESULT_SNARED
	-- [2470] = {"/esoui/art/icons/ability_debuff_stagger.dds", self.config.CC.Stagger}, --ACTION_RESULT_STAGGERED
	-- [2020] = {"/esoui/art/icons/ability_debuff_stun.dds", self.config.CC.Stun}, --ACTION_RESULT_STUNNED
}

    self.log = self.config.debug

    self.inCombat = IsUnitInCombat("player")
    self.currentEvent = nil
	-- self.rollDodgeFinished = true

    self.gcd = 1000

    self.unlocked = false
    self.progressbar = CombatMetronome:BuildProgressBar()
    CombatMetronome:BuildMenu()
	-- CombatMetronome:UpdateAdjustChoices()

    self.lastInterval = 0
	self.actionSlotCache = Util.Stacks:StoreAbilitiesOnActionBar()

	self:RegisterMetadata()
	
	Util.Ability.Tracker.CombatMetronome = self
    Util.Ability.Tracker:Start()
	
	-----------------------
	---- Stack Tracker ----
	-----------------------
	
	if CM_TRACKER_CLASS_ATTRIBUTES[self.class] then
		self.stackTracker = CombatMetronome:BuildStackTracker()
		self.stackTracker.indicator.ApplyDistance(self.config.indicatorSize/5, self.config.indicatorSize)
		self.stackTracker.indicator.ApplySize(self.config.indicatorSize)
		self.stackTracker.indicator.ApplyIcon()
	
		self:RegisterTracker()
		self.showSampleTracker = false
	end
	
	------------------------------
	---- Light Attack Tracker ----
	------------------------------
	
	LATracker:BuildLATracker()
	LATracker.frame:SetUnlocked(self.config.laTrackerIsUnlocked)
	LATracker:DisplayText()
	
	--------------------
	---- CC Tracker ----
	--------------------
	
	CCTracker.UI = CCTracker:BuildCCTracker()
	CCTracker.UI.indicator.ApplySize(self.config.CCTrackerSize)
	CCTracker.UI.indicator.ApplyDistance(self.config.CCTrackerSize)
	CCTracker:ApplyIcons()
	
	if CombatMetronome:CheckForCCRegister() then
		CombatMetronome:RegisterEffectsChanged()
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
        EVENT_ACTION_SLOTS_ALL_HOTBARS_UPDATED,
        function()
			self.actionSlotCache = Util.Stacks:StoreAbilitiesOnActionBar()
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
			LATracker:ManageLATracker(inCombat)
        end
    )		
end

function CombatMetronome:RegisterCM()
	EVENT_MANAGER:RegisterForUpdate(
        self.name.."Update",
        1000 / 60,
        function(...) self:Update() end
    )
    
    -- EVENT_MANAGER:RegisterForEvent(
        -- self.name.."SlotUsed",
        -- EVENT_ACTION_SLOT_ABILITY_USED,
        -- function(e, slot)
			-- d(slot)
			-- local ability = {}
            -- local actionType = GetSlotType(slot)
			-- d(actionType)
			-- if actionType == ACTION_TYPE_CRAFTED_ABILITY then --3 then
				-- d("Crafted ability executed")
				-- ability = Util.Ability:ForId(GetAbilityIdForCraftedAbilityId(GetSlotBoundId(slot)))
				-- d("Ability used - "..ability.name..", ID: "..ability.id)
			-- else
				-- ability = Util.Ability:ForId(GetSlotBoundId(slot))
			-- end
						
			-- d("Slot used - Target: "..GetAbilityTargetDescription(GetSlotBoundId(slot)).." - "..ability.name)
            -- log("Abilty used - ", ability.name)
            -- if slot == 2 then
                -- log("Cancelling heavy")
                -- self.currentEvent = nil
            -- end
        -- end
    -- )
	
	self.cmRegistered = true
	
	if self.config.trackCollectibles or (self.config.showMountNick and self.config.trackMounting) then
		CombatMetronome:RegisterCollectiblesTracker()
	end
	
	if self.config.trackItems then
		CombatMetronome:RegisterItemsTracker()
	end
	
	if CombatMetronome:CheckForCombatEventsRegister() then
		CombatMetronome:RegisterCombatEvents()
	end
	-- d("cm is registered")
end

function CombatMetronome:RegisterCollectiblesTracker()
	EVENT_MANAGER:RegisterForEvent(
		self.name.."CollectibleUsed",
		EVENT_COLLECTIBLE_UPDATED,
		function(_, id)
			local name,_,icon,_,_,_,_,type,_ = GetCollectibleInfo(id)
			if type == COLLECTIBLE_CATEGORY_TYPE_ASSISTANT or type == COLLECTIBLE_CATEGORY_TYPE_COMPANION then
				CombatMetronome:SetIconsAndNamesNil()
				self.collectibleInUse = {}
				self.collectibleInUse.name = Util.Text.CropZOSString(name)
				self.collectibleInUse.icon = icon
				zo_callLater(function() self.collectibleInUse = nil end, 1000)
			end
			if type == COLLECTIBLE_CATEGORY_TYPE_MOUNT then
				-- if id == GetActiveCollectibleByType(COLLECTIBLE_CATEGORY_TYPE_MOUNT,GAMEPLAY_ACTOR_CATEGORY_PLAYER) then
					self.activeMount.name = Util.Text.CropZOSString(GetCollectibleNickname(id))
					self.activeMount.icon = icon
					if CombatMetronome.menu.icons[2] then
						CombatMetronome.menu.icons[2]:SetTexture(icon)
					end
				-- end
			end
		end
	)
	
	self.collectiblesTrackerRegistered = true
end

function CombatMetronome:RegisterItemsTracker()
	EVENT_MANAGER:RegisterForEvent(
		self.name.."InventoryItemUsed",
		EVENT_INVENTORY_ITEM_USED,
		function()
			local bagSize = GetBagSize(1)
			CombatMetronome:SetIconsAndNamesNil()
			self.itemCache = {}
			self.itemCache.name = {}
			self.itemCache.icon = {}
			for i = 1, bagSize do
				self.itemCache.name[i] = Util.Text.CropZOSString(GetItemName(1, i))
				self.itemCache.icon[i] = GetItemInfo(1, i)
			end
			zo_callLater(function()
				self.itemCache = nil
			end,
			400)
		end
	)

	EVENT_MANAGER:RegisterForEvent(
		self.name.."InventoryItemInfo",
		EVENT_INVENTORY_SINGLE_SLOT_UPDATE,
		function(_, _, slotId, _, _, _, stackCountChange, _, _, _, _)
			if stackCountChange == -1 and self.itemCache then
				CombatMetronome:SetIconsAndNamesNil()
				self.itemUsed = {}
				self.itemUsed.name = self.itemCache.name[slotId]
				self.itemUsed.icon = self.itemCache.icon[slotId]
				zo_callLater(function()
					if self.itemUsed then
						self.itemUsed.name = nil
						self.itemUsed.icon = nil
						self.itemUsed = nil
					end
				end,
				950)
			end
		end
	)
	
	self.itemTrackerRegistered = true
end

function CombatMetronome:RegisterCombatEvents()
	EVENT_MANAGER:RegisterForEvent(
		self.name.."CombatEvents",
		EVENT_COMBAT_EVENT,
--	------------------------------
--  ---- Handle Combat Events ----
--	------------------------------
		function (_,   res,  err, aName, aGraphic, aSlotType, sName, sType, tName, 
				tType, hVal, pType, dType, _, 		sUId, 	 tUId,  aId,   _     )
			if Util.Text.CropZOSString(sName) == self.currentCharacterName then
				if IsMounted() and aId == 36432 and self.activeMount.action ~= "Dismounting" then
					CombatMetronome:SetIconsAndNamesNil()
					self.activeMount.action = "Dismounting"
				elseif not IsMounted() and aId == 36010 and self.activeMount.action ~= "Mounting" then
					CombatMetronome:SetIconsAndNamesNil()
					self.activeMount.action = "Mounting"
				elseif aId == 138780 then
					CombatMetronome:SetIconsAndNamesNil()
					self.killingAction = {}
					self.killingAction.name = Util.Text.CropZOSString(aName)
					self.killingAction.icon = "/esoui/art/icons/ability_u26_vampire_synergy_feed.dds"
				elseif aId == 146301 then
					CombatMetronome:SetIconsAndNamesNil()
					self.killingAction = {}
					self.killingAction.name = Util.Text.CropZOSString(aName)
					self.killingAction.icon = "/esoui/art/icons/achievement_u23_skillmaster_darkbrotherhood.dds"
				elseif aId == 16565 then
					CombatMetronome:SetIconsAndNamesNil()
					self.breakingFree = {}
					self.breakingFree.name = Util.Text.CropZOSString(aName)
					self.breakingFree.icon = "/esoui/art/icons/ability_rogue_050.dds"
				-- elseif aGraphic ~= nil and aName ~= nil and res == 2240 and aId ~= (36432 or 36010 or 138780 or 146301 or 16565) and aSlotType == ACTION_SLOT_TYPE_OTHER then
					-- CombatMetronome:SetIconsAndNamesNil()
					-- self.otherSynergies = {}
					-- self.otherSynergies.icon = aGraphic
					-- self.otherSynergies.name = Util.Text.CropZOSString(aName)
				end
			end
			-- if Util.Text.CropZOSString(tName) == self.currentCharacterName and not err then
				-- local newAbility = {aId, res, aName}
				-- if CCTracker.variables[res] and CCTracker.variables[res][2] then
					-- if not CCTracker:ResInList(res) then CCTracker.ccChanged = true end
					-- if not CCTracker:AIdInList(aId) then table.insert(CCTracker.cc, newAbility) end
				-- end
				-- if res == ACTION_RESULT_EFFECT_FADED then
					-- if CCTracker:AIdInList(aId) then
						-- local aIdInList, i = CCTracker:AIdInList(aId)
						-- table.remove(CCTracker.cc, i)
						-- CCTracker.ccChanged = true
					-- elseif CCTracker:NameInList(aName) then
						-- local nameInList, i = CCTracker:NameInList(aName)
						-- table.remove(CCTracker.cc, i)
						-- CCTracker.ccChanged = true
					-- end
				-- end
				-- if CCTracker.ccChanged then CCTracker:ApplyIcons() end
			-- end
		end
	)
	
	self.combatEventsRegistered = true
end

function CombatMetronome:RegisterEffectsChanged()
	EVENT_MANAGER:RegisterForEvent(
		self.name.."EffectsChanged",
		EVENT_EFFECT_CHANGED,
		function(...)
			CCTracker:HandleEffectsChanged(...)
		end
	)
	
	self.effectsChangedRegistered = true
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
		
	-- EVENT_MANAGER:UnregisterForEvent(
        -- self.name.."SlotUsed")
	
	self.cmRegistered = false
	-- d("cm is unregistered")
	
	-- EVENT_MANAGER:UnregisterForEvent(
		-- self.name.."BarSwap")
		
	-- EVENT_MANAGER:UnregisterForEvent(
		-- self.name.."RollDodge")
	
	if self.collectiblesTrackerRegistered then
		CombatMetronome:UnregisterCollectiblesTracker()
	end
	
	if self.itemsTrackerRegistered then
		CombatMetronome:UnregisterItemsTracker()
	end
	
	if self.combatEventsRegistered then
		CombatMetronome:UnregisterCombatEvents()
	end
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

function CombatMetronome:UnregisterCollectiblesTracker()
	EVENT_MANAGER:UnregisterForEvent(
		self.name.."CollectibleUsed")
		
	self.collectiblesTrackerRegistered = false
end

function CombatMetronome:UnregisterItemsTracker()
	EVENT_MANAGER:UnregisterForEvent(
		self.name.."InventoryItemUsed")
	
	EVENT_MANAGER:UnregisterForEvent(
		self.name.."InventoryItemInfo")
		
	self.itemsTrackerRegistered = false
end

function CombatMetronome:UnregisterCombatEvents()
	EVENT_MANAGER:UnregisterForEvent(
		self.name.."CombatEvents")
		
	self.combatEventsRegistered = false
end

function CombatMetronome:UnregisterEffectsChanged()
	EVENT_MANAGER:UnregisterForEvent(
		self.name.."EffectsChanged")
	
	self.effectsChangedRegistered = false
end