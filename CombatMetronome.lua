-- local Util = DAL:Use("DariansUtilities", 6)
-- CombatMetronome = DAL:Def("CombatMetronome", 4, 1, {
--     onLoad = function(self) self:Init() end,
-- })

CombatMetronome = {
    name = "CombatMetronome",
    version = {
		["patch"] = 1,
		["major"] = 6,
		["minor"] = 15,
	},
	API = GetAPIVersion()
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

Util.onLoad(CombatMetronome, function(self) self:Init() end)

ZO_CreateStringId("SI_BINDING_NAME_COMBATMETRONOME_FORCE", "Force display")
ZO_CreateStringId("SI_BINDING_NAME_COMBATMETRONOME_TOGGLE_SOUND_CUES", "Toggle metronome sound cues")
ZO_CreateStringId("SI_BINDING_NAME_COMBATMETRONOME_TOGGLE_TICK", "Toggle 'tick'")
ZO_CreateStringId("SI_BINDING_NAME_COMBATMETRONOME_TOGGLE_TOCK", "Toggle 'tock'")

	-------------------------------------
	---- Initialize Combat Metronome ----
	-------------------------------------

function CombatMetronome:Init()

	self:CheckSavedVariables()
	
	self.SV = ZO_SavedVars:NewCharacterIdSettings("CombatMetronomeSavedVars", 2, nil, self.DEFAULT_SAVED_VARS)
	if self.SV.global then
		self.SV = ZO_SavedVars:NewAccountWide("CombatMetronomeSavedVars", 2, nil, self.DEFAULT_SAVED_VARS)
		self.SV.global = true
	end
	
	CombatMetronome.debug = LibChatMessage("|ce11212C|rombat |ce11212M|retronome", "|ce11212C|r|ce11212M|r")
	CombatMetronome.debug:SetEnabled(true)
	
	if CombatMetronome.SV.automaticSVCleanup.enabled then
		self:AutomaticSVCleanup()
	end
		
	if LibSetDetection and LibSetDetection.RegisterEvent then
		CombatMetronome.LSD = LibSetDetection
	else
		CombatMetronome.SV.Resources.coralBahsei = false
	end
	
	self.currentCharacterName = Util.Text.CropZOSString(GetUnitName("player"), "name")
	self.currentlyEquippedAbilities = {}
	CombatMetronome:BuildListOfCurrentlyEquippedAbilities()
		
	StackTracker.classId = GetUnitClassId("player")
	StackTracker.class = StackTracker.CLASS[StackTracker.classId]
	Util.Stacks:HandleMorphRegister(StackTracker.class)
	StackTracker:MorphCheck()

    -- self.log = CombatMetronome.SV.debug

    self.inCombat = IsUnitInCombat("player")
    self.currentEvent = nil
	-- self.rollDodgeFinished = true

    self.gcd = 1000

	self.Progressbar = {}
	self.Progressbar.soundTockPlayed = true
	self.Progressbar.activeMount = {}
	self.Progressbar.activeMount.name = Util.Text.CropZOSString(GetCollectibleNickname(GetActiveCollectibleByType(COLLECTIBLE_CATEGORY_TYPE_MOUNT,GAMEPLAY_ACTOR_CATEGORY_PLAYER)), "collectible")
	self.Progressbar.activeMount.icon = GetCollectibleIcon(GetActiveCollectibleByType(COLLECTIBLE_CATEGORY_TYPE_MOUNT,GAMEPLAY_ACTOR_CATEGORY_PLAYER))
	self.Progressbar.activeMount.action = ""
	self.Progressbar.itemUsed = nil
	self.Progressbar.collectibleInUse = nil
	self.Progressbar.synergy = {}
    self.Progressbar.UI = CombatMetronome:BuildUI()
    CombatMetronome:BuildMenu()
	-- CombatMetronome:UpdateAdjustChoices()

    self.Progressbar.lastInterval = 0
	StackTracker.actionSlotCache = self.currentlyEquippedAbilities.data

	
	Util.Ability.Tracker.CombatMetronome = self
    Util.Ability.Tracker:Start()
	
	-----------------------
	---- Stack Tracker ----
	-----------------------
	StackTracker.activeSkills = {}
	StackTracker:GetRelevantActiveSkillLines()
	StackTracker.registered = {}
	StackTracker.trackedIds = {}
	StackTracker.stacks = {}
	StackTracker.UI = {}
	for skill, _ in pairs(StackTracker.SKILL_ATTRIBUTES) do
		if CombatMetronome.SV.StackTracker[skill].tracked and StackTracker:IsTrackingAvailable(skill) and StackTracker:CheckIfSlotted(skill) then
			StackTracker:InitializeUI(skill)
		end
	end
	
	------------------------------
	---- Light Attack Tracker ----
	------------------------------
	
	LATracker:BuildUI()
	LATracker.frame:SetUnlocked(CombatMetronome.SV.LATracker.isUnlocked)
	LATracker:DisplayText()
	
	--------------
	-- Metadata --
	--------------
	self:RegisterMetadata()
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
			CombatMetronome:BuildListOfCurrentlyEquippedAbilities()
			StackTracker.actionSlotCache = self.currentlyEquippedAbilities.data
			for skill, _ in pairs(StackTracker.SKILL_ATTRIBUTES) do
				if StackTracker:IsTrackingAvailable(skill) and self.SV.StackTracker[skill].tracked then
					if StackTracker:CheckIfSlotted(skill) then
						StackTracker:InitializeUI(skill)
						StackTracker:Register(skill)
					elseif (skill == "FS" and StackTracker.registered.hotbarUpdate) or (skill ~= "FS" and StackTracker.registered.effectChanged and StackTracker.registered.effectChanged[skill]) and not StackTracker:CheckIfSlotted(skill) then
						StackTracker:Unregister(skill)
						StackTracker:HandleUIVisibility(skill, "NoUI")
						StackTracker:HandleUIVisibility(skill, "NoSample")
					end
				end
			end
        end
    )
	
	EVENT_MANAGER:RegisterForEvent(
		self.name.."CharacterLoaded",
		EVENT_PLAYER_ACTIVATED,
		function(_,_)
			self.inPVPZone = self:IsInPvPZone()
			self:CMPVPSwitch()
			self:ResourcesPVPSwitch()
			for skill, _ in pairs(CombatMetronome.StackTracker.SKILL_ATTRIBUTES) do	
				StackTracker:PVPSwitch(skill)
			end
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
        function(...) CombatMetronome:Update() end
    )
    
    -- EVENT_MANAGER:RegisterForEvent(
        -- self.name.."SlotUsed",
        -- EVENT_ACTION_SLOT_ABILITY_USED,
        -- function(e, slot)
			-- if self.SV.debug.enabled then CombatMetronome.debug:Print(slot) end
			-- local ability = {}
            -- local actionType = GetSlotType(slot)
			-- if self.SV.debug.enabled then CombatMetronome.debug:Print(actionType) end
			-- if actionType == ACTION_TYPE_CRAFTED_ABILITY then --3 then
				-- if self.SV.debug.enabled then CombatMetronome.debug:Print("Crafted ability executed") end
				-- ability = Util.Ability:ForId(GetAbilityIdForCraftedAbilityId(GetSlotBoundId(slot)))
				-- if self.SV.debug.enabled then CombatMetronome.debug:Print("Ability used - "..ability.name..", ID: "..ability.id) end
			-- else
				-- ability = Util.Ability:ForId(GetSlotBoundId(slot))
			-- end
						
			-- if self.SV.debug.enabled then CombatMetronome.debug:Print("Slot used - Target: "..GetAbilityTargetDescription(GetSlotBoundId(slot)).." - "..ability.name) end
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
	
	if CombatMetronome.SV.Progressbar.trackSynergies then
		CombatMetronome:RegisterSynergyChanged()
	end
	-- if self.SV.debug.enabled then CombatMetronome.debug:Print("cm is registered") end
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
				self.Progressbar.collectibleInUse.name = Util.Text.CropZOSString(name, "collectible")
				self.Progressbar.collectibleInUse.icon = icon
				zo_callLater(function() self.Progressbar.collectibleInUse = nil end, 1000)
			end
			if type == COLLECTIBLE_CATEGORY_TYPE_MOUNT then
				-- if id == GetActiveCollectibleByType(COLLECTIBLE_CATEGORY_TYPE_MOUNT,GAMEPLAY_ACTOR_CATEGORY_PLAYER) then
					self.Progressbar.activeMount.name = Util.Text.CropZOSString(GetCollectibleNickname(id), "collectible")
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
				self.itemCache.name[i] = Util.Text.CropZOSString(GetItemName(1, i), "item")
				self.itemCache.icon[i] = GetItemInfo(1, i)
			end
			-- zo_callLater(function()
				-- self.itemCache = nil
			-- end,
			-- 400)
		end
	)

	EVENT_MANAGER:RegisterForEvent(
		self.name.."InventoryItemInfo",
		EVENT_INVENTORY_SINGLE_SLOT_UPDATE,
		function(_, bagId, slotId, _, _, _, stackCountChange, _, _, _, _)
			if stackCountChange == -1 and self.itemCache then
				CombatMetronome:SetIconsAndNamesNil()
				self.Progressbar.itemUsed = {
					["name"] = self.itemCache.name[slotId],
					["icon"] = self.itemCache.icon[slotId]
				}
				zo_callLater(function()
					if self.Progressbar.itemUsed then
						self.Progressbar.itemUsed = nil
						self.itemCache = nil
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
			if Util.Text.CropZOSString(sName, "name") == self.currentCharacterName then
				if IsMounted() and aId == 36432 and self.Progressbar.activeMount.action ~= "Dismounting" then
					CombatMetronome:SetIconsAndNamesNil()
					self.Progressbar.activeMount.action = "Dismounting"
				elseif not IsMounted() and aId == 36010 and self.Progressbar.activeMount.action ~= "Mounting" then
					CombatMetronome:SetIconsAndNamesNil()
					self.Progressbar.activeMount.action = "Mounting"
				elseif aId == 87474 then
					CombatMetronome:SetIconsAndNamesNil()
					self.Progressbar.jesterFestivalCherryBlossom = true
				-- elseif aId == 138780 then
					-- CombatMetronome:SetIconsAndNamesNil()
					-- self.Progressbar.killingAction = {}
					-- self.Progressbar.killingAction.name = Util.Text.CropZOSString(aName, "ability")
					-- self.Progressbar.killingAction.icon = "/esoui/art/icons/ability_u26_vampire_synergy_feed.dds"
				-- elseif aId == 146301 then
					-- CombatMetronome:SetIconsAndNamesNil()
					-- self.Progressbar.killingAction = {}
					-- self.Progressbar.killingAction.name = Util.Text.CropZOSString(aName, "ability")
					-- self.Progressbar.killingAction.icon = "/esoui/art/icons/achievement_u23_skillmaster_darkbrotherhood.dds"
				elseif aId == 16565 then
					CombatMetronome:SetIconsAndNamesNil()
					self.Progressbar.breakingFree = {}
					self.Progressbar.breakingFree.name = Util.Text.CropZOSString(aName, "ability")
					self.Progressbar.breakingFree.icon = "/esoui/art/icons/ability_rogue_050.dds"
				-- elseif aGraphic ~= nil and aName ~= nil and res == 2240 and aId ~= (36432 or 36010 or 138780 or 146301 or 16565) and aSlotType == ACTION_SLOT_TYPE_OTHER then
					-- CombatMetronome:SetIconsAndNamesNil()
					-- self.otherSynergies = {}
					-- self.otherSynergies.icon = aGraphic
					-- self.otherSynergies.name = Util.Text.CropZOSString(aName)
				elseif self.Progressbar.synergy and self.Progressbar.synergy.name == Util.Text.CropZOSString(aName, "ability") then
					-- self.debug:Print("Synergy "..Util.Text.CropZOSString(aName, "ability").." was used")
					self.Progressbar.synergy.wasUsed = true
				end
			end
		end
	)
	
	self.combatEventsRegistered = true
end

function CombatMetronome:RegisterSynergyChanged()
	EVENT_MANAGER:RegisterForEvent(
		self.name.."SynergyChanged",
		EVENT_SYNERGY_ABILITY_CHANGED,
		function()
			local hasSynergy, name, icon, _, _ = GetCurrentSynergyInfo()
			if hasSynergy then
				-- if self.SV.debug.enabled then self.debug:Print("Found synergy: "..Util.Text.CropZOSString(name, "synergy")) end
				self.Progressbar.synergy.name = Util.Text.CropZOSString(name, "synergy")
				self.Progressbar.synergy.icon = icon
			-- else
				-- self.Progressbar.synergy = nil
				-- if self.SV.debug.enabled then self.debug:Print("Synergy deleted") end
			end
		end
	)
end

function CombatMetronome:RegisterResourceTracker()
    EVENT_MANAGER:RegisterForUpdate(
        self.name.."UpdateLabels",
        1000 / 60,
        function(...) self:UpdateLabels() end
    )
	
	if self.SV.Resources.coralBahsei and self.LSD then
		CombatMetronome:RegisterCoralBahsei()
	end
	
	self.rtRegistered = true
end

function CombatMetronome:RegisterCoralBahsei()
	local setIds = {647,587,147}
	CombatMetronome.LSD.RegisterEvent(
		LSD_EVENT_SET_CHANGE,
		CombatMetronome.name.."CoralBahseiActive",
		function(...)
			CombatMetronome:UpdateCoralBahsei(...)
		end,
		LSD_UNIT_TYPE_PLAYER,
		setIds
	)
	-- CombatMetronome.debug:Print("Coral/Bahsei active status registered")
	CombatMetronome:UpdateCoralBahsei()
	self.coralBahseiRegistered = true
end

function StackTracker:Register(skill)
	if (skill == "FS" and self.registered.hotbarUpdate) or (skill ~= "FS" and self.registered.effectChanged and self.registered.effectChanged[skill]) then
		return
	end
	self.stacks[skill] = self:GetCurrentStacks(skill)
	StackTracker:ChangeStackCount(skill, self.stacks[skill])
	if skill == "FS" and not self.registered.hotbarUpdate then
		EVENT_MANAGER:RegisterForEvent(
			self.name.."HotbarUpdateUpdate",
			EVENT_HOTBAR_SLOT_CHANGE_REQUESTED,
			function(...) self:HandleHotbarChangeRequested(...) end
		)
		self.registered.hotbarUpdate = true
		if CombatMetronome.SV.debug.enabled then CombatMetronome.debug:Print("hotbarUpdate is registered") end
	elseif skill ~= "FS" then
		if not self.registered.effectChanged then
			EVENT_MANAGER:RegisterForEvent(
				self.name.."EffectChanged",
				EVENT_EFFECT_CHANGED,
				function(...) self:HandleEffectChanged(...) end
			)
			self.registered.effectChanged = {}
		end
		self.registered.effectChanged[skill] = true
		
		local aId
		if type(self.SKILL_ATTRIBUTES[skill].id) == "number" then
			aId = self.SKILL_ATTRIBUTES[skill].id
		elseif self.SKILL_ATTRIBUTES[skill].id.buff then
			aId = self.SKILL_ATTRIBUTES[skill].id.buff
		else
			aId = self.SKILL_ATTRIBUTES[skill].id[Util.Stacks.morphs[skill]].buff
		end
		self.trackedIds[aId] = skill
		
		if CombatMetronome.SV.debug.enabled then CombatMetronome.debug:Print("effectChanged is registered") end
	end
	if CombatMetronome.SV.debug.enabled then CombatMetronome.debug:Print(skill.." tracker is registered") end
end

function CombatMetronome:UnregisterCM()
	EVENT_MANAGER:UnregisterForUpdate(
        self.name.."Update")
		
	-- EVENT_MANAGER:UnregisterForEvent(
        -- self.name.."SlotUsed")
	
	self.cmRegistered = false
	-- if self.SV.debug.enabled then CombatMetronome.debug:Print("cm is unregistered") end
	
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
	
	if self.synergyChangedRegistered then
		CombatMetronome:UnregisterSynergyChanged()
	end
end

function CombatMetronome:UnregisterResourceTracker()
	EVENT_MANAGER:UnregisterForUpdate(
        self.name.."UpdateLabels")
		
	self.rtRegistered = false
end

function CombatMetronome:UnregisterCoralBahsei()
	local setIds = {647,587}
	CombatMetronome.LSD.UnregisterEvent(
		LSD_EVENT_SET_CHANGE,
		CombatMetronome.name.."CoralBahseiActive",
		LSD_UNIT_TYPE_PLAYER,
		setIds
	)
	-- CombatMetronome.debug:Print("Coral/Bahsei active status unregistered")
	self.coralBahseiRegistered = false
end

function StackTracker:Unregister(skill)
	self.stacks[skill] = nil
	if skill == "FS" and self.registered.hotbarUpdate then
		EVENT_MANAGER:UnregisterForEvent(
			self.name.."HotbarUpdate")
		
		self.registered.hotbarUpdate = false
		if CombatMetronome.SV.debug.enabled then CombatMetronome.debug:Print("hotbarUpdate is unregistered") end
	elseif skill ~= "FS" and self.registered.effectChanged then
		self.registered.effectChanged[skill] = nil
		
		local aId
		if type(self.SKILL_ATTRIBUTES[skill].id) == "number" then
			aId = self.SKILL_ATTRIBUTES[skill].id
		elseif self.SKILL_ATTRIBUTES[skill].id.buff then
			aId = self.SKILL_ATTRIBUTES[skill].id.buff
		else
			aId = self.SKILL_ATTRIBUTES[skill].id[Util.Stacks.morphs[skill]].buff
		end
		if self.trackedIds[aId] then self.trackedIds[aId] = nil end
		
		if not self:EffectChangedShouldBeActive() then
			EVENT_MANAGER:UnregisterForEvent(
				self.name.."EffectChanged")
			
			self.registered.effectChanged = nil
		end
		if CombatMetronome.SV.debug.enabled then CombatMetronome.debug:Print("effectChanged is unregistered") end
	end
	self:HandleUIVisibility(skill, "NoUI")
	self:HandleUIVisibility(skill, "NoSample")
	if CombatMetronome.SV.debug.enabled then CombatMetronome.debug:Print(skill.." tracker is unregistered") end
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

function CombatMetronome:UnregisterCombatEvents()
	EVENT_MANAGER:UnregisterForEvent(
		self.name.."SynergyChanged")
		
	self.synergyChangedRegistered = false
end
