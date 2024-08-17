local LAM = LibAddonMenu2
local Util = DariansUtilities
Util.Text = Util.Text or {}
CombatMetronome.LATracker = CombatMetronome.LATracker or {}
local LATracker = CombatMetronome.LATracker

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
	"MEDIUM_FONT",
	"BOLD_FONT",
	"CHAT_FONT",
	"GAMEPAD_LIGHT_FONT" ,
	"GAMEPAD_MEDIUM_FONT",
	"GAMEPAD_BOLD_FONT",
	"ANTIQUE_FONT",
	"HANDWRITTEN_FONT",
	"STONE_TABLET_FONT",
}

local fontStyles = {
	"soft-shadow-thin",
	"soft-shadow-thick",
	"outline",
}

local LATrackerChoices = {
	"la/s",
	"Time between light attacks",
	"Nothing",
}

function CombatMetronome:BuildMenu()
    -- sounds = { }
    -- for _, sound in pairs(SOUNDS) do
    --     sounds[#sounds + 1] = sound
    -- end
	local LATrackerSettings = LATracker:BuildLATracker()
	local CreateIcons
	CreateIcons = function(panel)
		if panel == CombatMetronomeOptions then
			local dodgeNum, mountNum, assistantsNum, itemsNum, killingNum = CombatMetronome:CreateMenuIconsPath("Dodgeroll", "Mounting/Dismounting", "Assistants and companions", "Usage of Items", "Killing actions")
			dodgeIcon = WINDOW_MANAGER:CreateControl(nil, panel.controlsToRefresh[dodgeNum].checkbox, CT_TEXTURE)
			dodgeIcon:SetAnchor(RIGHT, panel.controlsToRefresh[dodgeNum].checkbox, LEFT, -25, 0)
			dodgeIcon:SetTexture("/esoui/art/icons/ability_rogue_035.dds")
			dodgeIcon:SetDimensions(35, 35)
			-- if self.config.trackRolldodge then
				-- dodgeIcon:SetDesaturation(0)
			-- else
				-- dodgeIcon:SetDesaturation(-100)
			-- end
			mountIcon = WINDOW_MANAGER:CreateControl(nil, panel.controlsToRefresh[mountNum].checkbox, CT_TEXTURE)
			mountIcon:SetAnchor(RIGHT, panel.controlsToRefresh[mountNum].checkbox, LEFT, -20, 0)
			mountIcon:SetTexture(self.activeMount.icon)
			mountIcon:SetDimensions(45, 45)
			-- if self.config.trackMounting then
				-- mountIcon:SetDesaturation(0)
			-- else
				-- mountIcon:SetDesaturation(-100)
			-- end
			assistantsIcon = WINDOW_MANAGER:CreateControl(nil, panel.controlsToRefresh[assistantsNum].checkbox, CT_TEXTURE)
			assistantsIcon:SetAnchor(RIGHT, panel.controlsToRefresh[assistantsNum].checkbox, LEFT, -20, 0)
			assistantsIcon:SetTexture("/esoui/art/icons/assistant_ezabibanker.dds")
			assistantsIcon:SetDimensions(45, 45)
			-- if self.config.trackCollectibles then
				-- assistantsIcon:SetColor(1,1,1,1)
			-- else
				-- assistantsIcon:SetColor(0,0,0,1)
			-- end
			itemsIcon = WINDOW_MANAGER:CreateControl(nil, panel.controlsToRefresh[itemsNum].checkbox, CT_TEXTURE)
			itemsIcon:SetAnchor(RIGHT, panel.controlsToRefresh[itemsNum].checkbox, LEFT, -25, 0)
			itemsIcon:SetTexture("/esoui/art/tribute/tributeendofgamereward_overflow.dds")
			itemsIcon:SetDimensions(35, 35)
			-- if self.config.trackItems then
				-- itemsIcon:SetDesaturation(0)
			-- else
				-- itemsIcon:SetDesaturation(-100)
			-- end
			killingIcon = WINDOW_MANAGER:CreateControl(nil, panel.controlsToRefresh[killingNum].checkbox, CT_TEXTURE)
			killingIcon:SetAnchor(RIGHT, panel.controlsToRefresh[killingNum].checkbox, LEFT, -25, 0)
			killingIcon:SetTexture("/esoui/art/icons/achievement_u23_skillmaster_darkbrotherhood.dds")
			killingIcon:SetDimensions(35, 35)
			CALLBACK_MANAGER:UnregisterCallback("LAM-PanelControlsCreated", CreateIcons)
		end
	end
	CALLBACK_MANAGER:RegisterCallback("LAM-PanelControlsCreated", CreateIcons)

    self.menu = { }
    self.menu.abilityAdjustChoices = self:CreateAdjustList()
    self.menu.curSkillName = ABILITY_ADJUST_PLACEHOLDER
    self.menu.curSkillId = -1
	-- self.listOfCurrentSkills = {}
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
		registerForDefaults = true,
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
                self:BuildProgressBar()
            end,
        },
		{
            type = "submenu",
            name = "Progressbar aka. GCD Tracker",
			tooltip = "Lets you track your GCD and helps you queuing your light attacks and spells more efficiently.",
			controls = {
				{
					type = "checkbox",
					name = "Hide GCD Tracker",
					tooltip = "Hides progress bar, in case you just need the stack tracker",
					warning = "Activating this disables all other settings regarding the GCD Tracker",
					getFunc = function() return self.config.hideProgressbar end,
					setFunc = function(value)
						self.config.hideProgressbar = value
						self.frame:SetHidden(value)
						if value then
							self:UnregisterCM()
							self.bar:SetHidden(true)
						else
							self:RegisterCM()
							self.progressbar.HiddenStates()
						end
					end,
				},
				{
					type = "checkbox",
					name = "Hide progress bar in PVP Zones",
					tooltip = "Hides progress bar in PVPZones to keep UI clean",
					disabled = function() return self.config.hideProgressbar end,
					getFunc = function() return self.config.hideCMInPVP end,
					setFunc = function(value)
						self.config.hideCMInPVP = value
						self:CMPVPSwitch()
						-- self:BuildProgressBar()
					end,
				},
				{
					type = "checkbox",
					name = "How does it look?",
					tooltip = "Shows bar at the right of the screen to check your settings. This bar is not resizable nor movable! This resets if you leave the menu.",
					warning = "This temporarily disables the Unlock function! Deactivate again to be able to unlock the bar.",
					disabled = function() return self.config.hideProgressbar end,
					default = false,
					getFunc = function() return self.showSampleBar end,
					setFunc = function(value)
						self.showSampleBar = value
						if value then
							self.progressbar.Position("Sample")
							self.frame:SetHidden(false)
						else
							self.progressbar.Position("UI")
							self.progressbar.HiddenStates()
						end
					end,
				},
		---------------------------
		---- Position and Size ----
		---------------------------
				{
					type = "submenu",
					name = "Position / Size",
					disabled = function() return self.config.hideProgressbar end,
					controls = {
						{
							type = "checkbox",
							name = "Unlock progressbar",
							tooltip = "Reposition / resize bar by dragging center / edges.",
							-- width = "half",
							disabled = function() return self.showSampleBar end,
							getFunc = function() return self.frame.IsUnlocked() end,
							setFunc = function(value)
								self.frame:SetUnlocked(value)
								if value then
									self.frame:SetDrawTier(DT_HIGH)
									self.frame:SetHidden(false)
								else
									self.frame:SetDrawTier(DT_LOW)
									self.frame:SetHidden(true)
								end
							end,
						},
						-- {
							-- type = "checkbox",
							-- name = "Show bar over settings menu",
							-- tooltip = "Shows progressbar over settings menu in unlocked mode",
							-- disabled = function() return not self.frame.IsUnlocked() end,
							-- width = "half",
							-- getFunc = function() return false end,
							-- setFunc = function(value)
								-- if value then
									-- self.frame:SetDrawTier(DT_HIGH)
									-- self.frame:SetHidden(false)
								-- elseif not self.frame.IsUnlocked() then
									-- self.frame:SetDrawTier(DT_LOW)
									-- self.frame:SetHidden(true)
								-- else
									-- self.frame:SetDrawTier(DT_LOW)
									-- self.frame:SetHidden(true)
								-- end
							-- end,
						-- },
						{
							type = "slider",
							name = "X Offset",
							min = 0,
							--max = math.floor(GuiRoot:GetWidth() - self.config.barSize),
							max = math.floor(GuiRoot:GetWidth() - self.config.width),
							step = 1,
							disabled = function() return self.showSampleBar end,
							getFunc = function() return self.config.xOffset end,
							setFunc = function(value) 
								self.config.xOffset = value
								self.progressbar.Position("UI")
								-- self:BuildProgressBar()
							end,
						},
						{
							type = "button",
							name = "Center Horizontally",
							disabled = function() return self.showSampleBar end,
							func = function()
								self.config.xOffset = math.floor((GuiRoot:GetWidth() - self.config.width) / 2)
								self.progressbar.Position("UI")
								-- self:BuildProgressBar()
							end
						},
						{
							type = "slider",
							name = "Y Offset",
							min = 0,
							--max = math.floor(GuiRoot:GetHeight() - self.config.barSize/10),
							max = math.floor(GuiRoot:GetHeight() - self.config.height),
							step = 1,
							disabled = function() return self.showSampleBar end,
							getFunc = function() return self.config.yOffset end,
							setFunc = function(value) 
								self.config.yOffset = value 
								self.progressbar.Position("UI")
								-- self:BuildProgressBar()
							end,
						},
						{
							type = "button",
							name = "Center Vertically",
							disabled = function() return self.showSampleBar end,
							func = function()
								self.config.yOffset = math.floor((GuiRoot:GetHeight() - self.config.height) / 2)
								self.progressbar.Position("UI")
								-- self:BuildProgressBar()
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
								self.progressbar.Size()
								-- self:BuildProgressBar()
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
								self.progressbar.Size()
								-- self:BuildProgressBar()
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
					disabled = function() return self.config.hideProgressbar end,
					controls = {
						{
							type = "checkbox",
							name = "Show permanently",
							tooltip = "If you don't want to hide the cast bar when it's unused, it will display the background color.",
							getFunc = function() return self.config.dontHide end,
							setFunc = function(value)
								self.config.dontHide = value
								self.progressbar.HiddenStates()
								-- self:BuildProgressBar()
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
								self.progressbar.HiddenStates()
								-- self:BuildProgressBar()
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
								self.progressbar.BarColors()
								-- self:BuildProgressBar()
							end,
						},
						{
							type = "colorpicker",
							name = "Progress Color",
							tooltip = "Color of the progress bar",
							getFunc = function() return unpack(self.config.progressColor) end,
							setFunc = function(r, g, b, a)
								self.config.progressColor = {r, g, b, a}
								self.progressbar.BarColors()
								-- self:BuildProgressBar()
							end,
						},
						{
							type = "colorpicker",
							name = "Ping Color",
							tooltip = "Color of the ping zone",
							getFunc = function() return unpack(self.config.pingColor) end,
							setFunc = function(r, g, b, a)
								self.config.pingColor = {r, g, b, a}
								self.progressbar.BarColors()
								-- self:BuildProgressBar()
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
								self.progressbar.Anchors()
								-- self:BuildProgressBar()
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
								-- self:BuildProgressBar()
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
								self.progressbar.BarColors()
								-- self:BuildProgressBar()
							end,
						},
						{
							type = "dropdown",
							name = "Label font",
							tooltip = "Font that is used for labels",
							choices = labelFonts,
							width = "half",
							getFunc = function() return self.config.labelFont end,
							setFunc = function(value)
								self.config.labelFont = value
								self.progressbar.Fonts()
								LATrackerSettings.LabelSettings()
								-- self:BuildProgressBar()
							end,
						},
						{
							type = "dropdown",
							name = "Font Style",
							tooltip = "Font style that is used for labels",
							choices = fontStyles,
							width = "half",
							getFunc = function() return self.config.fontStyle end,
							setFunc = function(value)
								self.config.fontStyle = value
								self.progressbar.Fonts()
								LATrackerSettings.LabelSettings()
								-- self:BuildProgressBar()
							end,
						},
					},
				},
		------------------
		---- Behavior ----
		------------------
				{
					type = "submenu",
					name = "Behavior",
					disabled = function() return self.config.hideProgressbar end,
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
								-- self:BuildProgressBar()
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
							type = "submenu",
							name = "Show further gcd information",
							disabled = function() return not self.config.trackGCD end,
							controls = {
								{
									type = "checkbox",
									name = "Dodgeroll",
									disabled = function() return not self.config.trackGCD end,
									default = false,
									getFunc = function() return self.config.trackRolldodge end,
									setFunc = function(value)
										self.config.trackRolldodge = value
										-- if value then
											-- dodgeIcon:SetDesaturation(0)
										-- else
											-- dodgeIcon:SetDesaturation(-100)
										-- end
									end,
								},
								{
									type = "checkbox",
									name = "Mounting/Dismounting",
									disabled = function() return not self.config.trackGCD end,
									default = false,
									getFunc = function() return self.config.trackMounting end,
									setFunc = function(value)
										self.config.trackMounting = value
										if value then
											-- mountIcon:SetDesaturation(0)
											if not self.mountingTrackerRegistered then
												CombatMetronome:RegisterMountingTracker()
											end
											if self.config.showMountNick and not self.collectiblesTrackerRegistered then
												CombatMetronome:RegisterCollectiblesTracker()
											end
										else
											-- mountIcon:SetDesaturation(-100)
											if self.mountingTrackerRegistered and not self.config.trackKillingActions then
												CombatMetronome:UnregisterMountingTracker()
											end
											if not self.config.trackCollectibles and self.collectiblesTrackerRegistered then
												CombatMetronome:UnregisterCollectiblesTracker()
											end
										end
									end,
								},
								{
									type = "checkbox",
									name = "Show mount nickname",
									disabled = function() return not self.config.trackMounting end,
									default = false,
									getFunc = function() return self.config.showMountNick end,
									setFunc = function(value)
										self.config.showMountNick = value
										if value then
											if not self.collectiblesTrackerRegistered then
												CombatMetronome:RegisterCollectiblesTracker()
											end
										else
											if not self.config.trackCollectibles and self.collectiblesTrackerRegistered then
												CombatMetronome:UnregisterCollectiblesTracker()
											end
										end
									end,
								},
								{
									type = "checkbox",
									name = "Assistants and companions",
									disabled = function() return not self.config.trackGCD end,
									default = false,
									getFunc = function() return self.config.trackCollectibles end,
									setFunc = function(value)
										self.config.trackCollectibles = value
										if value then
											-- assistantsIcon:SetDesaturation(0)
											if not self.CollectiblesTrackerRegistered then
												CombatMetronome:RegisterCollectiblesTracker()
											end
										else
											-- assistantsIcon:SetDesaturation(-100)
											if self.collectiblesTrackerRegistered and not self.config.showMountNick then
												CombatMetronome:UnregisterCollectiblesTracker()
											end
										end
									end,
								},
								{
									type = "checkbox",
									name = "Usage of Items",
									disabled = function() return not self.config.trackGCD end,
									default = false,
									getFunc = function() return self.config.trackItems end,
									setFunc = function(value)
										self.config.trackItems = value
										-- if value then
											-- itemsIcon:SetDesaturation(0)
										-- else
											-- itemsIcon:SetDesaturation(-100)
										-- end
										if value and not self.itemsTrackerRegistered then
											CombatMetronome:RegisterItemsTracker()
										elseif not value and self.itemsTrackerRegistered then
											CombatMetronome:UnregisterItemsTracker()
										end
									end,
								},
								{
									type = "checkbox",
									name = "Killing actions",
									tooltip = "Toggle displaying killing actions like vampire feed and blade of woe",
									disabled = function() return not self.config.trackGCD end,
									default = false,
									getFunc = function() return self.config.trackKillingActions end,
									setFunc = function(value)
										self.config.trackKillingActions = value
										-- if value then
											-- itemsIcon:SetDesaturation(0)
										-- else
											-- itemsIcon:SetDesaturation(-100)
										-- end
										if value and not self.mountingAndKillingTrackerRegistered then
											CombatMetronome:RegisterMountingAndKillingTracker()
										elseif not value and self.mountingAndKillingTrackerRegistered and not self.config.trackMounting then
											CombatMetronome:UnregisterMountingAndKillingTracker()
										end
									end,
								},
								-- {
									-- type = "submenu",
									-- name = "Collectible types",
									-- disabled = function() return not self.config.trackCollectibles end,
									-- controls = {
										-- {
											-- type = "checkbox",
											-- name = "Assistants",
											-- disabled = function() return not self.config.trackCollectibles end,
											-- default = false,
											-- getFunc = function() return self.config.trackRolldodge end,
											-- setFunc = function(value)
												-- self.config.trackRolldodge = value
											-- end,
										-- },
										-- {
											-- type = "checkbox",
											-- name = "Companions",
											-- disabled = function() return not self.config.trackCollectibles end,
											-- default = false,
											-- getFunc = function() return self.config.trackRolldodge end,
											-- setFunc = function(value)
												-- self.config.trackRolldodge = value
											-- end,
										-- },
										-- {
											-- type = "checkbox",
											-- name = "Costumes",
											-- disabled = function() return not self.config.trackCollectibles end,
											-- default = false,
											-- getFunc = function() return self.config.trackRolldodge end,
											-- setFunc = function(value)
												-- self.config.trackRolldodge = value
											-- end,
										-- },
										-- {
											-- type = "checkbox",
											-- name = "Polymorphs",
											-- disabled = function() return not self.config.trackCollectibles end,
											-- default = false,
											-- getFunc = function() return self.config.trackRolldodge end,
											-- setFunc = function(value)
												-- self.config.trackRolldodge = value
											-- end,
										-- },
										-- {
											-- type = "checkbox",
											-- name = "Vanity pets",
											-- disabled = function() return not self.config.trackCollectibles end,
											-- default = false,
											-- getFunc = function() return self.config.trackRolldodge end,
											-- setFunc = function(value)
												-- self.config.trackRolldodge = value
											-- end,
										-- },
									-- },
								-- },
							},
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
								self:BuildProgressBar()
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
							setFunc = function(value)
								self.config.showSpell = value
							end,
						},
						{
							type = "checkbox",
							name = "Display time remaining in cast bar",
							tooltip = "Displays the remaining time on channel or cast in the cast bar",
							getFunc = function() return self.config.showTimeRemaining end,
							setFunc = function(value)
								self.config.showTimeRemaining = value
							end,
						},
					},
				},
		----------------
		---- Sounds ----
		----------------
				{
					type = "submenu",
					name = "Sound", 
					disabled = function() return self.config.hideProgressbar end,
					controls = {
						{
							type = "slider",
							name = "Volume of 'tick' and 'tock'",
							tooltip = "Adjust volume of tick and tock effects",
							warning = "You may have to adjust your general audio settings and general audio volume for this to have a noticable effect. Take care not to overadjust, your ears can only take so much!",
							disabled = function() return not (self.config.soundTickEnabled or self.config.soundTockEnabled) end,
							min = 0,
							max = 100,
							setp = 1,
							getFunc = function() return self.config.tickVolume end,
							setFunc = function(value) self.config.tickVolume = value end,
						},
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
					disabled = function() return self.config.hideProgressbar end,
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
									if Util.Text.CropZOSString(GetAbilityName(id)) == name then
										--[[_=self.log and]] d("Found ability for '"..name.."'", "id: "..id)
										self.menu.curSkillName = name
										self.menu.curSkillId = id
										self.config.abilityAdjusts[id] = 0
										self:UpdateAdjustChoices()
										break
									elseif id == 300000 then
										d("CM - Could not find valid ability named "..name.."!")
									end
								end
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
									if Util.Text.CropZOSString(GetAbilityName(id)) == value then
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
							getFunc = function()
								for id, adj in pairs(self.config.abilityAdjusts) do
									if Util.Text.CropZOSString(GetAbilityName(id)) == self.menu.curSkillName then
										self.menu.curSkillId = id
									end
								end
								return self.config.abilityAdjusts[self.menu.curSkillId] or 0
							end,
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
								--[[_=DLog and]] d("Removing skill '"..self.menu.curSkillName.."'", "id: "..self.menu.curSkillId)
								self.config.abilityAdjusts[self.menu.curSkillId] = nil
								self:UpdateAdjustChoices()
							end
						},
					},
				},
			},
		},
		{	type = "divider",},
		-------------------
		---- Resources ----
		-------------------
		{	type = "submenu",
			name = "Resources",
			tooltip = "To keep track of your resources on a different bar",
			controls = {
				{
					type = "checkbox",
					name = "Unlock resource bar",
					tooltip = "Reposition / resize resourcebar by dragging center / edges.",
					disabled = function () return self.config.anchorResourcesToProgressbar or self.showSampleResources end,
					getFunc = function() return self.labelFrame.IsUnlocked() end,
					setFunc = function(value)
						self.labelFrame:SetUnlocked(value)
						if value then
							self.labelFrame:SetDrawTier(DT_HIGH)
							self.labelFrame:SetHidden(false)
						else
							self.labelFrame:SetDrawTier(DT_LOW)
							self.labelFrame:SetHidden(true)
						end
					end,
				},
				{
					type = "checkbox",
					name = "Anchor resource tracker atop the progressbar",
					tooltip = "If turned off, resourcebar can be dragged or resized independently",
					warning = "Turning this off will automaticly resize resourcebar to fit your GCD bar!",
					disabled = function()
						return not (self.config.showUltimate or self.config.showStamina or self.config.showMagicka or self.config.showHealth) or self.labelFrame.IsUnlocked()
					end,
					getFunc = function() return self.config.anchorResourcesToProgressbar end,
					setFunc = function(value)
						self.config.anchorResourcesToProgressbar = value
						self.progressbar.Size()
						if self.showSampleResources then
							self.progressbar.ResourcesPosition("Sample")
						end
					end,
				},
				{
					type = "checkbox",
					name = "Hide resource tracker in PVP Zones",
					tooltip = "Hides resource tracker in PVPZones to keep UI clean",
					disabled = function()
						return not (self.config.showUltimate or self.config.showStamina or self.config.showMagicka or self.config.showHealth)
					end,
					getFunc = function() return self.config.hideResourcesInPVP end,
					setFunc = function(value)
						self.config.hideResourcesInPVP = value
					end,
				},
				{
					type = "checkbox",
					name = "How does it look?",
					tooltip = "Shows resourcebar at the right of the screen to check your settings. This resourcebar is not movable!",
					warning = "This temporarily disables the Unlock function! Deactivate again to be able to unlock the tracker. This resets, if you leave the menu.",
					default = false,
					disabled = function()
						return not (self.config.showUltimate or self.config.showStamina or self.config.showMagicka or self.config.showHealth)
					end,
					getFunc = function() return self.showSampleResources end,
					setFunc = function(value)
						self.showSampleResources = value
						if value then
							self.progressbar.ResourcesPosition("Sample")
							self.labelFrame:SetHidden(false)
						else
							self.progressbar.ResourcesPosition("UI")
							self.progressbar.HiddenStates()
						end
					end,
				},
				{
					type = "submenu",
					name = "Configuration",
					-- disabled = function() return self.config.hideProgressbar end,
					controls = {
						{
							type = "checkbox",
							name = "Always show own resources",
							tooltip = "Toggle show own resources. If this is off, your resources will only be shown, when targeting units",
							disabled = function()
								return not (self.config.showUltimate or self.config.showStamina or self.config.showMagicka or self.config.showHealth)
							end,
							getFunc = function() return self.config.showResources end,
							setFunc = function(value) self.config.showResources = value end,
						},
						{
							type = "checkbox",
							name = "Show Ultimate",
							tooltip = "Toggle show ultimate above cast bar",
							getFunc = function() return self.config.showUltimate end,
							setFunc = function(value)
								self.config.showUltimate = value
							end,
						},
						{
							type = "slider",
							name = "Ultimate Label Size",
							tooltip = "Set the size of the Ultimate label",
							disabled = function()
								return (not self.config.showUltimate)
							end,
							min = 0,
							max = self.config.labelFrameHeight,
							step = 1,
							default = self.config.ultSize,
							getFunc = function() return self.config.ultSize end,
							setFunc = function(value)
								self.config.ultSize = value
								self.progressbar.Fonts()
								-- self:BuildProgressBar()
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
								self.progressbar.LabelColors()
								-- self:BuildProgressBar()
							end,
						},
						{
							type = "checkbox",
							name = "Show Stamina",
							tooltip = "Toggle show stamina above cast bar",
							getFunc = function() return self.config.showStamina end,
							setFunc = function(value)
								self.config.showStamina = value
							end,
						},
						{
							type = "slider",
							name = "Stamina Label Size",
							tooltip = "Set the size of the Stamina label",
							disabled = function()
								return (not self.config.showStamina)
							end,
							min = 0,
							max = self.config.labelFrameHeight/2,
							step = 1,
							default = self.config.stamSize,
							getFunc = function() return self.config.stamSize end,
							setFunc = function(value)
								self.config.stamSize = value
								self.progressbar.Fonts()
								-- self:BuildProgressBar()
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
								self.progressbar.LabelColors()
								-- self:BuildProgressBar()
							end,
						},
						{
							type = "checkbox",
							name = "Show Magicka",
							tooltip = "Toggle show magicka above cast bar",
							getFunc = function() return self.config.showMagicka end,
							setFunc = function(value)
								self.config.showMagicka = value
								-- self.sampleBar.Mag:SetHidden(not value)
							end,
						},
						{
							type = "slider",
							name = "Magicka Label Size",
							tooltip = "Set the size of the Magicka label",
							disabled = function()
								return (not self.config.showMagicka)
							end,
							min = 0,
							max = self.config.labelFrameHeight/2,
							step = 1,
							default = self.config.magSize,
							getFunc = function() return self.config.magSize end,
							setFunc = function(value)
								self.config.magSize = value
								self.progressbar.Fonts()
								-- self:BuildProgressBar()
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
								self.progressbar.LabelColors()
								-- self:BuildProgressBar()
							end,
						},
						{
							type = "checkbox",
							name = "Show Target Health",
							tooltip = "Toggle show target health above cast bar",
							getFunc = function() return self.config.showHealth end,
							setFunc = function(value)
								self.config.showHealth = value
							end,
						},
						{
							type = "slider",
							name = "Health Label Size",
							tooltip = "Set the size of the Health label",
							disabled = function()
								return (not self.config.showHealth)
							end,
							min = 0,
							max = self.config.labelFrameHeight,
							step = 1,
							default = self.config.healthSize,
							getFunc = function() return self.config.healthSize end,
							setFunc = function(value)
								self.config.healthSize = value
								self.progressbar.Fonts()
								-- self:BuildProgressBar()
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
								self.progressbar.LabelColors()
								-- self:BuildProgressBar()
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
								-- self:BuildProgressBar()
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
								self.progressbar.Anchors()
								-- self:BuildProgressBar()
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
							type = "colorpicker",
							name = "Health Highlight Color",
							tooltip = "Color of target health label",
							disabled = function()
								return (not (self.config.hpHighlightThreshold ~= 0 and self.config.showHealth))
							end,
							getFunc = function() return unpack(self.config.healthHighligtColor) end,
							setFunc = function(r, g, b, a)
								self.config.healthHighligtColor = {r, g, b, a}
								self.progressbar.LabelColors()
								-- self:BuildProgressBar()
								end,
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
			},
		},
		{	type = "divider",},
		-----------------------
		---- Stack Tracker ----
		-----------------------
		-- if CM_TRACKER_CLASS_ATTRIBUTES[self.class] then
		{	type = "submenu",
			name = "Stack Tracker",
			tooltip = "Lets you track your stacks on e.g. crux or bound armaments. This works on Nightblade, Sorcerer, Dragonknight and Arcanist.",
			controls = {
				{
					type = "checkbox",
					name = "Hide tracker in PVP Zones",
					tooltip = "Hides stack tracker in PVPZones to keep UI clean",
					disabled = function ()
						return not self:TrackerIsActive()											--CM_TRACKER_CLASS_ATTRIBUTES[self.class]
					end,
					getFunc = function() return self.config.hideTrackerInPVP end,
					setFunc = function(value)
						self.config.hideTrackerInPVP = value
						self:TrackerPVPSwitch()
					end,
				},
				{
					type = "checkbox",
					name = "How does it look?",
					tooltip = "Shows tracker at the right of the screen to check your settings. This tracker is not movable!",
					warning = "This temporarily disables the Unlock function! Deactivate again to be able to unlock the tracker. This resets, if you leave the menu.",
					default = false,
					disabled = function ()
						return not (self:TrackerIsActive() and self:CheckIfSlotted())					--CM_TRACKER_CLASS_ATTRIBUTES[self.class]
					end,
					getFunc = function() return (self.showSampleTracker and self:TrackerIsActive() and self:CheckIfSlotted()) end,
					setFunc = function(value)
						self.showSampleTracker = value
						if value then
							self.stackTracker.Position("Sample")
							self.stackTracker.FadeScenes("Sample")
						else
							self.stackTracker.Position("UI")
							self.stackTracker.FadeScenes("NoSample")
						end
					end,
				},
		---------------------------
		---- Position and Size ----
		---------------------------
				{
					type = "submenu",
					name = "Position and size",
					disabled = function ()
						return not CM_TRACKER_CLASS_ATTRIBUTES[self.class]
					end,
					controls = {
						{	type = "checkbox",
							name = "Unlock Tracker",
							tooltip = "Move stack tracker",
							-- width = "half",
							disabled = function ()
								return not (self:TrackerIsActive() and self:CheckIfSlotted()) or self.showSampleTracker		--CM_TRACKER_CLASS_ATTRIBUTES[self.class]
							end,
							getFunc = function() return self.config.trackerIsUnlocked end,
							setFunc = function(value)
								self.config.trackerIsUnlocked = value
								self.stackTracker.stacksWindow:SetMovable(value)
								if not value then
									self.stackTracker.stacksWindow:SetHidden(true)
								-- if value then
									-- self.stackTracker.stacksWindow:SetDrawTier(DT_HIGH)
								-- else
									self.stackTracker.stacksWindow:SetDrawTier(DT_LOW)
								end
							end,
						},
						-- {
							-- type = "checkbox",
							-- name = "Show tracker over settings menu",
							-- tooltip = "Shows tracker over settings menu in unlocked mode",
							-- disabled = function() return not self.config.trackerIsUnlocked end,
							-- width = "half",
							-- getFunc = function() return false end,
							-- setFunc = function(value)
								-- if self:TrackerIsActive() then
									-- self.stackTracker.stacksWindow:SetHidden(not value)
									-- if value then
										-- self.stackTracker.stacksWindow:SetDrawTier(DT_HIGH)
									-- else
										-- self.stackTracker.stacksWindow:SetDrawTier(DT_LOW)
									-- end
								-- end
							-- end,
						-- },
						{	type = "slider",
							name = "Stack indicator size",
							disabled = function()
								if self.class == "ARC" and self.config.trackCrux then
									value = false
								elseif self.class == "SORC" and self.config.trackBA then
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
							end,
						},
					},
				},
		-------------------------
		---- Stacks to track ----
		-------------------------
				{
					type = "submenu",
					name = "Stacks to track",
					disabled = function ()
						return not CM_TRACKER_CLASS_ATTRIBUTES[self.class]
					end,
					controls = {
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
								return self.class ~= "SORC"
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
						{
							type = "checkbox",
							name = "Track Stacks of flame skull and its Morphs",
							-- warning = "If changed, will automaticly reload the UI.",
							disabled = function()
								return self.class ~= "CRO"
							end,
							getFunc = function() return self.config.trackFS end,
							setFunc = function(value)
								self.config.trackFS = value
								-- ReloadUI()
							end
						},
					},
				},
		--------------------------
		---- Tracker Behavior ----
		--------------------------
				{
					type = "submenu",
					name = "Audio and visual cues",
					tooltip = "Settings regarding audio and visual cues when reaching full stacks",
					disabled = function ()
						return not CM_TRACKER_CLASS_ATTRIBUTES[self.class]
					end,
					controls = {
						{	type = "checkbox",
							name = "Play sound cue at max stacks",
							tooltip = "Plays a sound when you are at max stacks, so you don't miss to cast your ability",
							disabled = function ()
								return not self:TrackerIsActive()											--CM_TRACKER_CLASS_ATTRIBUTES[self.class]
							end,
							getFunc = function() return self.config.trackerPlaySound end,
							setFunc = function(value) self.config.trackerPlaySound = value end,
						},
						{
							type = "slider",
							name = "Sound cue volume",
							tooltip = "Adjust volume of the sound cue effect",
							warning = "You may have to adjust your general audio settings and general audio volume for this to have a noticable effect. Take care not to overadjust, your ears can only take so much!",
							disabled = function() return not self.config.trackerPlaySound end,
							min = 0,
							max = 100,
							setp = 1,
							getFunc = function() return self.config.trackerVolume end,
							setFunc = function(value) self.config.trackerVolume = value end,
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
					},
				},
			},
		},
		{	type = "divider",},
		------------------------------
		---- Light Attack Tracker ----
		------------------------------
		{	type = "submenu",
			name = "Light Attack Tracker",
			tooltip = "Lets you track your light attacks, to better analyze your parses",
			controls = {
				{
					type = "checkbox",
					name = "Hide la tracker in PVP Zones",
					tooltip = "Hides la tracker in PVPZones to keep UI clean",
					default = true,
					disabled = function()
						return self.config.laTrackerChoice == "Nothing"
					end,
					getFunc = function() return self.config.hideLATrackerInPVP end,
					setFunc = function(value)
						self.config.hideLATrackerInPVP = value
						LATracker:DisplayText()
					end,
				},
				{	type = "checkbox",
					name = "Unlock light attack tracker",
					tooltip = "Enable moving the tracker label",
					default = false,
					getFunc = function() return self.config.laTrackerIsUnlocked end,
					setFunc = function(value)
						self.config.laTrackerIsUnlocked = value
						LATracker.frame:SetUnlocked(value)
						if value then
							LATracker.frame:SetDrawTier(DT_HIGH)
							LATracker.frame:SetHidden(false)
						else
							LATracker.frame:SetDrawTier(DT_LOW)
							LATracker.frame:SetHidden(true)
						end
					end,
				},
				{	type = "dropdown",
					name = "What to track",
					tooltip = "Define whether tracker should be displaying light attacks per second, time between light attacks, or nothing at all",
					choices = LATrackerChoices,
					default = "Nothing",
					getFunc = function() return self.config.laTrackerChoice end,
					setFunc = function(value)
						self.config.laTrackerChoice = value
						LATracker:DisplayText()
					end,					
				},
				{	type = "slider",
					name = "Time until tracker hides after a fight",
					tooltip = "This is the amount of seconds the tracker will keep displaying your values after a fight is finished",
					default = 15,
					min = 1,
					max = 30,
					step = 1,
					getFunc = function() return self.config.timeTilHidingLATracker end,
					setFunc = function(value)
						self.config.timeTilHidingLATracker = value
					end,
				},
				{	type = "checkbox",
					name = "Show LA record after fight",
					tooltip = "Gives you a small record of duration of the fight, la/s and the total amount of light attacks",
					default = false,
					getFunc = function() return self.config.showLALogAfterFight end,
					setFunc = function(value)
						self.config.showLALogAfterFight = value
					end,
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