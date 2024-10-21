CombatMetronome.StackTracker = CombatMetronome.StackTracker or {}
CombatMetronome.menu = CombatMetronome.menu or {}

CombatMetronome.DEFAULT_SAVED_VARS = {
	["version"] = 1,
	["global"] = true,
	["Progressbar"] = {
		["hideProgressbar"] = false,
		["hideCMInPVP"] = false,
		["xOffset"] = (GuiRoot:GetWidth() - 303) / 2,
		["yOffset"] = (GuiRoot:GetHeight() - 30) / 2,
		["width"] = 303,
		["height"] = 30,
		["dontHide"] = false,
		["dontShowPing"] = false,
		["lastBackgroundColor"] = { 0, 0, 0, 0.5 },
		["backgroundColor"] = { 0, 0, 0, 0.5 },
		["progressColor"] = { 1, 0.84, 0.24, 0.63 },
		["pingColor"] = { 1, 0, 0, 0.63 },
		["channelColor"] = { 1, 0, 1, 0.63},
		["colorCache"] = { 1, 0.84, 0.24, 0.63},
		["changeOnChanneled"] = false,
		["gcdAdjust"] = 0,
		["barAlign"] = "Center",
		["labelFont"] = "CHAT_FONT",
		["fontStyle"] = "outline",
		["trackGCD"] = false,
		["displayPingOnHeavy"] = true,
		["spellSize"] = 25,
		["globalHeavyAdjust"] = 25,
		["globalAbilityAdjust"] = 25,
		["abilityAdjusts"] = { },
		["showSpell"] = true,
		["showTimeRemaining"] = true,
		["soundTickEnabled"] = false,
		["tickVolume"] = 100,
		["soundTickEffect"] = "Justice_PickpocketFailed",
		["soundTickOffset"] = 200,
		["soundTockEnabled"] = false,
		["soundTockEffect"] = "Dialog_Decline",
		["soundTockOffset"] = 300,
		["stopHATracking"] = false,
		["makeItFancy"] = false,
		["maxLatency"] = 150,
		["showPingOnGCD"] = true,
	},
	["Resources"] = {
		["anchorResourcesToProgressbar"] = true,
		["hideResourcesInPVP"] = false,
		["labelFrameXOffset"] = (GuiRoot:GetWidth() - 303) / 2,
		["labelFrameYOffset"] = (GuiRoot:GetHeight() - 80) / 2,
		["labelFrameWidth"] = 303,
		["labelFrameHeight"] = 50,
		["showResources"] = false,
		["showUltimate"] = true,
		["showStamina"] = true,
		["showMagicka"] = true,
		["showHealth"] = true,
		["ultColor"] = {1, 1, 1, 1},
		["magColor"] = {0, 0.5, 1, 1},
		["stamColor"] = {0, 0.8, 0.3, 1},
		["healthColor"] = {0.8, 0, 0, 1},
		["healthHighligtColor"] = {1, 1, 1, 1},
		["stamSize"] = 21,
		["magSize"] = 21,
		["ultSize"] = 40,
		["healthSize"] = 35,
		["showResourcesForGuard"] = false,
		["hpHighlightThreshold"] = 25,
		["reticleHp"] = false,
	},
	["StackTracker"] = {
		["isUnlocked"] = false,
		["hideInPVP"] = false,
		["trackMW"] = false,
		["trackBA"] = false,
		["trackGF"] = false,
		["trackCrux"] = false,
		["trackFS"] = false,
		["indicatorSize"] = 30,
		["xOffset"] = 0,
		["yOffset"] = 0,
		["hideTracker"] = true,
		["playSound"] = false,
		["volume"] = 100,
		["hightlightOnFullStacks"] = false,
		["sound"] = "Ability_Companion_Ultimate_Ready",
	},
	["LATracker"] = {
		["xOffset"] = GuiRoot:GetWidth()/2,
		["yOffset"] = GuiRoot:GetHeight()/2,
		["width"] = 200,
		["height"] = 50,
		["choice"] = "Nothing",
		["timeTilHiding"] = 15,
	},
	["debug"] = {
		["enabled"] = false,
		["triggers"] = false,
		["triggerTimer"] = 170,
		["currentEvent"] = false,
		["eventCancel"] = false,
		["abilityUsed"] = false,
	},
}

