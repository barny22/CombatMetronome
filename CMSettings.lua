local LAM = LibAddonMenu2
local Util = DariansUtilities

local ABILITY_ADJUST_PLACEHOLDER = "Add ability adjust"
local MAX_ADJUST = 200

local MIN_WIDTH = 50
local MAX_WIDTH = 500
local MIN_HEIGHT = 10
local MAX_HEIGHT = 100

local sounds = {
    "Justice_PickpocketFailed",
    "Dialog_Decline",
    "Ability_Ultimate_Ready_Sound", 
    "Quest_Shared", 
    "Champion_PointsCommitted", 
    "GroupElection_Requested", 
    "Duel_Boundary_Warning",
}

local fullStackSounds = {
	"ABILITY_COMPANION_ULTIMATE_READY",
	"ABILITY_WEAPON_SWAP_FAIL",
	"ANTIQUITIES_DIGGING_DIG_POWER_REFUND",
	"BATTLEGROUND_CAPTURE_AREA_CAPTURED_OTHER_TEAM",
	"BATTLEGROUND_COUNTDOWN_FINISH",
}

local labelFonts = {
	"$(MEDIUM_FONT)",
	"$(BOLD_FONT)",
	"$(CHAT_FONT)",
	"$(GAMEPAD_LIGHT_FONT)" ,
	"$(GAMEPAD_MEDIUM_FONT)",
	"$(GAMEPAD_BOLD_FONT)",
	"$(ANTIQUE_FONT)",
	"$(HANDWRITTEN_FONT)",
	"$(STONE_TABLET_FONT)",
}

