CM_DEFAULT_SAVED_VARS = {
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
	["labelFont"] = "$(CHAT_FONT)",
	["trackGCD"] = false,
    ["showOOC"] = true,
    ["displayPingOnHeavy"] = true,
    ["debug"] = false,
    ["globalHeavyAdjust"] = 25,
    ["globalAbilityAdjust"] = 25,
    ["abilityAdjusts"] = { },
	["showResources"] = false,
    ["showUltimate"] = true,
    ["showStamina"] = true,
	["showMagicka"] = true,
    ["showHealth"] = true,
	["colorfulResources"] = true,
	["ultColor"] = {1, 1, 1, 1},
	["magColor"] = {0, 0.5, 1, 1},
	["stamColor"] = {0, 0.8, 0.3, 1},
	["healthColor"] = {0.8, 0, 0, 1},
	["stamSize"] = 21,
	["magSize"] = 21,
	["ultSize"] = 40,
	["healthSize"] = 35,
	["showSpell"] = true,
	["showTimeRemaining"] = true,
    ["showResourcesForGuard"] = false,
    ["maxLatency"] = 150,
    ["global"] = true,
    ["hpHighlightThreshold"] = 25,
    ["reticleHp"] = false,
    ["soundTickEnabled"] = false,
    ["soundTickEffect"] = "Justice_PickpocketFailed",
    ["soundTickOffset"] = 200,
    ["soundTockEnabled"] = false,
    ["soundTockEffect"] = "Dialog_Decline",
    ["soundTockOffset"] = 300,
	["stopHATracking"] = false,
	["makeItFancy"] = false,
	["trackerIsUnlocked"] = false,
	["hideTrackerInPVP"] = false,
	["trackMW"] = false,
	["trackBA"] = false,
	["trackGF"] = false,
	["trackCrux"] = false,
	["indicatorSize"] = 30,
	["trackerX"] = 0,
	["trackerY"] = 0,
	["hideTracker"] = true,
	["trackerPlaySound"] = false,
	["hightlightOnFullStacks"] = false,
	["trackerSound"] = "Ability_Companion_Ultimate_Ready",
}

CM_TRACKER_CLASS_ATTRIBUTES = {
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
	["SOR"] = {
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
}

CM_CLASS = {
	[1] = "DK",
	[2] = "SOR",
	[3] = "NB",
	[4] = "DEN",
	[5] = "NEC",
	[6] = "TEM",
	[117] = "ARC",
}