CombatMetronome.menu.CONTROLS = {
	{
		["Name"] = "Dodgeroll",
		["Icon"] = "/esoui/art/icons/ability_rogue_035.dds",
		["Dimensions"] = 35,
		["Offset"] = -25,
	},
	{
		["Name"] = "Mounting/Dismounting",
		["Dimensions"] = 45,
		["Offset"] = -20,
	},
	{
		["Name"] = "Assistants and companions",
		["Icon"] = "/esoui/art/icons/assistant_ezabibanker.dds",
		["Dimensions"] = 45,
		["Offset"] = -20,
	},
	{
		["Name"] = "Usage of items",
		["Icon"] = "/esoui/art/tribute/tributeendofgamereward_overflow.dds",
		["Dimensions"] = 35,
		["Offset"] = -25,
	},
	{
		["Name"] = "Killing actions",
		["Icon"] = "/esoui/art/icons/achievement_u23_skillmaster_darkbrotherhood.dds",
		["Dimensions"] = 35,
		["Offset"] = -25,
	},
	{
		["Name"] = "Breaking free",
		["Icon"] = "/esoui/art/icons/ability_debuff_stun.dds",
		["Dimensions"] = 35,
		["Offset"] = -25,
	},
	{
		["Name"] = "Other synergies that cause GCD",
		["Icon"] = "/esoui/art/icons/ability_healer_017.dds",
		["Dimensions"] = 35,
		["Offset"] = -25,
	},
}

CombatMetronome.StackTracker.CLASS_ATTRIBUTES = {
	["ARC"] = {
		["iMax"] = 3,
		["graphic"] = "/esoui/art/icons/class_buff_arcanist_crux.dds",
		["highlight"] = {0,1,0,0.2},
		["highlightAnimation"] = {0.8,1,0.8,0.8},
	},
	["DK"] = {
		["iMax"] = 3,
		["graphic"] = "/esoui/art/icons/ability_dragonknight_001_b.dds",
		["highlight"] = {1,0,0,0.2},
		["highlightAnimation"] = {1,0.8,0.8,0.8},
	},
	["SORC"] = {
		["iMax"] = 4,
		["graphic"] = "/esoui/art/icons/ability_sorcerer_bound_armaments.dds",
		["highlight"] = {0,0,1,0.2},
		["highlightAnimation"] = {0.8,0.8,1,0.8},
	},
	["NB"] = {
		["iMax"] = 5,
		["icon"] = {
			["gF"] = "/esoui/art/icons/ability_nightblade_005.dds",
			["rF"] = "/esoui/art/icons/ability_nightblade_005_a.dds",
			["mR"] = "/esoui/art/icons/ability_nightblade_005_b.dds",
		},
		["graphic"] = "",
		["highlight"] = {1,0,0,0.2},
		["highlightAnimation"] = {1,0.8,0.8,0.8},
	},
	["CRO"] = {
		["iMax"] = 2,
		["icon"] = {
			["fs"] = "/esoui/art/icons/ability_necromancer_001.dds",
			["rS"] = "/esoui/art/icons/ability_necromancer_001_b.dds",
			["vS"] = "/esoui/art/icons/ability_necromancer_001_a.dds",
		},
		["graphic"] = "",
		["highlight"] = {0.3,0,1,0.2},
		["highlightAnimation"] = {0.9,0.8,1,0.8},
	},
}

CombatMetronome.StackTracker.CLASS = {
	[1] = "DK",
	[2] = "SORC",
	[3] = "NB",
	[4] = "DEN",
	[5] = "CRO",
	[6] = "PLAR",
	[117] = "ARC",
}