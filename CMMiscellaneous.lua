CombatMetronome.StackTracker = CombatMetronome.StackTracker or {}
CombatMetronome.Resources = CombatMetronome.Resources or {}
CombatMetronome.menu = CombatMetronome.menu or {}

CombatMetronome.DEFAULT_SAVED_VARS = {
	["version"] = 2,
	["lastAddOnVersion"] = 0,
	["showBetaMessage"] = true,
	["automaticSVCleanup"] = {
		["enabled"] = false,
		["lastCleanup"] = {
			["year"] = 0,
			["month"] = 0,
			["day"] = 0,
		},
	},
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
		["forceSoundTock"] = true,
		["stopHATracking"] = false,
		["makeItFancy"] = false,
		["maxLatency"] = 150,
		["showPingOnGCD"] = true,
		["expandDynamically"] = false,
		["moveIconDynamically"] = true,
		["dynamicExpansionMultiplyer"] = 1,
	},
	["Resources"] = {
		["anchorResourcesToProgressbar"] = true,
		["hideResourcesInPVP"] = false,
		["xOffset"] = (GuiRoot:GetWidth() - 303) / 2,
		["yOffset"] = (GuiRoot:GetHeight() - 80) / 2,
		["width"] = 303,
		["height"] = 50,
		["showResources"] = false,
		["coralBahsei"] = false,
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
		["unlockExecuteReminder"] = false,
		["showExecuteReminder"] = false,
		["executeColor"] = {0.8, 0, 0, 1},
		["executeX"] = (GuiRoot:GetWidth() - 250) / 2,
		["executeY"] = (GuiRoot:GetHeight() - 50) / 2,
		["executeWidth"] = 303,
		["executeHeight"] = 50,
	},
	["StackTracker"] = {
		["isUnlocked"] = false,
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

local frameTexture = "/esoui/art/actionbar/abilityframe64_up.dds"
CombatMetronome.menu.CONTROLS = {
	["progressbar"] = {
		{
			["Name"] = "Dodgeroll",
			["Icon"] = "/esoui/art/icons/ability_rogue_035.dds",
			["Dimensions"] = 35,
			["Offset"] = -25,
			["SavedVars"] = "trackRolldodge",
		},
		{
			["Name"] = "Mounting/Dismounting",
			["Dimensions"] = 45,
			["Offset"] = -20,
			["SavedVars"] = "trackMounting",
		},
		{
			["Name"] = "Assistants and companions",
			["Icon"] = "/esoui/art/icons/assistant_ezabibanker.dds",
			["Dimensions"] = 45,
			["Offset"] = -20,
			["SavedVars"] = "trackCollectibles",
		},
		{
			["Name"] = "Usage of items",
			["Icon"] = "/esoui/art/tribute/tributeendofgamereward_overflow.dds",
			["Dimensions"] = 35,
			["Offset"] = -25,
			["SavedVars"] = "trackItems",
		},
		{
			["Name"] = "Synergies",
			["Icon"] = "/esoui/art/icons/achievement_u23_skillmaster_darkbrotherhood.dds",
			["Dimensions"] = 35,
			["Offset"] = -25,
			["SavedVars"] = "trackSynergies",
		},
		{
			["Name"] = "Breaking free",
			["Icon"] = "/esoui/art/icons/ability_debuff_stun.dds",
			["Dimensions"] = 35,
			["Offset"] = -25,
			["SavedVars"] = "trackBreakingFree",
		},
	},
	["stackTracker"] = {
		["MW"] = {
			["Name"] = "Track molten whip stacks",
			["subName"] = "Molten whip",
			-- ["frame"] = frameTexture,
			["icon"] = "/esoui/art/icons/ability_dragonknight_001_b.dds",
		},
		["BA"] = {
			["Name"] = "Track bound armaments stacks",
			["subName"] = "Bound armaments",
			-- ["frame"] = frameTexture,
			["icon"] = "/esoui/art/icons/ability_sorcerer_bound_armaments.dds",
		},
		["GF"] = {
			["Name"] = "Track stacks of grimm focus and its morphs",
			["subName"] = "Grimm focus (and morphs)",
			-- ["frame"] = frameTexture,
			["icon"] = "/esoui/art/icons/ability_nightblade_005.dds",
		},
		["Crux"] = {
			["Name"] = "Track crux stacks",
			["subName"] = "Crux",
			-- ["frame"] = frameTexture,
			["icon"] = "/esoui/art/icons/class_buff_arcanist_crux.dds",
		},
		["FS"] = {
			["Name"] = "Track stacks of flame skull and its morphs",
			["subName"] = "Flame skull (and morphs)",
			-- ["frame"] = frameTexture,
			["icon"] = "/esoui/art/icons/ability_necromancer_001.dds",
		},
		["FI"] = {
			["Name"] = "Track fetcher infection stack",
			["subName"] = "Fetcher infection",
			-- ["frame"] = frameTexture,
			["icon"] = "/esoui/art/icons/ability_warden_014.dds",
		},
	},
}

CombatMetronome.StackTracker.SKILL_ATTRIBUTES = {
	["Crux"] = {
		["iMax"] = 3,
		["graphic"] = "/esoui/art/icons/class_buff_arcanist_crux.dds",
		["highlight"] = {0,1,0,0.2},
		["highlightAnimation"] = {0.8,1,0.8,0.8},
		["id"] = 184220,
		["skillLineId"] = {218,219,220,315,316,317},
		-- ["skillLineIndex"] = {19,20,21},
	},
	["MW"] = {
		["iMax"] = 3,
		["graphic"] = "/esoui/art/icons/ability_dragonknight_001_b.dds",
		["highlight"] = {1,0,0,0.2},
		["highlightAnimation"] = {1,0.8,0.8,0.8},
		["id"] = { ["buff"] = 122658, ["ability"] = 20805,}, -- 122729
		["skillLineId"] = {35,297},
		-- ["skillLineIndex"] = 7,
	},
	["BA"] = {
		["iMax"] = 4,
		["graphic"] = "/esoui/art/icons/ability_sorcerer_bound_armaments.dds",
		["highlight"] = {0,0,1,0.2},
		["highlightAnimation"] = {0.8,0.8,1,0.8},
		["id"] = { ["buff"] = 203447, ["ability"] = 24165,},
		["skillLineId"] = {42,306},
		-- ["skillLineIndex"] = 2,
	},
	["GF"] = {
		["iMax"] = 5,
		["icon"] = {
			["GF"] = "/esoui/art/icons/ability_nightblade_005.dds",
			["RF"] = "/esoui/art/icons/ability_nightblade_005_a.dds",
			["MR"] = "/esoui/art/icons/ability_nightblade_005_b.dds",
		},
		["graphic"] = "",
		["highlight"] = {1,0,0,0.2},
		["highlightAnimation"] = {1,0.8,0.8,0.8},
		["id"] = {
			["GF"] = { ["buff"] = 122585, ["ability"] = 61902,},
			["MR"] = { ["buff"] = 122586, ["ability"] = 61919,},
			["RF"] = { ["buff"] = 122587, ["ability"] = 61927,},
		},
		["skillLineId"] = {38,300},
		-- ["skillLineIndex"] = 10,
	},
	["FS"] = {
		["iMax"] = 2,
		["icon"] = {
			["FS"] = "/esoui/art/icons/ability_necromancer_001.dds",
			["RS"] = "/esoui/art/icons/ability_necromancer_001_b.dds",
			["VS"] = "/esoui/art/icons/ability_necromancer_001_a.dds",
		},
		["graphic"] = "",
		["highlight"] = {0.3,0,1,0.2},
		["highlightAnimation"] = {0.9,0.8,1,0.8},
		["id"] = {
			["FS"] = { ["buff"] = 114131, ["ability"] = {
			[1] = 114108, [2] = 123683, [3] = 123685
			}},	
			["RS"] = { ["buff"] = 117638, ["ability"] = {
			[1] = 117637, [2] = 123718, [3] = 123719
			}},
			["VS"] = { ["buff"] = 117625, ["ability"] = {
			[1] = 117624, [2] = 123699, [3] = 123704
			}},
		},
		["skillLineId"] = {131,312},
		-- ["skillLineIndex"] = 16,
	},
	["FI"] = {
		["iMax"] = 1,
		["graphic"] = "/esoui/art/icons/ability_warden_014_a.dds",
		["highlight"] = {0,1,0,0.2},
		["highlightAnimation"] = {0.8,1,0.8,0.8},
		["id"] = { ["buff"] = 91416, ["ability"] = 86027,},
		["skillLineId"] = {127,309},
		-- ["skillLineIndex"] = 13,
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

CombatMetronome.Resources.EXECUTE_ABILITIES = {
	[85990] = 25, --wild guardian
	[238043] = 25, --wild guardian (vengeance)
	[85982] = 25, --feral guardian
	[85986] = 25, --eternal guardian
	[34851] = 25, --impale
	[34843] = 50, --killer's blade
	[33386] = 25, --assassin's blade
	[237603] = 25, --assassin's blade (vengeance)
	[63029] = 33, --radiant destrucion
	[237974] = 33, --radiant destrucion (vengeance)
	[63046] = 40, --radiant oppression
	[63044] = 33, --radiant glory
	[19123] = 20, --mages' wrath
	[18718] = 20, --mages' fury
	[237948] = 20, --mages' fury (vengeance)
	[19109] = 20, --endless fury
}

local function InsertSkillOptionsForStackTracker()
	for skill, _ in pairs(CombatMetronome.StackTracker.SKILL_ATTRIBUTES) do
		local skillOptions = {}
		skillOptions[skill] = {
			["tracked"] = false,
			["xOffset"] = 0,
			["yOffset"] = 0,
			["indicatorSize"] = 25,
			["hideInPVP"] = false,
			["playSound"] = false,
			["sound"] = "ABILITY_COMPANION_ULTIMATE_READY",
			["hightlightOnFullStacks"] = false,
			["volume"] = 100,
		}
		CombatMetronome.DEFAULT_SAVED_VARS.StackTracker[skill] = skillOptions[skill]
	end
end
InsertSkillOptionsForStackTracker()