function CombatMetronome:BuildMenu()
    -- sounds = { }
    -- for _, sound in pairs(SOUNDS) do
    --     sounds[#sounds + 1] = sound
    -- end

    self.menu = { }
    self.menu.abilityAdjustChoices = { }
    self.menu.curSkillName = ABILITY_ADJUST_PLACEHOLDER
    self.menu.curSkillId = -1
	self.listOfCurrentSkills = {}
	local attributes = CM_TRACKER_CLASS_ATTRIBUTES[self.class]
    self.menu.metadata = {
        type = "panel",
        name = "Combat Metronome",
        displayName = "|ce11212C|rombat |ce11212M|retronome",			-- "Combat Metronome"
        author = "Darianopolis, |ce11212b|c3645d6arny|r",
        version = ""..self.version,
		website = "https://www.esoui.com/downloads/info2373-CombatMetronomeGCDTracker.html",
		feedback = "https://www.esoui.com/portal.php?&id=386",
        slashCommand = "/cm",
        registerForRefresh = true,
    }
	-- local slotInQuestion = 1
    self.menu.options = {
        {
            type = "header",
            name = "Settings"
        },
        {
            type = "checkbox",
            name = "Account Wide",
            tooltip = "Check for account wide addon settings",
            getFunc = function() return self.config.global end,
            setFunc = function(value) 
                if self.config.global == value then return end

                if value then
                    self.config.global = true
                    self.config = ZO_SavedVars:NewAccountWide(
                        "CombatMetronomeSavedVars", 1, nil, DEFAULT_SAVED_VARS
                    )
                    self.config.global = true
                else
                    self.config = ZO_SavedVars:NewCharacterIdSettings(
                        "CombatMetronomeSavedVars", 1, nil, DEFAULT_SAVED_VARS
                    )
                    self.config.global = false
                end

                self.config.global = value
                self:UpdateAdjustChoices()
                self:BuildUI()
            end,
        },
		---------------------------
		---- Position and Size ----
		---------------------------
        {
            type = "submenu",
            name = "Position / Size",  
			controls = {
				{
					type = "checkbox",
					name = "Unlock",
					tooltip = "Reposition / resize bar by dragging center / edges.",
					getFunc = function() return self.frame.IsUnlocked() end,
					setFunc = function(value)
						self.frame:SetUnlocked(value)
					end,
				},
				{
					type = "slider",
					name = "X Offset",
					min = 0,
					--max = math.floor(GuiRoot:GetWidth() - self.config.barSize),
					max = math.floor(GuiRoot:GetWidth() - self.config.width),
					step = 1,
					getFunc = function() return self.config.xOffset end,
					setFunc = function(value) 
						self.config.xOffset = value 
						self:BuildUI()
					end,
				},
				{
					type = "button",
					name = "Center Horizontally",
					func = function()
						self.config.xOffset = math.floor((GuiRoot:GetWidth() - self.config.width) / 2)
						self:BuildUI()
					end
				},
				{
					type = "slider",
					name = "Y Offset",
					min = 0,
					--max = math.floor(GuiRoot:GetHeight() - self.config.barSize/10),
					max = math.floor(GuiRoot:GetHeight() - self.config.height),
					step = 1,
					getFunc = function() return self.config.yOffset end,
					setFunc = function(value) 
						self.config.yOffset = value 
						self:BuildUI()
					end,
				},
				{
					type = "button",
					name = "Center Vertically",
					func = function()
						self.config.yOffset = math.floor((GuiRoot:GetHeight() - self.config.height) / 2)
						self:BuildUI()
					end
				},
				{
					type = "slider",
					name = "Width",
					min = MIN_WIDTH,
					max = MAX_WIDTH,
					step = 1,
					getFunc = function() return self.config.width end,
					setFunc = function(value) 
						self.config.width = value 
						self:BuildUI()
					end,
				},
				{
					type = "slider",
					name = "Height",
					min = MIN_HEIGHT,
					max = MAX_HEIGHT,
					step = 1,
					getFunc = function() return self.config.height end,
					setFunc = function(value) 
						self.config.height = value 
						self:BuildUI()
					end,
				},
			},
		},
		-----------------
		---- Visuals ----
		-----------------
        {
            type = "submenu",
            name = "Visuals / Color / Layout",
			controls = {
				{
					type = "checkbox",
					name = "Show permanently",
					tooltip = "If you don't want to hide the cast bar when it's unused, it will display the background color.",
					getFunc = function() return self.config.dontHide end,
					setFunc = function(value)
						self.config.dontHide = value
						self:BuildUI()
					end,
				},
				{
					type = "checkbox",
					name = "Make it fancy",
					tooltip = "Have fancy effects and stuff",
					getFunc = function() return self.config.makeItFancy, self.config.lastBackgroundColor, self.config.backgroundColor end,
					setFunc = function(value)
						self.config.makeItFancy = value
						if self.config.makeItFancy then
							self.config.lastBackgroundColor = self.config.backgroundColor
							self.config.backgroundColor = {0, 0, 0, 0}
						else
							self.config.backgroundColor = self.config.lastBackgroundColor
						end
						self:BuildUI()
					end,
				},
				{
					type = "colorpicker",
					name = "Background Color",
					tooltip = "Color of the bar background",
					disabled = function()
						return (self.config.makeItFancy)
					end,
					getFunc = function() return unpack(self.config.backgroundColor) end,
					setFunc = function(r, g, b, a)
						self.config.backgroundColor = {r, g, b, a}
						self:BuildUI()
					end,
				},
				{
					type = "colorpicker",
					name = "Progress Color",
					tooltip = "Color of the progress bar",
					getFunc = function() return unpack(self.config.progressColor) end,
					setFunc = function(r, g, b, a)
						self.config.progressColor = {r, g, b, a}
						self:BuildUI()
					end,
				},
				{
					type = "colorpicker",
					name = "Ping Color",
					tooltip = "Color of the ping zone",
					getFunc = function() return unpack(self.config.pingColor) end,
					setFunc = function(r, g, b, a)
						self.config.pingColor = {r, g, b, a}
						self:BuildUI()
					end,
				},
				{
					type = "dropdown",
					name = "Alignment",
					tooltip = "Alignment of the progress bar",
					choices = {"Left", "Center", "Right"},
					getFunc = function() return self.config.barAlign end,
					setFunc = function(value)
						self.config.barAlign = value
						self:BuildUI()
					end,
				},
				{
					type = "checkbox",
					name = "Switch Progress Color while channeling",
					tooltip = "Change bar color on channeling abilities <1 second to indicate possibility to barswap, when channel is finished",
					warning = "This is experimental and might feel a little wonky",
					getFunc = function() return self.config.changeOnChanneled end,
					setFunc = function(value)
						self.config.changeOnChanneled = value
						-- self:BuildUI()
					end,
				},
				{
					type = "colorpicker",
					name = "Channel Color",
					tooltip = "Color while channelling",
					disabled = function()
						return (not self.config.changeOnChanneled)
					end,
					getFunc = function() return unpack(self.config.channelColor) end,
					setFunc = function(r, g, b, a)
						self.config.channelColor = {r, g, b, a}
						self:BuildUI()
					end,
				},
				{
					type = "dropdown",
					name = "Label font",
					tooltip = "Font that is used for labels",
					choices = labelFonts,
					getFunc = function() return self.config.labelFont end,
					setFunc = function(value)
						self.config.labelFont = value
						self:BuildUI()
					end,
				},
			},
		},
		-------------------
		---- Resources ----
		-------------------
        {
            type = "submenu",
            name = "Resources",
			controls = {
				{
					type = "checkbox",
					name = "Always show own resources",
					tooltip = "Toggle show own resources. If this is off, your resources will only be shown, when targeting units",
					disabled = function()
						return self.config.showUltimate or self.config.showStamina or self.config.showMagicka
					end,
					getFunc = function() return self.config.showResources end,
					setFunc = function(value) self.config.showResources = value end,
				},
				{
					type = "checkbox",
					name = "Show Ultimate",
					tooltip = "Toggle show ultimate above cast bar",
					getFunc = function() return self.config.showUltimate end,
					setFunc = function(value) self.config.showUltimate = value end,
				},
				{
					type = "slider",
					name = "Ultimate Label Size",
					tooltip = "Set the size of the Ultimate label",
					disabled = function()
						return (not self.config.showUltimate)
					end,
					min = 0,
					max = 50,
					step = 1,
					default = self.config.ultSize,
					getFunc = function() return self.config.ultSize end,
					setFunc = function(value)
						self.config.ultSize = value
						self:BuildUI()
					end,
				},
				{
					type = "colorpicker",
					name = "Ultimate Label Color",
					tooltip = "Color of your ultimate label",
					disabled = function()
						return (not self.config.showUltimate)
					end,
					getFunc = function() return unpack(self.config.ultColor) end,
					setFunc = function(r, g, b, a)
						self.config.ultColor = {r, g, b, a}
						self:BuildUI()
					end,
				},
				{
					type = "checkbox",
					name = "Show Stamina",
					tooltip = "Toggle show stamina above cast bar",
					getFunc = function() return self.config.showStamina end,
					setFunc = function(value) self.config.showStamina = value end,
				},
				{
					type = "slider",
					name = "Stamina Label Size",
					tooltip = "Set the size of the Stamina label",
					disabled = function()
						return (not self.config.showStamina)
					end,
					min = 0,
					max = 25,
					step = 1,
					default = self.config.stamSize,
					getFunc = function() return self.config.stamSize end,
					setFunc = function(value)
						self.config.stamSize = value
						self:BuildUI()
					end,
				},
				{
					type = "colorpicker",
					name = "Stamina Label Color",
					tooltip = "Color of your stamina label",
					disabled = function()
						return (not self.config.showStamina)
					end,
					getFunc = function() return unpack(self.config.stamColor) end,
					setFunc = function(r, g, b, a)
						self.config.stamColor = {r, g, b, a}
						self:BuildUI()
					end,
				},
				{
					type = "checkbox",
					name = "Show Magicka",
					tooltip = "Toggle show magicka above cast bar",
					getFunc = function() return self.config.showMagicka end,
					setFunc = function(value) self.config.showMagicka = value end,
				},
				{
					type = "slider",
					name = "Magicka Label Size",
					tooltip = "Set the size of the Magicka label",
					disabled = function()
						return (not self.config.showMagicka)
					end,
					min = 0,
					max = 25,
					step = 1,
					default = self.config.magSize,
					getFunc = function() return self.config.magSize end,
					setFunc = function(value)
						self.config.magSize = value
						self:BuildUI()
					end,
				},
				{
					type = "colorpicker",
					name = "Magicka Label Color",
					tooltip = "Color of your magicka label",
					disabled = function()
						return (not self.config.showMagicka)
					end,
					getFunc = function() return unpack(self.config.magColor) end,
					setFunc = function(r, g, b, a)
						self.config.magColor = {r, g, b, a}
						self:BuildUI()
					end,
				},
				{
					type = "checkbox",
					name = "Show Target Health",
					tooltip = "Toggle show target health above cast bar",
					getFunc = function() return self.config.showHealth end,
					setFunc = function(value) self.config.showHealth = value end,
				},
				{
					type = "slider",
					name = "Health Label Size",
					tooltip = "Set the size of the Health label",
					disabled = function()
						return (not self.config.showHealth)
					end,
					min = 0,
					max = 50,
					step = 1,
					default = self.config.healthSize,
					getFunc = function() return self.config.healthSize end,
					setFunc = function(value)
						self.config.healthSize = value
						self:BuildUI()
					end,
				},
				{
					type = "colorpicker",
					name = "Health Label Color",
					tooltip = "Color of target health label",
					disabled = function()
						return (not self.config.showHealth)
					end,
					getFunc = function() return unpack(self.config.healthColor) end,
					setFunc = function(r, g, b, a)
						self.config.healthColor = {r, g, b, a}
						self:BuildUI()
					end,
				},
				-- {
					-- type = "checkbox",
					-- name = "Make resources colorful",
					-- tooltip = "Magicka will be blue, stamina green and target health will be red",
					-- getFunc = function() return self.config.colorfulResources, self.config.magColor, self.config.stamColor, self.config.healthColor end,
					-- setFunc = function(value) 
						-- self.config.colorfulResources = value
						-- if self.config.colorfulResources then
							-- self.config.magColor = {0, 0.5, 1, 1}
							-- self.config.stamColor = {0, 0.8, 0.3, 1}
							-- self.config.healthColor = {0.8, 0, 0, 1}
						-- else
							-- self.config.magColor = {1, 1, 1, 1}
							-- self.config.stamColor = {1, 1, 1, 1}
							-- self.config.healthColor = {1, 1, 1, 1}
						-- end
						-- self:BuildUI()
					-- end,
				-- },
				{
					type = "checkbox",
					name = "Attach Target Health to reticle",
					tooltip = "Attach Target Health to side of reticle",
					disabled = function()
						return (not self.config.showHealth)
					end,
					getFunc = function() return self.config.reticleHp end,
					setFunc = function(value) 
						self.config.reticleHp = value
						self:BuildUI()
					end,
				},
				{
					type = "slider",
					name = "Target Health execute highlight threshold",
					tooltip = "Set the threshold for target health highlighting (Set 0% for no highlight)",
					disabled = function()
						return (not self.config.showHealth)
					end,
					min = 0,
					max = 100,
					getFunc = function() return self.config.hpHighlightThreshold end,
					setFunc = function(value) self.config.hpHighlightThreshold = value end,
				},
				{
					type = "checkbox",
					name = "Show resources when targeting guard",
					tooltip = "Show resources when targeting guard",
					getFunc = function() return self.config.showResourcesForGuard end,
					setFunc = function(value) self.config.showResourcesForGuard = value end,
				},
			},
		},
		------------------
		---- Behavior ----
		------------------
        {
            type = "submenu",
            name = "Behavior",
			controls = {
				{
					type = "slider",
					name = "Max latency",
					tooltip = "Set the maximum display latency",
					min = 0,
					max = 1000,
					step = 1,
					getFunc = function() return self.config.maxLatency end,
					setFunc = function(value) self.config.maxLatency = value end,
				},
				{
					type = "slider",
					name = "GCD Adjust",
					tooltip = "Increase/decrease the displayed GCD length",
					min = -MAX_ADJUST,
					max = MAX_ADJUST,
					step = 1,
					getFunc = function() return self.config.gcdAdjust end,
					setFunc = function(value) 
						self.config.gcdAdjust = value 
						self:BuildUI()
					end,
				},
				{
					type = "slider",
					name = "Global Heavy Attack Adjust",
					tooltip = "Increase/decrease the baseline heavy attack cast time. Additional adjustments to specific heavy types are made in addition to this",
					min = -MAX_ADJUST,
					max = MAX_ADJUST,
					step = 1,
					getFunc = function() return self.config.globalHeavyAdjust end,
					setFunc = function(value) 
						self.config.globalHeavyAdjust = value 
					end,
				},
				{
					type = "slider",
					name = "Global Ability Cast Adjust",
					tooltip = "Increase/decrease the baseline ability cast time. Additional adjustments to specific abilities are made in addition to this",
					min = -MAX_ADJUST,
					max = MAX_ADJUST,
					step = 1,
					getFunc = function() return self.config.globalAbilityAdjust end,
					setFunc = function(value)
						self.config.globalAbilityAdjust = value
					end,
				},
				--[[
				{
					type = "checkbox",
					name = "Show OOC",
					tooltip = "Track GCDs whilst out of combat",
					getFunc = function() return self.config.showOOC end,
					setFunc = function(value)
					self.config.showOOC = value
					end
					},
				]]
				{
					type = "checkbox",
					name = "Show GCD",
					tooltip = "Track GCDs whilst out of combat",
					getFunc = function() return self.config.trackGCD end,
					setFunc = function(value)
						self.config.trackGCD = value
					end,
				},
				{
					type = "checkbox",
					name = "Don't show ping zone",
					tooltip = "Don't show Ping Zone on cast bar at all",
					getFunc = function() return self.config.dontShowPing end,
					setFunc = function(value)
						self.config.dontShowPing = value
					end,
				},
				{
					type = "checkbox",
					name = "I'm no Oakensorc",
					tooltip = "Stops displaying heavy attacks on the progress bar",
					getFunc = function() return self.config.stopHATracking end,
					setFunc = function(value)
						self.config.stopHATracking = value
					end,
				},
				--[[
				{
					type = "dropdown",
					name = "Show Ping Zone",
					tooltip = "Show Ping Zone on HA and abilities', only on abilities or not at all",
					if self.config.stopHATracking then
						choices = {"Only abilities", "No"},
					else
						choices = {"On HA and abilities", "Only abilities", "No"},
					end,
					getFunc = function() return self.config.showPing end,
					setFunc = function(value)
						self.config.showPing = value
						self:BuildUI()
					end,
				},
				]]
				{
					type = "checkbox",
					name = "Display ping zone on heavy attacks",
					tooltip = "Displays heavy attacks with ping zone - Heavy attack cast will finish at start on entering ping zone "
										.."(heavy attack timing is calculated locally). This is for visual consistency",
					disabled = function()
						return (self.config.dontShowPing)
					end,
					getFunc = function() return self.config.displayPingOnHeavy end,
					setFunc = function(value)
						self.config.displayPingOnHeavy = value
					end,
				},
				{
					type = "checkbox",
					name = "Display spell name in cast bar",
					tooltip = "Displays the spell Name in the cast bar",
					getFunc = function() return self.config.showSpell end,
					setFunc = function(value) self.config.showSpell = value end,
				},
				{
					type = "checkbox",
					name = "Display time remaining in cast bar",
					tooltip = "Displays the remaining time on channel or cast in the cast bar",
					getFunc = function() return self.config.showTimeRemaining end,
					setFunc = function(value) self.config.showTimeRemaining = value end,
				},
			},
		},
		----------------
		---- Sounds ----
		----------------
        {
            type = "submenu",
            name = "Sound", 
			controls = {
				{
					type = "checkbox",
					name = "Sound 'tick'",
					tooltip = "Enable sound 'tick'",
					getFunc = function() return self.config.soundTickEnabled end,
					setFunc = function(state)
						self.config.soundTickEnabled = state
					end,
				},
				{
					type = "dropdown",
					name = "Sound 'tick' effect",
					disabled = function()
						return (not self.config.soundTickEnabled)
					end,
					choices = sounds,
					getFunc = function() return self.config.soundTickEffect end,
					setFunc = function(value)
						self.config.soundTickEffect = value
						PlaySound(value)
					end,
				},
				{
					type = "slider",
					name = "Sound 'tick' offset",
					disabled = function()
						return (not self.config.soundTickEnabled)
					end,
					min = 0,
					max = 1000,
					step =  1,
					getFunc = function() return self.config.soundTickOffset end,
					setFunc = function(value)
						self.config.soundTickOffset = value
					end,
				},

				{
					type = "checkbox",
					name = "Sound 'tock'",
					tooltip = "Offcycle sound cue",
					getFunc = function() return self.config.soundTockEnabled end,
					setFunc = function(state)
						self.config.soundTockEnabled = state
					end,
				},
				{
					type = "dropdown",
					name = "Sound 'tock' effect",
					disabled = function()
						return (not self.config.soundTockEnabled)
					end,
					choices = sounds,
					getFunc = function() return self.config.soundTockEffect end,
					setFunc = function(value)
						self.config.soundTockEffect = value
						PlaySound(value)
					end,
				},
				{
					type = "slider",
					name = "Sound 'tock' offset",
					disabled = function()
						return (not self.config.soundTockEnabled)
					end,
					min = 0,
					max = 1000,
					step = 1,
					getFunc = function() return self.config.soundTockOffset end,
					setFunc = function(value)
						self.config.soundTockOffset = value
					end,
				},
			},
		},
		-------------------------------
		---- Ability Timer Adjusts ----
		-------------------------------
        {
            type = "submenu",
            name = "Ability timer adjusts",
            description = "Adjusts timers on specific skills - This is applied ON TOP of relevant global adjust",
			controls = {
				-- {
					-- type = "dropdown",
					-- name = "Currently equipped abilities",
					-- width = "half",
					-- choices = self.listOfCurrentSkills,
					-- getFunc = function() return self.listOfCurrentSkills end,
					-- setFunc = function() end
				-- },
				-- {
					-- type = "button",
					-- name = "Build ability list",
					-- width = "half",
					-- func = function()
						-- self.listOfCurrentSkills = CombatMetronome:BuildListOfCurrentSkills()
						-- d(self.listOfCurrentSkills)
					-- end
				-- },
				{
					type = "editbox",
					name = "Add skill to adjust",
					isMultiline = false,
					-- disabled = true,
					getFunc = function() return self.menu.curSkillName end,
					setFunc = function(name)
						if not name or #name == 0 then return end
						for id = 0, 300000 do
							if CombatMetronome:CropZOSSpellName(GetAbilityName(id)) == name then
								--[[_=self.log and]] d("Found ability for "..name, "id = "..id)
								self.menu.curSkillName = name
								self.menu.curSkillId = id
								self.config.abilityAdjusts[id] = 0
								self:UpdateAdjustChoices()
								return
							end
						end
						d("CM - Could not find valid ability named "..name.."!")
					end
				},
				{
					type = "dropdown",
					name = "Select skill adjust",
					choices = self.menu.abilityAdjustChoices,
					getFunc = function() return self.menu.curSkillName end,
					setFunc = function(value) 
						self.menu.curSkillName = value
						for id, adj in pairs(self.config.abilityAdjusts) do
							if GetAbilityName(id) == value then
								self.menu.curSkillId = id
							end
						end
					end
				},
				{
					type = "slider",
					name = "Modify skill adjust",
					min = -MAX_ADJUST,
					max = MAX_ADJUST,
					step = 1,
					getFunc = function() return self.config.abilityAdjusts[self.menu.curSkillId] or 0 end,
					setFunc = function(value)
						if self.config.abilityAdjusts[self.menu.curSkillId] then
							self.config.abilityAdjusts[self.menu.curSkillId] = value
						end
					end
				},
				{
					type = "button",
					name = "Remove skill adjust",
					func = function()
						--[[_=DLog and]] d("Removing skill "..self.menu.curSkillName, "id: "..self.menu.curSkillId)
						self.config.abilityAdjusts[self.menu.curSkillId] = nil
						self:UpdateAdjustChoices()
					end
				},
			},
		},
		-----------------------
		---- Stack Tracker ----
		-----------------------
		-- if CM_TRACKER_CLASS_ATTRIBUTES[self.class] then
		{	type = "header",
			name = "Stack Tracker",
		},
		{	type = "checkbox",
			name = "Unlock Tracker",
			tooltip = "Move stack tracker",
			-- width = "half",
			disabled = function ()
				return not self:TrackerIsActive()											--CM_TRACKER_CLASS_ATTRIBUTES[self.class]
			end,
			getFunc = function() return self.config.trackerIsUnlocked end,
			setFunc = function(value)
				self.config.trackerIsUnlocked = value
				self.stackTracker.stacksWindow:SetMovable(value)
				-- self.stackTracker.stacksWindow:SetHidden(not value)
			end,
		},
		{	type = "checkbox",
			name = "Play Sound Cue when stacks are at max",
			tooltip = "Plays a sound when you are at max stacks, so you don't miss to cast your ability",
			-- width = "half",
			disabled = function ()
				return not self:TrackerIsActive()											--CM_TRACKER_CLASS_ATTRIBUTES[self.class]
			end,
			getFunc = function() return self.config.trackerPlaySound end,
			setFunc = function(value)
				self.config.trackerPlaySound = value
			end,
		},
		{
			type = "dropdown",
			name = "Select Sound",
			choices = fullStackSounds,
			default = self.config.trackerSound,
			disabled = function() return not (self:TrackerIsActive() and self.config.trackerPlaySound) end,
			getFunc = function() return self.config.trackerSound end,
			setFunc = function(value) 
				self.config.trackerSound = value
				PlaySound(SOUNDS[value])
			end
		},
		{	type = "checkbox",
			name = "Play animation when reaching full stacks",
			tooltip = "Gives you a more intense visual cue",
			-- width = "half",
			disabled = function ()
				return not self:TrackerIsActive()											--CM_TRACKER_CLASS_ATTRIBUTES[self.class]
			end,
			getFunc = function() return self.config.hightlightOnFullStacks end,
			setFunc = function(value)
				self.config.hightlightOnFullStacks = value
			end,
		},
		-- {
			-- type = "checkbox",
			-- name = "Hide Tracker",
			-- disabled = function ()
				-- return not self.stackTracker.stacksWindow
			-- end,
			-- getFunc = function() return self.config.hideTracker end,
			-- setFunc = function(value)
				-- self.config.hideTracker = value
				-- self.stackTracker.DefineFragmentScenes(not value)
			-- end,
		-- },
		-- {
			-- type = "description",
			-- titel = "I lost my stack tracker",
			-- width = "half",
		-- },
		-- {
			-- type = "button",
			-- name = "Centralize Tracker",
			-- tooltip = "This button centers the stack tracker in the middle of your screen",
			-- width = "half",
			-- disabled = function ()
				-- return not self.stackTracker.stacksWindow
			-- end,
			-- func = function()
				-- self.stackTracker.stacksWindow:SetAnchor(TOPLEFT, GuiRoot, TOPLEFT, GuiRoot:GetWidth()/2, GuiRoot:GetHeight()/2)
			-- end,
		-- },
		{
			type = "submenu",
			name = "Stack Tracker",
			tooltip = "Lets you track your stacks on e.g. crux or bound armaments. This works on Nightblade, Sorcerer, Dragonknight and Arcanist.",
			controls = {
				{	type = "slider",
					name = "Stack indicator size",
					disabled = function()
						if self.class == "ARC" and self.config.trackCrux then
							value = false
						elseif self.class == "SOR" and self.config.trackBA then
							value = false
						elseif self.class == "DK" and self.config.trackMW then
							value = false
						elseif self.class == "NB" and self.config.trackGF then
							value = false
						else
							value = true
						end
						return value
					end,
					min = 10,
					max = 60,
					step = 1,
					default = self.config.indicatorSize,
					getFunc = function() return self.config.indicatorSize end,
					setFunc = function(value)
						self.config.indicatorSize = value
						self.stackTracker.indicator.ApplySize(value)
						self.stackTracker.indicator.ApplyDistance(value/5, value)
						self.stackTracker.stacksWindow:SetDimensions((value*attributes.iMax+(value/5)*(attributes.iMax-1)), value)
						-- self.config.trackerX = self.stackTracker.stacksWindow:GetLeft()
						-- self.config.trackerY = self.stackTracker.stacksWindow:GetTop()
					end,
				},
				{
					type = "checkbox",
					name = "Track Molten Whip Stacks",
					-- warning = "If changed, will automaticly reload the UI.",
					disabled = function()
						return self.class ~= "DK"
					end,
					getFunc = function() return self.config.trackMW end,
					setFunc = function(value)
						self.config.trackMW = value
						-- ReloadUI()
					end
				},
				{
					type = "checkbox",
					name = "Track Bound Armaments Stacks",
					-- warning = "If changed, will automaticly reload the UI.",
					disabled = function()
						return self.class ~= "SOR"
					end,
					getFunc = function() return self.config.trackBA end,
					setFunc = function(value)
						self.config.trackBA = value
						-- ReloadUI()
					end
				},
				{
					type = "checkbox",
					name = "Track Stacks of Grimm Focus and its Morphs",
					-- warning = "If changed, will automaticly reload the UI.",
					disabled = function()
						return self.class ~= "NB"
					end,
					getFunc = function() return self.config.trackGF end,
					setFunc = function(value)
						self.config.trackGF = value
						-- ReloadUI()
					end
				},
				{
					type = "checkbox",
					name = "Track Crux Stacks",
					-- warning = "If changed, will automaticly reload the UI.",
					disabled = function() 
						return self.class ~= "ARC"
					end,
					getFunc = function() return self.config.trackCrux end,
					setFunc = function(value)
						self.config.trackCrux = value
						-- ReloadUI()
					end
				},
			},
		},
		-- end
		----------------------
		---- Experimental ----
		----------------------
--[[will be added again later
        {
            type = "header",
            name = "Experimental",
            description = "Features under development"
        },
        {
            type = "checkbox",
            name = "Debug",
            getFunc = function() return self.config.debug end,
            setFunc = function(value)
                self.config.debug = value
                self.log = value
            end
        },
]]
		---------------------------
		---- Get Ability Infos ----
		---------------------------
		-- {
			-- type = "slider",
			-- name = "Ability Slot",
			-- min = 1,
			-- max = 6,
			-- step = 1,
			-- default = slotInQuestion,
			-- getFunc = function() return slotInQuestion end,
			-- setFunc = function(value)
				-- slotInQuestion = value
				-- return slotInQuestion
			-- end
		-- },
		-- {
			-- type = "editbox",
			-- name = "Ability ID",
			-- isMultiline = false,
			-- disabled = true,
			-- getFunc = function()
				-- return self.actionSlotCache[slotInQuestion].id
			-- end,
			-- setFunc = function() end,
		-- },
		-- {
			-- type = "editbox",
			-- name = "Ability Name",
			-- isMultiline = false,
			-- disabled = true,
			-- getFunc = function()
				-- return self.actionSlotCache[slotInQuestion].name
			-- end,
			-- setFunc = function() end,
		-- },
		-- {
			-- type = "editbox",
			-- name = "Ability Icon",
			-- isMultiline = false,
			-- width = "half",
			-- disabled = true,
			-- getFunc = function() 
				-- return self.actionSlotCache[self.slotInQuestion].icon
			-- end,
			-- setFunc = function() end,
		-- },
		-- {
			-- type = "editbox",
			-- name = "Ability Place",
			-- isMultiline = false,
			-- width = "half",
			-- disabled = true,
			-- getFunc = function()
				-- return self.actionSlotCache[self.slotInQuestion].place
			-- end,
			-- setFunc = function() end,
		-- },
		-- {
			-- type = "button",
			-- name = "Get Ability Info",
			-- tooltip = "This button gives you Info about the chosen ability",
			-- width = "half",
			-- func = function()
				-- local ProgressionSkill = GetProgressionSkillCurrentMorphSlot(GetProgressionSkillProgressionId(1, 1, 6))
				-- local skillType,skillLineIndex,skillIndex,morphChoice,rank = GetSpecificSkillAbilityKeysByAbilityId(61902)
				-- local skillType2,skillLineIndex2,skillIndex2,morphChoice2,rank2 = GetSpecificSkillAbilityKeysByAbilityId(61919)
				-- local skillType3,skillLineIndex3,skillIndex3,morphChoice3,rank3 = GetSpecificSkillAbilityKeysByAbilityId(61927)
				-- local ProgressionRank = GetAbilityProgressionRankFromAbilityId(self.actionSlotCache[slotInQuestion].id)
				-- d(ProgressionSkill)
				-- d(skillType..","..skillLineIndex..","..skillIndex..","..morphChoice..","..rank)
				-- d(skillType2..","..skillLineIndex2..","..skillIndex2..","..morphChoice2..","..rank2)
				-- d(skillType3..","..skillLineIndex3..","..skillIndex3..","..morphChoice3..","..rank3)
				-- d(ProgressionRank)
			-- end,
		-- },
		-- {
			-- type = "button",
			-- name = "Update Actionslots",
			-- tooltip = "Does what it says",
			-- width = "half",
			-- func = function()
				-- CombatMetronome:StoreAbilitiesOnActionBar()
			-- end,
		-- },
    }

    self.menu.panel = LAM:RegisterAddonPanel(self.name.."Options", self.menu.metadata)
    LAM:RegisterOptionControls(self.name.."Options", self.menu.options)

    -- self:UpdateAdjustChoices()
end