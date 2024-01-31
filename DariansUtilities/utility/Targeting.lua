-- local Util = DAL:Ext("DariansUtilities")
local Util = DariansUtilities
Util.Targeting = { }

local log = Util.log

Util.Targeting.playerUnitId = 0
Util.Targeting.playerUnitIdUpdated = 0
Util.Targeting.PLAYER_UNIT_ID_UPDATE_INTERVAL = 15000

function Util.Targeting.isUnitPlayer(unitName, unitId)
	local self = Util.Targeting
	local time = GetFrameTimeMilliseconds()

	if not unitName or #unitName == 0 then 
		return self.playerUnitId == unitId 
	end

	if time > self.playerUnitIdUpdated + self.PLAYER_UNIT_ID_UPDATE_INTERVAL then
        local playerName = GetUnitName('player')
        local len = #playerName
        if unitName:sub(len + 1, len + 1) == "^" and unitName:sub(1, len) == playerName then
        	self.playerUnitId = unitId
        	self.playerUnitIdUpdated = time
        end
    end

    return unitId and self.playerUnitId == unitId
end

function Util.Targeting.isUnitValidCombatTarget(unitTag, guardsAreValid)
	-- if IsUnitInCombat("player") then return true end

    local targetHealth = GetUnitPower(unitTag, POWERTYPE_HEALTH)
    if targetHealth <= 1 then return false end

    local reaction = GetUnitReaction(unitTag)
    if reaction == UNIT_REACTION_FRIENDLY 
    or reaction == UNIT_REACTION_NPC_ALLY 
    or reaction == UNIT_REACTION_PLAYER_ALLY then 
        return false
    end

    if IsUnitLivestock(unitTag) then return false end

    if not guardsAreValid and (IsUnitJusticeGuard(unitTag) or IsUnitInvulnerableGuard(unitTag)) then
        return false
    end

    return true
end