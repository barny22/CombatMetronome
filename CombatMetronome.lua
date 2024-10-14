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
CombatMetronome.StackTracker = CombatMetronome.StackTracker or {}
local StackTracker = CombatMetronome.StackTracker
StackTracker.name = CombatMetronome.name.."StackTracker"
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
	if _G["CombatMetronomeSavedVars"].Default[GetDisplayName()][GetCurrentCharacterId()].version == 1 then
		for charId, sv in pairs(_G["CombatMetronomeSavedVars"].Default[GetDisplayName()]) do
			if sv.version == 1 then
				_G["CombatMetronomeSavedVars"].Default[GetDisplayName()][charId] = {}
				_G["CombatMetronomeSavedVars"].Default[GetDisplayName()][charId] = CombatMetronome:ConvertSavedVariables(sv)
			end
		end
	end
	self.SV = ZO_SavedVars:NewCharacterIdSettings("CombatMetronomeSavedVars", 2, nil, self.DEFAULT_SAVED_VARS)
	if self.SV.global then
		self.SV = ZO_SavedVars:NewAccountWide("CombatMetronomeSavedVars", 2, nil, self.DEFAULT_SAVED_VARS)
		self.SV.global = true
	end
	
	self.currentCharacterName = Util.Text.CropZOSString(GetUnitName("player"))
		
	StackTracker.classId = GetUnitClassId("player")
	StackTracker.class = StackTracker.CLASS[StackTracker.classId]
	
	CCTracker.cc = {}
	CCTracker.ccCache = {}
	CCTracker.variables = {
	-- Effects Changed
	
	[32] = {["icon"] = "/esoui/art/icons/ability_debuff_disorient.dds", ["tracked"] = self.SV.CCTracker.CC.Disoriented, ["res"] = 2340, ["active"] = false, ["name"] = "Disoriented",}, --ABILITY_TYPE_DISORIENT
	[27] = {["icon"] = "/esoui/art/icons/ability_debuff_fear.dds", ["tracked"] = self.SV.CCTracker.CC.Fear, ["res"] = 2320, ["active"] = false, ["name"] = "Fear",}, --ABILITY_TYPE_FEAR
	[17] = {["icon"] = "/esoui/art/icons/ability_debuff_knockback.dds", ["tracked"] = self.SV.CCTracker.CC.Knockback, ["res"] = 2475, ["active"] = false, ["name"] = "Knockback",}, --ABILITY_TYPE_KNOCKBACK
	[48] = {["icon"] = "/esoui/art/icons/ability_debuff_levitate.dds", ["tracked"] = self.SV.CCTracker.CC.Levitate, ["res"] = 2400, ["active"] = false, ["name"] = "Levitating",}, --ABILITY_TYPE_LEVITATE
	[53] = {["icon"] = "/esoui/art/icons/ability_debuff_offbalance.dds", ["tracked"] = self.SV.CCTracker.CC.Offbalance, ["res"] = 2440, ["active"] = false, ["name"] = "Offbalance",}, --ABILITY_TYPE_OFFBALANCE
	-- ["rootPlaceholder"] = {["icon"] = "/esoui/art/icons/ability_debuff_root.dds", ["tracked"] = self.SV.CCTracker.CC.Root, ["res"] = 2480 ["active"] = false, ["name"] = "Rooted",}, --ACTION_RESULT_ROOTED
	[11] = {["icon"] = "/esoui/art/icons/ability_debuff_silence.dds", ["tracked"] = self.SV.CCTracker.CC.Silence, ["res"] = 2010, ["active"] = false, ["name"] = "Silence",}, --ABILITY_TYPE_SILENCE
	[10] = {["icon"] = "/esoui/art/icons/ability_debuff_snare.dds", ["tracked"] = self.SV.CCTracker.CC.Snare, ["res"] = 2025, ["active"] = false, ["name"] = "Snare",}, --ABILITY_TYPE_SNARE
	[33] = {["icon"] = "/esoui/art/icons/ability_debuff_stagger.dds", ["tracked"] = self.SV.CCTracker.CC.Stagger, ["res"] = 2470, ["active"] = false, ["name"] = "Stagger",}, --ABILITY_TYPE_STAGGER
	[9] = {["icon"] = "/esoui/art/icons/ability_debuff_stun.dds", ["tracked"] = self.SV.CCTracker.CC.Stun, ["res"] = 2020, ["active"] = false, ["name"] = "Stun",}, --ABILITY_TYPE_STUN
}

    -- self.log = CombatMetronome.SV.debug

    self.inCombat = IsUnitInCombat("player")
    self.currentEvent = nil
	-- self.rollDodgeFinished = true

    self.gcd = 1000

	self.Progressbar = {}
	self.Progressbar.activeMount = {}
	self.Progressbar.activeMount.name = Util.Text.CropZOSString(GetCollectibleNickname(GetActiveCollectibleByType(COLLECTIBLE_CATEGORY_TYPE_MOUNT,GAMEPLAY_ACTOR_CATEGORY_PLAYER)))
	self.Progressbar.activeMount.icon = GetCollectibleIcon(GetActiveCollectibleByType(COLLECTIBLE_CATEGORY_TYPE_MOUNT,GAMEPLAY_ACTOR_CATEGORY_PLAYER))
	self.Progressbar.activeMount.action = ""
	self.Progressbar.itemUsed = nil
	self.Progressbar.collectibleInUse = nil
    self.Progressbar.UI = CombatMetronome:BuildUI()
    CombatMetronome:BuildMenu()
	-- CombatMetronome:UpdateAdjustChoices()

    self.Progressbar.lastInterval = 0
	StackTracker.actionSlotCache = Util.Stacks:StoreAbilitiesOnActionBar()

	self:RegisterMetadata()
	
	Util.Ability.Tracker.CombatMetronome = self
    Util.Ability.Tracker:Start()
	
	-----------------------
	---- Stack Tracker ----
	-----------------------
	
	if StackTracker.CLASS_ATTRIBUTES[StackTracker.class] then
		StackTracker.UI = StackTracker:BuildUI()
		StackTracker.UI.indicator.ApplyDistance(CombatMetronome.SV.StackTracker.indicatorSize/5, CombatMetronome.SV.StackTracker.indicatorSize)
		StackTracker.UI.indicator.ApplySize(CombatMetronome.SV.StackTracker.indicatorSize)
		StackTracker.UI.indicator.ApplyIcon()
	
		StackTracker:Register()
		StackTracker.showSampleTracker = false
	end
	
	------------------------------
	---- Light Attack Tracker ----
	------------------------------
	
	LATracker:BuildUI()
	LATracker.frame:SetUnlocked(CombatMetronome.SV.LATracker.isUnlocked)
	LATracker:DisplayText()
	
	--------------------
	---- CC Tracker ----
	--------------------
	
	CCTracker.UI = CCTracker:BuildUI()
	CCTracker.UI.indicator.ApplySize(CombatMetronome.SV.CCTracker.size)
	CCTracker:ApplyIcons()
	CCTracker:Register()	
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
			StackTracker.actionSlotCache = Util.Stacks:StoreAbilitiesOnActionBar()
			-- self.menu.abilityAdjustChoices = CombatMetronome:BuildListForAbilityAdjusts()
        end
    )
	
	EVENT_MANAGER:RegisterForEvent(
		self.name.."CharacterLoaded",
		EVENT_PLAYER_ACTIVATED,
		function(_,_)
			self.inPVPZone = self:IsInPvPZone()
			self:CMPVPSwitch()
			self:ResourcesPVPSwitch()
			StackTracker:PVPSwitch()
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
	
	if CombatMetronome.SV.Progressbar.trackCollectibles or (CombatMetronome.SV.Progressbar.showMountNick and CombatMetronome.SV.Progressbar.trackMounting) then
		CombatMetronome:RegisterCollectiblesTracker()
	end
	
	if CombatMetronome.SV.Progressbar.trackItems then
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
				self.Progressbar.collectibleInUse = {}
				self.Progressbar.collectibleInUse.name = Util.Text.CropZOSString(name)
				self.Progressbar.collectibleInUse.icon = icon
				zo_callLater(function() self.Progressbar.collectibleInUse = nil end, 1000)
			end
			if type == COLLECTIBLE_CATEGORY_TYPE_MOUNT then
				-- if id == GetActiveCollectibleByType(COLLECTIBLE_CATEGORY_TYPE_MOUNT,GAMEPLAY_ACTOR_CATEGORY_PLAYER) then
					self.Progressbar.activeMount.name = Util.Text.CropZOSString(GetCollectibleNickname(id))
					self.Progressbar.activeMount.icon = icon
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
				self.Progressbar.itemUsed = {}
				self.Progressbar.itemUsed.name = self.itemCache.name[slotId]
				self.Progressbar.itemUsed.icon = self.itemCache.icon[slotId]
				zo_callLater(function()
					if self.Progressbar.itemUsed then
						self.Progressbar.itemUsed.name = nil
						self.Progressbar.itemUsed.icon = nil
						self.Progressbar.itemUsed = nil
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
				if IsMounted() and aId == 36432 and self.Progressbar.activeMount.action ~= "Dismounting" then
					CombatMetronome:SetIconsAndNamesNil()
					self.Progressbar.activeMount.action = "Dismounting"
				elseif not IsMounted() and aId == 36010 and self.Progressbar.activeMount.action ~= "Mounting" then
					CombatMetronome:SetIconsAndNamesNil()
					self.Progressbar.activeMount.action = "Mounting"
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
			if CCTracker:CheckForCCRegister() and Util.Text.CropZOSString(tName) == self.currentCharacterName and not err then
				for ccType, check in pairs(CCTracker.variables) do
					if check.tracked and check.res == res then
						-- d("caching cc ability")
						CCTracker.ccCache = {}
						local newAbility = {["type"] = ccType, ["recorded"] = GetFrameTimeMilliseconds()}
						table.insert(CCTracker.ccCache, newAbility)
						if CombatMetronome.SV.debug.ccCache then d("Caching ability "..Util.Text.CropZOSString(aName)) end
						break
					end
				end
			else return
			end
		end
	)
	
	self.combatEventsRegistered = true
end

function CCTracker:Register()
	if CCTracker:CheckForCCRegister() then
		CCTracker:RegisterEffectsChanged()
		if not CombatMetronome.combatEventsRegistered then
			CombatMetronome:RegisterCombatEvents()
			CombatMetronome.combatEventsRegistered = true
		end
	end
end

function CCTracker:RegisterEffectsChanged()
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

function StackTracker:Register()
	EVENT_MANAGER:RegisterForUpdate(
		self.name.."Update",
		1000 / 60,
		function(...) self:Update() end
	)
	self.registered = true
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
	
	if self.combatEventsRegistered and not self:CheckForCombatEventsRegister() then
		CombatMetronome:UnregisterCombatEvents()
	end
end

function CombatMetronome:UnregisterResourceTracker()
	EVENT_MANAGER:UnregisterForUpdate(
        self.name.."UpdateLabels")
		
	self.rtRegistered = false
end

function StackTracker:Unregister()
	EVENT_MANAGER:UnregisterForUpdate(
		self.name.."Update")
	
	self.registered = false
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

function CCTracker:UnregisterEffectsChanged()
	EVENT_MANAGER:UnregisterForEvent(
		self.name.."EffectsChanged")
	
	self.effectsChangedRegistered = false
end