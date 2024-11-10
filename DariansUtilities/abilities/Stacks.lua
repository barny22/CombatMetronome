local Util = DariansUtilities
Util.Ability = Util.Ability or { }
Util.Stacks = Util.Stacks or {}
local Stacks = Util.Stacks

--IDs for easy access

local cruxId = 184220
local dodgeId = 29721
local bAId = { ["buff"] = 203447, ["ability"] = 24165,}
local mWId = { ["buff"] = 122658, ["ability"] = 20805,} -- 122729
local gFId = {
	["gF"] = { ["buff"] = 122585, ["ability"] = 61902,},
	["mR"] = { ["buff"] = 122586, ["ability"] = 61919,},
	["rF"] = { ["buff"] = 122587, ["ability"] = 61927,},
	}
local fSId = {
	["fS"] = { ["buff"] = 114131, ["ability"] = {
	[1] = 114108, [2] = 123683, [3] = 123685
	}},	
	["rS"] = { ["buff"] = 117638, ["ability"] = {
	[1] = 117637, [2] = 123718, [3] = 123719
	}},
	["vS"] = { ["buff"] = 117625, ["ability"] = {
	[1] = 117624, [2] = 123699, [3] = 123704
	}},
	}

		---------------------------------------
        ---- Store abilities on Actionbars ----
        ---------------------------------------

function Stacks:StoreAbilitiesOnActionBar()
    local actionSlots = {}  -- Create a table to store action slots
	
	local function IsAlreadyInList(id)
		for i, entry in ipairs(actionSlots) do
			if entry.id == id then return true end
		end
		return false
	end

    for j = 0, 1 do
        for i = 3, 8 do
            local actionSlot = {}  -- Create a new table for each action slot
			local slotType = GetSlotType(i, j)
            -- setmetatable(actionSlot, {__index = index})
            if slotType then
				actionSlot.place = tostring(i .. j)
				if slotType == ACTION_TYPE_CRAFTED_ABILITY then
					actionSlot.id = GetAbilityIdForCraftedAbilityId(GetSlotBoundId(i, j))
				else
					actionSlot.id = GetSlotBoundId(i, j)
				end
				if not IsAlreadyInList(actionSlot.id) then
					actionSlot.icon = GetAbilityIcon(actionSlot.id)
					actionSlot.name = Util.Text.CropZOSString(GetAbilityName(actionSlot.id))

					table.insert(actionSlots, actionSlot)  -- Add the current action slot to the table
					if not Util.Ability.cache[actionSlot.id] then Util.Ability:ForId(actionSlot.id) end
				end
			end
        end
    end

    return actionSlots
end

	-----------------------
	---- Crux Tracking ----
	-----------------------

function Stacks:GetCurrentNumCruxOnPlayer()					-- Crux Tracking by barny (special thanks to akasha who basically did all the work)
	--local start = GetGameTimeMilliseconds()
	local crux = 0
	for i=1,GetNumBuffs("player") do
		local name,_,_,_,stack,_,_,_,_,statusEffectType,abilityId = GetUnitBuffInfo("player", i)
		if	abilityId == cruxId then
			crux = stack
			-- if self.SV.debug.enabled then CombatMetronome.debug:Print("You currently have "..tostring(crux).." Crux")
		break 
		end
	end
	-- if self.SV.debug.enabled then CombatMetronome.debug:Print(string.format("found %d crux(es); search time %d ms", crux, GetGameTimeMilliseconds() - start))
	return crux
end

	---------------------------------
	---- Bound Armaments Tracker ----
	---------------------------------

function Stacks:GetCurrentNumBAOnPlayer()
	--local start = GetGameTimeMilliseconds()
	local bAStacks = 0
	for i=1,GetNumBuffs("player") do
		local _,_,_,_,stack,_,_,_,_,_,abilityId = GetUnitBuffInfo("player", i)
		if	abilityId == bAId.buff then
			bAStacks = stack
			-- if self.SV.debug.enabled then CombatMetronome.debug:Print("You currently have "..tostring(bAStacks).." Stacks of Bound Armaments")
		break 
		end
	end
	return bAStacks
end

	-----------------------------
	---- Molten Whip Tracker ----
	-----------------------------

function Stacks:GetCurrentNumMWOnPlayer()
	--local start = GetGameTimeMilliseconds()
	local mWStacks = 0
	for i=1,GetNumBuffs("player") do
		local _,_,_,_,stack,_,_,_,_,_,abilityId = GetUnitBuffInfo("player", i)
		if	abilityId == mWId.buff then
			mWStacks = stack
			-- if self.SV.debug.enabled then CombatMetronome.debug:Print("You currently have "..tostring(mWStacks).." Stacks of Molten Whip")
		break 
		end
	end
	return mWStacks
end

	----------------------------------------------------------------
	---- Grimm Focus/Merciless Resolve/Relentless Focus Tracker ----
	----------------------------------------------------------------
	
function Stacks:CheckForGFMorph()
	local morph = ""
	local morphId = GetProgressionSkillCurrentMorphSlot(GetProgressionSkillProgressionId(1, 1, 6))
		if morphId == 0 then morph = "gF"
		elseif morphId == 1 then morph = "rF"
		elseif morphId == 2 then morph = "mR"
		end
	if morph ~= self.oldMorph and morph ~= "" then self.morphChanged = true end --self.stackTracker.indicator.ApplyIcon() end
	-- if morphChanged then if self.SV.debug.enabled then CombatMetronome.debug:Print("How dare you change morphs midgame??") end end
	self.oldMorph = morph
	return morph
end

function Stacks:GetCurrentNumGFOnPlayer()
	local morph = Stacks:CheckForGFMorph()
	local gFStacks = 0
	for i=1,GetNumBuffs("player") do
		local _,_,_,_,stack,_,_,_,_,_,abilityId = GetUnitBuffInfo("player", i)
		if	abilityId == gFId[morph].buff then
			gFStacks = stack
			-- if self.SV.debug.enabled then CombatMetronome.debug:Print("You currently have "..tostring(gFStacks).." Stacks of Grimm Focus")
		break 
		end
	end
	return gFStacks
end

	-----------------------------
	---- Necro skull Tracker ----
	-----------------------------
	
function Stacks:CheckForFSMorph()
	local morph = ""
	local morphId = GetProgressionSkillCurrentMorphSlot(GetProgressionSkillProgressionId(1, 1, 2))
		if morphId == 0 then morph = "fS"
		elseif morphId == 1 then morph = "vS"
		elseif morphId == 2 then morph = "rS"
		end
	if morph ~= self.oldMorph and morph ~= "" then self.morphChanged = true end -- CombatMetronome.stackTracker.indicator.ApplyIcon() end
	self.oldMorph = morph
	return morph
end

function Stacks:GetCurrentNumFSOnPlayer()
	local morph = Stacks:CheckForFSMorph()
	local fSStacks = 0
	local ability
	for i=2,3 do
		ability = fSId[morph].ability[i]
		for j=1,#CombatMetronome.StackTracker.actionSlotCache do
			if CombatMetronome.StackTracker.actionSlotCache[j].id == ability then
				fSStacks = i-1
				break
			end
		end
		if fSStacks ~= 0 then break	end
	end
	return fSStacks
end