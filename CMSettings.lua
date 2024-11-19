local LAM = LibAddonMenu2
local Util = DariansUtilities
Util.Text = Util.Text or {}
CombatMetronome.LATracker = CombatMetronome.LATracker or {}
local LATracker = CombatMetronome.LATracker
CombatMetronome.StackTracker = CombatMetronome.StackTracker or {}
local StackTracker = CombatMetronome.StackTracker
CombatMetronome.SV = CombatMetronome.SV or {}

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
    self.menu = self.menu or { }
	self.menu.icons = {}
	local LATrackerSettings = LATracker:BuildUI()
	local CreateIcons
	CreateIcons = function(panel)
		if panel == CombatMetronomeOptions then
			for i = 1, #self.menu.CONTROLS do
				local number = CombatMetronome:CreateMenuIconsPath(self.menu.CONTROLS[i].Name)
				self.menu.icons[i] = WINDOW_MANAGER:CreateControl(self.name.."MenuIcon"..i, panel.controlsToRefresh[number].checkbox, CT_TEXTURE)
				self.menu.icons[i]:SetAnchor(RIGHT, panel.controlsToRefresh[number].checkbox, LEFT, self.menu.CONTROLS[i].Offset, 0)
				self.menu.icons[i]:SetTexture(self.menu.CONTROLS[i].Icon)
				self.menu.icons[i]:SetDimensions(self.menu.CONTROLS[i].Dimensions, self.menu.CONTROLS[i].Dimensions)
				if CombatMetronome.SV.Progressbar[self.menu.CONTROLS[i].SavedVars] then
					self.menu.icons[i]:SetDesaturation(0)
				else
					self.menu.icons[i]:SetDesaturation(1)
				end
			end
			self.menu.icons[2]:SetTexture(self.Progressbar.activeMount.icon)
			CALLBACK_MANAGER:UnregisterCallback("LAM-PanelControlsCreated", CreateIcons)
		end
	end
	CALLBACK_MANAGER:RegisterCallback("LAM-PanelControlsCreated", CreateIcons)

    self.menu.abilityAdjustChoices = self:CreateAdjustList()
    self.menu.curSkillName = ABILITY_ADJUST_PLACEHOLDER
    self.menu.curSkillId = -1
	local attributes = StackTracker.CLASS_ATTRIBUTES[StackTracker.class]
    self.menu.metadata = {
        type = "panel",
        name = "Combat Metronome",
        displayName = "|ce11212C|rombat |ce11212M|retronome",			-- "Combat Metronome"
        author = "Darianopolis, |c2a52beb|rarny",
        version = self.version.patch.."."..self.version.major.."."..self.version.minor,
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
            getFunc = function() return CombatMetronome.SV.global end,
            setFunc = function(value) 
                if CombatMetronome.SV.global == value then return end

                if value then
                    CombatMetronome.SV.global = true
                    CombatMetronome.SV = ZO_SavedVars:NewAccountWide(
                        "CombatMetronomeSavedVars", 1, nil, DEFAULT_SAVED_VARS
                    )
					if not CombatMetronome.SV.migrated then
						self:ConvertSavedVariables()
						if self.SV.debug.enabled then CombatMetronome.debug:Print("Migrating saved variables") end
					end
                    CombatMetronome.SV.global = true
                else
                    CombatMetronome.SV = ZO_SavedVars:NewCharacterIdSettings(
                        "CombatMetronomeSavedVars", 1, nil, DEFAULT_SAVED_VARS
                    )
					if not CombatMetronome.SV.migrated then
						self:ConvertSavedVariables()
						if self.SV.debug.enabled then CombatMetronome.debug:Print("Migrating saved variables") end
					end
                    CombatMetronome.SV.global = false
                end

                CombatMetronome.SV.global = value
                self:UpdateAdjustChoices()
                self:BuildUI()
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
					getFunc = function() return CombatMetronome.SV.Progressbar.hide end,
					setFunc = function(value)
						CombatMetronome.SV.Progressbar.hide  = value
						self.Progressbar.frame:SetHidden(value)
						if value then
							self:UnregisterCM()
							self.Progressbar.bar:SetHidden(true)
						else
							self:RegisterCM()
							self.Progressbar.UI.HiddenStates()
						end
					end,
				},
				{
					type = "checkbox",
					name = "Hide progress bar in PVP Zones",
					tooltip = "Hides progress bar in PVPZones to keep UI clean",
					disabled = function() return CombatMetronome.SV.Progressbar.hide end,
					getFunc = function() return CombatMetronome.SV.Progressbar.hideInPVP end,
					setFunc = function(value)
						CombatMetronome.SV.Progressbar.hideInPVP = value
						self:CMPVPSwitch()
						-- self:BuildUI()
					end,
				},
				{
					type = "checkbox",
					name = "How does it look?",
					tooltip = "Shows bar at the right of the screen to check your settings. This bar is not resizable nor movable! This resets if you leave the menu.",
					warning = "This temporarily disables the Unlock function! Deactivate again to be able to unlock the bar.",
					disabled = function() return CombatMetronome.SV.Progressbar.hide end,
					default = false,
					getFunc = function() return self.Progressbar.showSample end,
					setFunc = function(value)
						self.Progressbar.showSample = value
						if value then
							self.Progressbar.UI.Position("Sample")
							self.Progressbar.frame:SetHidden(false)
							self.Progressbar.bar:SetHidden(false)
						else
							self.Progressbar.UI.Position("UI")
							self.Progressbar.UI.HiddenStates()
						end
					end,
				},
		---------------------------
		---- Position and Size ----
		---------------------------
				{
					type = "submenu",
					name = "Position / Size",
					disabled = function() return CombatMetronome.SV.Progressbar.hide end,
					controls = {
						{
							type = "checkbox",
							name = "Unlock progressbar",
							tooltip = "Reposition / resize bar by dragging center / edges.",
							-- width = "half",
							disabled = function() return self.Progressbar.showSample end,
							getFunc = function() return self.Progressbar.frame.IsUnlocked() end,
							setFunc = function(value)
								self.Progressbar.frame:SetUnlocked(value)
								if value then
									self.Progressbar.frame:SetDrawTier(DT_HIGH)
									self.Progressbar.frame:SetHidden(false)
								else
									self.Progressbar.frame:SetDrawTier(DT_LOW)
									self.Progressbar.frame:SetHidden(true)
								end
							end,
						},
						{
							type = "slider",
							name = "X Offset",
							min = 0,
							--max = math.floor(GuiRoot:GetWidth() - CombatMetronome.SV.Progressbar.barSize),
							max = math.floor(GuiRoot:GetWidth() - CombatMetronome.SV.Progressbar.width),
							step = 1,
							disabled = function() return self.Progressbar.showSample end,
							getFunc = function() return CombatMetronome.SV.Progressbar.xOffset end,
							setFunc = function(value) 
								CombatMetronome.SV.Progressbar.xOffset = value
								self.Progressbar.UI.Position("UI")
								-- self:BuildUI()
							end,
						},
						{
							type = "button",
							name = "Center Horizontally",
							disabled = function() return self.Progressbar.showSample end,
							func = function()
								CombatMetronome.SV.Progressbar.xOffset = math.floor((GuiRoot:GetWidth() - CombatMetronome.SV.Progressbar.width) / 2)
								self.Progressbar.UI.Position("UI")
								-- self:BuildUI()
							end
						},
						{
							type = "slider",
							name = "Y Offset",
							min = 0,
							--max = math.floor(GuiRoot:GetHeight() - CombatMetronome.SV.Progressbar.barSize/10),
							max = math.floor(GuiRoot:GetHeight() - CombatMetronome.SV.Progressbar.height),
							step = 1,
							disabled = function() return self.Progressbar.showSample end,
							getFunc = function() return CombatMetronome.SV.Progressbar.yOffset end,
							setFunc = function(value) 
								CombatMetronome.SV.Progressbar.yOffset = value 
								self.Progressbar.UI.Position("UI")
								-- self:BuildUI()
							end,
						},
						{
							type = "button",
							name = "Center Vertically",
							disabled = function() return self.Progressbar.showSample end,
							func = function()
								CombatMetronome.SV.Progressbar.yOffset = math.floor((GuiRoot:GetHeight() - CombatMetronome.SV.Progressbar.height) / 2)
								self.Progressbar.UI.Position("UI")
								-- self:BuildUI()
							end
						},
						{
							type = "slider",
							name = "Width",
							min = MIN_WIDTH,
							max = MAX_WIDTH,
							step = 1,
							getFunc = function() return CombatMetronome.SV.Progressbar.width end,
							setFunc = function(value) 
								CombatMetronome.SV.Progressbar.width = value
								self.Progressbar.UI.Size()
								-- self:BuildUI()
							end,
						},
						{
							type = "slider",
							name = "Height",
							min = MIN_HEIGHT,
							max = MAX_HEIGHT,
							step = 1,
							getFunc = function() return CombatMetronome.SV.Progressbar.height end,
							setFunc = function(value) 
								CombatMetronome.SV.Progressbar.height = value 
								self.Progressbar.UI.Size()
								-- self:BuildUI()
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
					disabled = function() return CombatMetronome.SV.Progressbar.hide end,
					controls = {
						{
							type = "checkbox",
							name = "Show permanently",
							tooltip = "If you don't want to hide the cast bar when it's unused, it will display the background color.",
							disabled = function() return CombatMetronome.Progressbar.showSample end,
							getFunc = function() return CombatMetronome.SV.Progressbar.dontHide end,
							setFunc = function(value)
								CombatMetronome.SV.Progressbar.dontHide = value
								self.Progressbar.UI.HiddenStates()
								-- self:BuildUI()
							end,
						},
						{
							type = "checkbox",
							name = "Make it fancy",
							tooltip = "Have fancy effects and stuff",
							getFunc = function() return CombatMetronome.SV.Progressbar.makeItFancy, CombatMetronome.SV.Progressbar.lastBackgroundColor, CombatMetronome.SV.Progressbar.backgroundColor end,
							setFunc = function(value)
								CombatMetronome.SV.Progressbar.makeItFancy = value
								if CombatMetronome.SV.Progressbar.makeItFancy then
									CombatMetronome.SV.Progressbar.lastBackgroundColor = CombatMetronome.SV.Progressbar.backgroundColor
									CombatMetronome.SV.Progressbar.backgroundColor = {0, 0, 0, 0}
								else
									CombatMetronome.SV.Progressbar.backgroundColor = CombatMetronome.SV.Progressbar.lastBackgroundColor
								end
								self.Progressbar.UI.HiddenStates()
								-- self:BuildUI()
							end,
						},
						{
							type = "colorpicker",
							name = "Background Color",
							tooltip = "Color of the bar background",
							disabled = function()
								return (CombatMetronome.SV.Progressbar.makeItFancy)
							end,
							getFunc = function() return unpack(CombatMetronome.SV.Progressbar.backgroundColor) end,
							setFunc = function(r, g, b, a)
								CombatMetronome.SV.Progressbar.backgroundColor = {r, g, b, a}
								self.Progressbar.UI.BarColors()
								-- self:BuildUI()
							end,
						},
						{
							type = "colorpicker",
							name = "Progress Color",
							tooltip = "Color of the progress bar",
							getFunc = function() return unpack(CombatMetronome.SV.Progressbar.progressColor) end,
							setFunc = function(r, g, b, a)
								CombatMetronome.SV.Progressbar.progressColor = {r, g, b, a}
								self.Progressbar.UI.BarColors()
								-- self:BuildUI()
							end,
						},
						{
							type = "colorpicker",
							name = "Ping Color",
							tooltip = "Color of the ping zone",
							getFunc = function() return unpack(CombatMetronome.SV.Progressbar.pingColor) end,
							setFunc = function(r, g, b, a)
								CombatMetronome.SV.Progressbar.pingColor = {r, g, b, a}
								self.Progressbar.UI.BarColors()
								-- self:BuildUI()
							end,
						},
						{
							type = "dropdown",
							name = "Alignment",
							tooltip = "Alignment of the progress bar",
							choices = {"Left", "Center", "Right"},
							getFunc = function() return CombatMetronome.SV.Progressbar.barAlign end,
							setFunc = function(value)
								CombatMetronome.SV.Progressbar.barAlign = value
								self.Progressbar.UI.Anchors()
								-- self:BuildUI()
							end,
						},
						{
							type = "checkbox",
							name = "Switch Progress Color while channeling",
							tooltip = "Change bar color on channeling abilities <1 second to indicate possibility to barswap, when channel is finished",
							warning = "This is experimental and might feel a little wonky",
							getFunc = function() return CombatMetronome.SV.Progressbar.changeOnChanneled end,
							setFunc = function(value)
								CombatMetronome.SV.Progressbar.changeOnChanneled = value
								-- self:BuildUI()
							end,
						},
						{
							type = "colorpicker",
							name = "Channel Color",
							tooltip = "Color while channelling",
							disabled = function()
								return (not CombatMetronome.SV.Progressbar.changeOnChanneled)
							end,
							getFunc = function() return unpack(CombatMetronome.SV.Progressbar.channelColor) end,
							setFunc = function(r, g, b, a)
								CombatMetronome.SV.Progressbar.channelColor = {r, g, b, a}
								self.Progressbar.UI.BarColors()
								-- self:BuildUI()
							end,
						},
						{
							type = "dropdown",
							name = "Label font",
							tooltip = "Font that is used for labels",
							choices = labelFonts,
							width = "half",
							getFunc = function() return CombatMetronome.SV.Progressbar.labelFont end,
							setFunc = function(value)
								CombatMetronome.SV.Progressbar.labelFont = value
								self.Progressbar.UI.Fonts()
								LATrackerSettings.LabelSettings()
								-- self:BuildUI()
							end,
						},
						{
							type = "dropdown",
							name = "Font Style",
							tooltip = "Font style that is used for labels",
							choices = fontStyles,
							width = "half",
							getFunc = function() return CombatMetronome.SV.Progressbar.fontStyle end,
							setFunc = function(value)
								CombatMetronome.SV.Progressbar.fontStyle = value
								self.Progressbar.UI.Fonts()
								LATrackerSettings.LabelSettings()
								-- self:BuildUI()
							end,
						},
						{
							type = "slider",
							name = "Font size",
							warning = "Font size only applies to time remaining and spell name!",
							min = 5,
							max = CombatMetronome.SV.Progressbar.height,
							step = 1,
							disabled = function() return not (CombatMetronome.SV.Progressbar.showTimeRemaining or CombatMetronome.SV.Progressbar.showSpell) end,
							getFunc = function() return CombatMetronome.SV.Progressbar.spellSize end,
							setFunc = function(value)
								CombatMetronome.SV.Progressbar.spellSize = value
								self.Progressbar.UI.Fonts()
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
					disabled = function() return CombatMetronome.SV.Progressbar.hide end,
					controls = {
						{
							type = "slider",
							name = "Max latency",
							tooltip = "Set the maximum display latency",
							min = 0,
							max = 1000,
							step = 1,
							getFunc = function() return CombatMetronome.SV.Progressbar.maxLatency end,
							setFunc = function(value) CombatMetronome.SV.Progressbar.maxLatency = value end,
						},
						{
							type = "slider",
							name = "GCD Adjust",
							tooltip = "Increase/decrease the displayed GCD length",
							min = -MAX_ADJUST,
							max = MAX_ADJUST,
							step = 1,
							getFunc = function() return CombatMetronome.SV.Progressbar.gcdAdjust end,
							setFunc = function(value) 
								CombatMetronome.SV.Progressbar.gcdAdjust = value 
								-- self:BuildUI()
							end,
						},
						{
							type = "slider",
							name = "Global Heavy Attack Adjust",
							tooltip = "Increase/decrease the baseline heavy attack cast time. Additional adjustments to specific heavy types are made in addition to this",
							min = -MAX_ADJUST,
							max = MAX_ADJUST,
							step = 1,
							getFunc = function() return CombatMetronome.SV.Progressbar.globalHeavyAdjust end,
							setFunc = function(value) 
								CombatMetronome.SV.Progressbar.globalHeavyAdjust = value 
							end,
						},
						{
							type = "slider",
							name = "Global Ability Cast Adjust",
							tooltip = "Increase/decrease the baseline ability cast time. Additional adjustments to specific abilities are made in addition to this",
							min = -MAX_ADJUST,
							max = MAX_ADJUST,
							step = 1,
							getFunc = function() return CombatMetronome.SV.Progressbar.globalAbilityAdjust end,
							setFunc = function(value)
								CombatMetronome.SV.Progressbar.globalAbilityAdjust = value
							end,
						},
						{
							type = "checkbox",
							name = "Show OOC",
							tooltip = "Track GCDs whilst out of combat",
							getFunc = function() return CombatMetronome.SV.Progressbar.showOOC end,
							setFunc = function(value)
								CombatMetronome.SV.Progressbar.showOOC = value
								if not value and CombatMetronome.SV.Progressbar.trackGCD then
									CombatMetronome.SV.Progressbar.trackGCD = false
								end
							end
						},
						{
							type = "checkbox",
							name = "Track all GCDs",
							tooltip = "In addition to ability GCDs also track itmes, synergies, etc.",
							disabled = function() return not CombatMetronome.SV.Progressbar.showOOC end,
							getFunc = function() return CombatMetronome.SV.Progressbar.trackGCD end,
							setFunc = function(value)
								CombatMetronome.SV.Progressbar.trackGCD = value
							end,
						},
						{
							type = "checkbox",
							name = "Show ping zone for non ability GCD",
							tooltip = "If turned on this shows a ping zone for GCD caused by using items or synergies, etc.",
							disabled = function() return (not CombatMetronome.SV.Progressbar.trackGCD or CombatMetronome.SV.Progressbar.dontShowPing) end,
							getFunc = function() return CombatMetronome.SV.Progressbar.showPingOnGCD end,
							setFunc = function(value)
								CombatMetronome.SV.Progressbar.showPingOnGCD = value
							end,
						},
						{
							type = "submenu",
							name = "Show further gcd information",
							disabled = function() return not CombatMetronome.SV.Progressbar.trackGCD end,
							controls = {
								{
									type = "checkbox",
									name = self.menu.CONTROLS[1].Name,
									disabled = function() return not CombatMetronome.SV.Progressbar.trackGCD end,
									default = false,
									getFunc = function() return CombatMetronome.SV.Progressbar.trackRolldodge end,
									setFunc = function(value)
										CombatMetronome.SV.Progressbar.trackRolldodge = value
										if value then
											self.menu.icons[1]:SetDesaturation(0)
										else
											self.menu.icons[1]:SetDesaturation(1)
										end
									end,
								},
								{
									type = "checkbox",
									name = self.menu.CONTROLS[2].Name,
									disabled = function() return not CombatMetronome.SV.Progressbar.trackGCD end,
									default = false,
									getFunc = function() return CombatMetronome.SV.Progressbar.trackMounting end,
									setFunc = function(value)
										CombatMetronome.SV.Progressbar.trackMounting = value
										if value then
											self.menu.icons[2]:SetDesaturation(0)
											if not self.combatEventsRegistered then
												CombatMetronome:RegisterCombatEvents()
											end
											if CombatMetronome.SV.Progressbar.showMountNick and not self.collectiblesTrackerRegistered then
												CombatMetronome:RegisterCollectiblesTracker()
											end
										else
											self.menu.icons[2]:SetDesaturation(1)
											if self.mountingTrackerRegistered and not CombatMetronome:CheckForCombatEventsRegister() then
												CombatMetronome:UnregisterCombatEvents()
											end
											if not CombatMetronome.SV.Progressbar.trackCollectibles and self.collectiblesTrackerRegistered then
												CombatMetronome:UnregisterCollectiblesTracker()
											end
										end
									end,
								},
								{
									type = "checkbox",
									name = "Show mount nickname",
									disabled = function() return not CombatMetronome.SV.Progressbar.trackMounting end,
									default = false,
									getFunc = function() return CombatMetronome.SV.Progressbar.showMountNick end,
									setFunc = function(value)
										CombatMetronome.SV.Progressbar.showMountNick = value
										if value then
											if not self.collectiblesTrackerRegistered then
												CombatMetronome:RegisterCollectiblesTracker()
											end
										else
											if not CombatMetronome.SV.Progressbar.trackCollectibles and self.collectiblesTrackerRegistered then
												CombatMetronome:UnregisterCollectiblesTracker()
											end
										end
									end,
								},
								{
									type = "checkbox",
									name = self.menu.CONTROLS[3].Name,
									disabled = function() return not CombatMetronome.SV.Progressbar.trackGCD end,
									default = false,
									getFunc = function() return CombatMetronome.SV.Progressbar.trackCollectibles end,
									setFunc = function(value)
										CombatMetronome.SV.Progressbar.trackCollectibles = value
										if value then
											self.menu.icons[3]:SetDesaturation(0)
											if not self.CollectiblesTrackerRegistered then
												CombatMetronome:RegisterCollectiblesTracker()
											end
										else
											self.menu.icons[3]:SetDesaturation(1)
											if self.collectiblesTrackerRegistered and not CombatMetronome.SV.Progressbar.showMountNick then
												CombatMetronome:UnregisterCollectiblesTracker()
											end
										end
									end,
								},
								{
									type = "checkbox",
									name = self.menu.CONTROLS[4].Name,
									disabled = function() return not CombatMetronome.SV.Progressbar.trackGCD end,
									default = false,
									getFunc = function() return CombatMetronome.SV.Progressbar.trackItems end,
									setFunc = function(value)
										CombatMetronome.SV.Progressbar.trackItems = value
										if value then
											self.menu.icons[4]:SetDesaturation(0)
										else
											self.menu.icons[4]:SetDesaturation(1)
										end
										if value and not self.itemsTrackerRegistered then
											CombatMetronome:RegisterItemsTracker()
										elseif not value and self.itemsTrackerRegistered then
											CombatMetronome:UnregisterItemsTracker()
										end
									end,
								},
								{
									type = "checkbox",
									name = self.menu.CONTROLS[5].Name,
									tooltip = "Toggle displaying synergies like vampire feed and blade of woe",
									disabled = function() return not CombatMetronome.SV.Progressbar.trackGCD end,
									default = false,
									getFunc = function() return CombatMetronome.SV.Progressbar.trackSynergies end,
									setFunc = function(value)
										CombatMetronome.SV.Progressbar.trackSynergies = value
										if value then
											self.menu.icons[5]:SetDesaturation(0)
										else
											self.menu.icons[5]:SetDesaturation(1)
										end
										if value then
											if not self.combatEventsRegistered then
												CombatMetronome:RegisterCombatEvents()
											elseif not self.synergyChangedRegistered then
												CombatMetronome:RegisterSynergyChanged()
											end
										elseif not value then
											if self.combatEventsRegistered and not CombatMetronome:CheckForCombatEventsRegister() then
												CombatMetronome:UnregisterCombatEvents()
											elseif self.synergyChangedRegistered then
												CombatMetronome:UnregisterSynergyChanged()
											end
										end
									end,
								},
								{
									type = "checkbox",
									name = self.menu.CONTROLS[6].Name,
									disabled = function() return not CombatMetronome.SV.Progressbar.trackGCD end,
									default = false,
									getFunc = function() return CombatMetronome.SV.Progressbar.trackBreakingFree end,
									setFunc = function(value)
										CombatMetronome.SV.Progressbar.trackBreakingFree = value
										if value then
											self.menu.icons[6]:SetDesaturation(0)
										else
											self.menu.icons[6]:SetDesaturation(1)
										end
										if value and not self.combatEventsRegistered then
											CombatMetronome:RegisterCombatEvents()
										elseif not value and self.combatEventsRegistered and not CombatMetronome:CheckForCombatEventsRegister() then
											CombatMetronome:UnregisterCombatEvents()
										end
									end,
								},
								-- {
									-- type = "checkbox",
									-- name = "Other synergies that cause GCD",
									-- disabled = function() return not CombatMetronome.SV.Progressbar.trackGCD end,
									-- default = false,
									-- getFunc = function() return CombatMetronome.SV.Progressbar.trackSynergies end,
									-- setFunc = function(value)
										-- CombatMetronome.SV.Progressbar.trackSynergies = value
										-- if value and not self.synergyChangedRegistered then
												-- CombatMetronome:RegisterSynergyChanged()
										-- elseif not value and self.synergyChangedRegistered then
												-- CombatMetronome:UnregisterSynergyChanged()
										-- end
									-- end,
								-- },
								-- {
									-- type = "submenu",
									-- name = "Collectible types",
									-- disabled = function() return not CombatMetronome.SV.Progressbar.trackCollectibles end,
									-- controls = {
										-- {
											-- type = "checkbox",
											-- name = "Assistants",
											-- disabled = function() return not CombatMetronome.SV.Progressbar.trackCollectibles end,
											-- default = false,
											-- getFunc = function() return CombatMetronome.SV.Progressbar.trackRolldodge end,
											-- setFunc = function(value)
												-- CombatMetronome.SV.Progressbar.trackRolldodge = value
											-- end,
										-- },
										-- {
											-- type = "checkbox",
											-- name = "Companions",
											-- disabled = function() return not CombatMetronome.SV.Progressbar.trackCollectibles end,
											-- default = false,
											-- getFunc = function() return CombatMetronome.SV.Progressbar.trackRolldodge end,
											-- setFunc = function(value)
												-- CombatMetronome.SV.Progressbar.trackRolldodge = value
											-- end,
										-- },
										-- {
											-- type = "checkbox",
											-- name = "Costumes",
											-- disabled = function() return not CombatMetronome.SV.Progressbar.trackCollectibles end,
											-- default = false,
											-- getFunc = function() return CombatMetronome.SV.Progressbar.trackRolldodge end,
											-- setFunc = function(value)
												-- CombatMetronome.SV.Progressbar.trackRolldodge = value
											-- end,
										-- },
										-- {
											-- type = "checkbox",
											-- name = "Polymorphs",
											-- disabled = function() return not CombatMetronome.SV.Progressbar.trackCollectibles end,
											-- default = false,
											-- getFunc = function() return CombatMetronome.SV.Progressbar.trackRolldodge end,
											-- setFunc = function(value)
												-- CombatMetronome.SV.Progressbar.trackRolldodge = value
											-- end,
										-- },
										-- {
											-- type = "checkbox",
											-- name = "Vanity pets",
											-- disabled = function() return not CombatMetronome.SV.Progressbar.trackCollectibles end,
											-- default = false,
											-- getFunc = function() return CombatMetronome.SV.Progressbar.trackRolldodge end,
											-- setFunc = function(value)
												-- CombatMetronome.SV.Progressbar.trackRolldodge = value
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
							getFunc = function() return CombatMetronome.SV.Progressbar.dontShowPing end,
							setFunc = function(value)
								CombatMetronome.SV.Progressbar.dontShowPing = value
							end,
						},
						{
							type = "checkbox",
							name = "I'm no Oakensorc",
							tooltip = "Stops displaying heavy attacks on the progress bar",
							getFunc = function() return CombatMetronome.SV.Progressbar.stopHATracking end,
							setFunc = function(value)
								CombatMetronome.SV.Progressbar.stopHATracking = value
							end,
						},
						{
							type = "checkbox",
							name = "Display ping zone on heavy attacks",
							tooltip = "Displays heavy attacks with ping zone - Heavy attack cast will finish at start on entering ping zone "
												.."(heavy attack timing is calculated locally). This is for visual consistency",
							disabled = function()
								return (CombatMetronome.SV.Progressbar.dontShowPing)
							end,
							getFunc = function() return CombatMetronome.SV.Progressbar.displayPingOnHeavy end,
							setFunc = function(value)
								CombatMetronome.SV.Progressbar.displayPingOnHeavy = value
							end,
						},
						{
							type = "checkbox",
							name = "Display spell name in cast bar",
							tooltip = "Displays the spell name in the cast bar, when the ability is not an instant cast",
							getFunc = function() return CombatMetronome.SV.Progressbar.showSpell end,
							setFunc = function(value)
								CombatMetronome.SV.Progressbar.showSpell = value
							end,
						},
						{
							type = "checkbox",
							name = "Display spell name for any ability",
							tooltip = "Always displays the spell name in the cast bar, not only when the ability is not an instant cast",
							disabled = function() return not CombatMetronome.SV.Progressbar.showSpell end,
							getFunc = function() return CombatMetronome.SV.Progressbar.alwaysShowSpell end,
							setFunc = function(value)
								CombatMetronome.SV.Progressbar.alwaysShowSpell = value
							end,
						},
						{
							type = "checkbox",
							name = "Display time remaining in cast bar",
							tooltip = "Displays the remaining time on channel or cast in the cast bar, when the ability is not an instant cast",
							getFunc = function() return CombatMetronome.SV.Progressbar.showTimeRemaining end,
							setFunc = function(value)
								CombatMetronome.SV.Progressbar.showTimeRemaining = value
							end,
						},
						{
							type = "checkbox",
							name = "Display time remaining for all abilities",
							tooltip = "Always displays the remaining time on channel or cast in the cast bar, not only when the ability is not an instant cast",
							disabled = function() return not CombatMetronome.SV.Progressbar.showTimeRemaining end,
							getFunc = function() return CombatMetronome.SV.Progressbar.alwaysShowTimeRemaining end,
							setFunc = function(value)
								CombatMetronome.SV.Progressbar.alwaysShowTimeRemaining = value
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
					disabled = function() return CombatMetronome.SV.Progressbar.hide end,
					controls = {
						{
							type = "slider",
							name = "Volume of 'tick' and 'tock'",
							tooltip = "Adjust volume of tick and tock effects",
							warning = "You may have to adjust your general audio settings and general audio volume for this to have a noticable effect. Take care not to overadjust, your ears can only take so much!",
							disabled = function() return not (CombatMetronome.SV.Progressbar.soundTickEnabled or CombatMetronome.SV.Progressbar.soundTockEnabled) end,
							min = 0,
							max = 100,
							setp = 1,
							getFunc = function() return CombatMetronome.SV.Progressbar.tickVolume end,
							setFunc = function(value) CombatMetronome.SV.Progressbar.tickVolume = value end,
						},
						{
							type = "checkbox",
							name = "Sound 'tick'",
							tooltip = "Enable sound 'tick', which marks the middle/beginning of your ability",
							width = "half",
							getFunc = function() return CombatMetronome.SV.Progressbar.soundTickEnabled end,
							setFunc = function(state)
								CombatMetronome.SV.Progressbar.soundTickEnabled = state
								CombatMetronome.Progressbar.soundTickPlayed = true
							end,
						},
						{
							type = "checkbox",
							name = "Sound 'tock'",
							tooltip = "This sound cue marks the end of an ability",
							warning = "If you don't hear this cue, you either have perfect weave or, and chances for that are much much higher, missed a light attack ¯\\_(ツ)_/¯",
							width = "half",
							getFunc = function() return CombatMetronome.SV.Progressbar.soundTockEnabled end,
							setFunc = function(state)
								CombatMetronome.SV.Progressbar.soundTockEnabled = state
								CombatMetronome.Progressbar.soundTockPlayed = true
							end,
						},
						{
							type = "dropdown",
							name = "Sound 'tick' effect",
							disabled = function()
								return (not CombatMetronome.SV.Progressbar.soundTickEnabled)
							end,
							width = "half",
							choices = sounds,
							getFunc = function() return CombatMetronome.SV.Progressbar.soundTickEffect end,
							setFunc = function(value)
								CombatMetronome.SV.Progressbar.soundTickEffect = value
								PlaySound(value)
							end,
						},
						{
							type = "dropdown",
							name = "Sound 'tock' effect",
							disabled = function()
								return (not CombatMetronome.SV.Progressbar.soundTockEnabled)
							end,
							width = "half",
							choices = sounds,
							getFunc = function() return CombatMetronome.SV.Progressbar.soundTockEffect end,
							setFunc = function(value)
								CombatMetronome.SV.Progressbar.soundTockEffect = value
								PlaySound(value)
							end,
						},
						-- {
							-- type = "checkbox",
							-- name = "Enable sound offsets",
							-- tooltip = "This option enables finetuning your sound cues",
							-- disabled = function() return not (CombatMetronome.SV.Progressbar.soundTockEnabled or CombatMetronome.SV.Progressbar.soundTickEnabled) end,
							-- getFunc = function() return CombatMetronome.SV.Progressbar.soundOffsets end,
							-- setFunc = function(value)
								-- CombatMetronome.SV.Progressbar.soundOffsets = value
							-- end,
						-- },
						{
							type = "slider",
							name = "Sound 'tick' offset",
							disabled = function()
								return not (CombatMetronome.SV.Progressbar.soundTickEnabled) -- and CombatMetronome.SV.Progressbar.soundOffsets)
							end,
							width = "half",
							min = 0,
							max = 1000,
							step =  1,
							getFunc = function() return CombatMetronome.SV.Progressbar.soundTickOffset end,
							setFunc = function(value)
								CombatMetronome.SV.Progressbar.soundTickOffset = value
							end,
						},
						{
							type = "slider",
							name = "Sound 'tock' offset",
							disabled = function()
								return not (CombatMetronome.SV.Progressbar.soundTockEnabled) -- and CombatMetronome.SV.Progressbar.soundOffsets)
							end,
							width = "half",
							min = 0,
							max = 1000,
							step = 1,
							getFunc = function() return CombatMetronome.SV.Progressbar.soundTockOffset end,
							setFunc = function(value)
								CombatMetronome.SV.Progressbar.soundTockOffset = value
							end,
						},
						{
							type = "checkbox",
							name = "Play 'tick' at the start of an ability",
							tooltip = "Have the tick mark the start of your ability",
							disabled = function() return not CombatMetronome.SV.Progressbar.soundTickEnabled end,
							getFunc = function() return not CombatMetronome.SV.Progressbar.soundTickMidAbility end,
							setFunc = function(value)
								CombatMetronome.SV.Progressbar.soundTickMidAbility = not value
							end,
						},
						{
							type = "checkbox",
							name = "Don't play 'tick' on heavy attacks",
							tooltip = "Since heavys are easily canceled, this is recommended to avoid annoying sound clutter",
							disabled = function() return not (CombatMetronome.SV.Progressbar.soundTickMidAbility and CombatMetronome.SV.Progressbar.soundTickEnabled) end,
							getFunc = function() return CombatMetronome.SV.Progressbar.noTickOnHeavy end,
							setFunc = function(value)
								CombatMetronome.SV.Progressbar.noTickOnHeavy = value
							end,
						},
						{
							type = "checkbox",
							name = "Force 'tock'",
							tooltip = "Forces the 'tock' sound even when you missed a light attack and already have another ability queued, to keep the rythm",
							disabled = function() return not CombatMetronome.SV.Progressbar.soundTockEnabled end,
							getFunc = function() return CombatMetronome.SV.Progressbar.forceSoundTock end,
							setFunc = function(value)
								CombatMetronome.SV.Progressbar.forceSoundTock = value
							end,
						},
						{
							type = "checkbox",
							name = "Play sounds ooc",
							tooltip = "When enabled, will play 'tick' and 'tock' sounds even while out of combat",
							disabled = function() return not (CombatMetronome.SV.Progressbar.showOOC and (CombatMetronome.SV.Progressbar.soundTockEnabled or CombatMetronome.SV.Progressbar.soundTickEnabled)) end,
							getFunc = function() return CombatMetronome.SV.Progressbar.playSoundsOOC end,
							setFunc = function(value)
								CombatMetronome.SV.Progressbar.playSoundsOOC = value
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
					disabled = function() return CombatMetronome.SV.Progressbar.hide end,
					controls = {
						{
							type = "dropdown",
							name = "Currently equipped abilities:",
							width = "half",
							choices = self.currentlyEquippedAbilities.list,
							getFunc = function()
								if self.menu.curSkillId then
									local i = self:IsSkillCurrentlyEquipped(self.menu.curSkillId)
									if self:IsSkillCurrentlyEquipped(self.menu.curSkillId) then
										-- self.debug:Print("Skill currently equipped")
										return self.currentlyEquippedAbilities.list[i]
									end
									return
								end
							end,
							setFunc = function(selectedSkill)
								local skillData = self:GetEquippedSkillData(selectedSkill)
								self.menu.curSkillName = skillData.name
								self.menu.curSkillId = skillData.id
								CombatMetronome.SV.Progressbar.abilityAdjusts[self.menu.curSkillId] = CombatMetronome.SV.Progressbar.abilityAdjusts[self.menu.curSkillId] or 0
								self:UpdateAdjustChoices()
							end,
						},
						{
							type = "button",
							name = "Refresh ability list",
							width = "half",
							func = function()
								CombatMetronome:BuildListOfCurrentlyEquippedAbilities()
							end
						},
						{
							type = "editbox",
							name = "Add skill to adjust",
							isMultiline = false,
							-- disabled = true,
							getFunc = function() return self:CropIconFromSkill(Util.Text.CropZOSString(self.menu.curSkillName)) end,
							setFunc = function(name)
								if name == ABILITY_ADJUST_PLACEHOLDER or not name or #name == 0  or name == self.menu.curSkillName then return end
								if Util.Ability.nameCache[name] then
									self.menu.curSkillName = name
									local id = Util.Ability.nameCache[name].id
									self.menu.curSkillId = id
									if CombatMetronome.SV.Progressbar.abilityAdjusts[id] then return end
									CombatMetronome.debug:Print("Found ability for '"..name.."'. ID: "..id)
									CombatMetronome.SV.Progressbar.abilityAdjusts[id] = CombatMetronome.SV.Progressbar.abilityAdjusts[self.menu.curSkillId] or 0
									self:UpdateAdjustChoices()
								else
									CombatMetronome.debug:Print("Couldn't find ability in cache. Make sure you cast the ability once or equip ability to ensure better results while gaming. Will try to find it somewhere else.")
									for id = 0, 300000 do
										if Util.Text.CropZOSString(GetAbilityName(id)) == name and GetAbilityIcon(id) ~= "/esoui/art/icons/ability_mage_065.dds" then
											--[[_=self.log and]] CombatMetronome.debug:Print("Found ability for '"..name.."'. ID: "..id)
											self.menu.curSkillName = name
											self.menu.curSkillId = id
											CombatMetronome.SV.Progressbar.abilityAdjusts[id] = 0
											self:UpdateAdjustChoices()
											return
										end
									end
									CombatMetronome.debug:Print("Could not find any valid ability named '"..name.."'!")
								end
							end
						},
						{
							type = "dropdown",
							name = "Select skill adjust",
							choices = self.menu.abilityAdjustChoices,
							scrollable = true,
							getFunc = function() return self.menu.abilityAdjustChoices[self:FindSkillInAdjustList(self.menu.curSkillName)] end,
							setFunc = function(value) 
								self.menu.curSkillName = self:CropIconFromSkill(value)
								if CombatMetronome.SV.debug.enabled then CombatMetronome.debug:Print("Current skill is: "..self.menu.curSkillName) end
								for id, adj in pairs(CombatMetronome.SV.Progressbar.abilityAdjusts) do
									if Util.Text.CropZOSString(GetAbilityName(id)) == self:CropIconFromSkill(value) then
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
								-- for id, adj in pairs(CombatMetronome.SV.Progressbar.abilityAdjusts) do
									-- if Util.Text.CropZOSString(GetAbilityName(id)) == self.menu.curSkillName then
										-- self.menu.curSkillId = id
									-- end
								-- end
								return CombatMetronome.SV.Progressbar.abilityAdjusts[self.menu.curSkillId] or 0
							end,
							setFunc = function(value)
								-- if CombatMetronome.SV.Progressbar.abilityAdjusts[self.menu.curSkillId] then
									CombatMetronome.SV.Progressbar.abilityAdjusts[self.menu.curSkillId] = value
								-- end
							end
						},
						{
							type = "button",
							name = "Remove skill adjust",
							func = function()
								--[[_=DLog and]] CombatMetronome.debug:Print("Removing skill '"..self.menu.curSkillName.."'. ID: "..self.menu.curSkillId)
								CombatMetronome.SV.Progressbar.abilityAdjusts[self.menu.curSkillId] = nil
								self:UpdateAdjustChoices()
								self.menu.curSkillName = self:CropIconFromSkill(self.menu.abilityAdjustChoices[1])
								for id, adj in pairs(CombatMetronome.SV.Progressbar.abilityAdjusts) do
									if Util.Text.CropZOSString(GetAbilityName(id)) == self.curSkillName then
										self.menu.curSkillId = id
									end
								end
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
					disabled = function () return CombatMetronome.SV.Resources.anchorResourcesToProgressbar or self.Resources.showSample end,
					getFunc = function() return self.Resources.frame.IsUnlocked() end,
					setFunc = function(value)
						self.Resources.frame:SetUnlocked(value)
						if value then
							self.Resources.frame:SetDrawTier(DT_HIGH)
							self.Resources.frame:SetHidden(false)
						else
							self.Resources.frame:SetDrawTier(DT_LOW)
							self.Resources.frame:SetHidden(true)
						end
					end,
				},
				{
					type = "checkbox",
					name = "Anchor resource tracker atop the progressbar",
					tooltip = "If turned off, resourcebar can be dragged or resized independently",
					warning = "Turning this off will automaticly resize resourcebar to fit your GCD bar!",
					disabled = function()
						return not (CombatMetronome.SV.Resources.showUltimate or CombatMetronome.SV.Resources.showStamina or CombatMetronome.SV.Resources.showMagicka or CombatMetronome.SV.Resources.showHealth) or self.Resources.frame.IsUnlocked()
					end,
					getFunc = function() return CombatMetronome.SV.Resources.anchorResourcesToProgressbar end,
					setFunc = function(value)
						CombatMetronome.SV.Resources.anchorResourcesToProgressbar = value
						self.Progressbar.UI.Size()
						if self.Resources.showSample then
							self.Progressbar.UI.ResourcesPosition("Sample")
						end
					end,
				},
				{
					type = "checkbox",
					name = "Hide resource tracker in PVP Zones",
					tooltip = "Hides resource tracker in PVPZones to keep UI clean",
					disabled = function()
						return not (CombatMetronome.SV.Resources.showUltimate or CombatMetronome.SV.Resources.showStamina or CombatMetronome.SV.Resources.showMagicka or CombatMetronome.SV.Resources.showHealth)
					end,
					getFunc = function() return CombatMetronome.SV.Resources.hideInPVP end,
					setFunc = function(value)
						CombatMetronome.SV.Resources.hideInPVP = value
					end,
				},
				{
					type = "checkbox",
					name = "How does it look?",
					tooltip = "Shows resourcebar at the right of the screen to check your settings. This resourcebar is not movable!",
					warning = "This temporarily disables the Unlock function! Deactivate again to be able to unlock the tracker. This resets, if you leave the menu.",
					default = false,
					disabled = function()
						return not (CombatMetronome.SV.Resources.showUltimate or CombatMetronome.SV.Resources.showStamina or CombatMetronome.SV.Resources.showMagicka or CombatMetronome.SV.Resources.showHealth)
					end,
					getFunc = function() return self.Resources.showSample end,
					setFunc = function(value)
						self.Resources.showSample = value
						if value then
							self.Progressbar.UI.ResourcesPosition("Sample")
							self.Resources.frame:SetHidden(false)
						else
							self.Progressbar.UI.ResourcesPosition("UI")
							self.Progressbar.UI.HiddenStates()
						end
					end,
				},
				{
					type = "submenu",
					name = "Configuration",
					-- disabled = function() return CombatMetronome.SV.Progressbar.hide end,
					controls = {
						{
							type = "checkbox",
							name = "Always show own resources",
							tooltip = "Toggle show own resources. If this is off, your resources will only be shown, when targeting units",
							disabled = function()
								return not (CombatMetronome.SV.Resources.showUltimate or CombatMetronome.SV.Resources.showStamina or CombatMetronome.SV.Resources.showMagicka or CombatMetronome.SV.Resources.showHealth)
							end,
							getFunc = function() return CombatMetronome.SV.Resources.showResources end,
							setFunc = function(value) CombatMetronome.SV.Resources.showResources = value end,
						},
						{
							type = "checkbox",
							name = "Show Ultimate",
							tooltip = "Toggle show ultimate above cast bar",
							getFunc = function() return CombatMetronome.SV.Resources.showUltimate end,
							setFunc = function(value)
								CombatMetronome.SV.Resources.showUltimate = value
							end,
						},
						{
							type = "slider",
							name = "Ultimate Label Size",
							tooltip = "Set the size of the Ultimate label",
							disabled = function()
								return (not CombatMetronome.SV.Resources.showUltimate)
							end,
							min = 0,
							max = CombatMetronome.SV.Resources.height,
							step = 1,
							default = CombatMetronome.SV.Resources.ultSize,
							getFunc = function() return CombatMetronome.SV.Resources.ultSize end,
							setFunc = function(value)
								CombatMetronome.SV.Resources.ultSize = value
								self.Progressbar.UI.Fonts()
								-- self:BuildUI()
							end,
						},
						{
							type = "colorpicker",
							name = "Ultimate Label Color",
							tooltip = "Color of your ultimate label",
							disabled = function()
								return (not CombatMetronome.SV.Resources.showUltimate)
							end,
							getFunc = function() return unpack(CombatMetronome.SV.Resources.ultColor) end,
							setFunc = function(r, g, b, a)
								CombatMetronome.SV.Resources.ultColor = {r, g, b, a}
								self.Progressbar.UI.LabelColors()
								-- self:BuildUI()
							end,
						},
						{
							type = "checkbox",
							name = "Show Stamina",
							tooltip = "Toggle show stamina above cast bar",
							getFunc = function() return CombatMetronome.SV.Resources.showStamina end,
							setFunc = function(value)
								CombatMetronome.SV.Resources.showStamina = value
							end,
						},
						{
							type = "slider",
							name = "Stamina Label Size",
							tooltip = "Set the size of the Stamina label",
							disabled = function()
								return (not CombatMetronome.SV.Resources.showStamina)
							end,
							min = 0,
							max = CombatMetronome.SV.Resources.height/2,
							step = 1,
							default = CombatMetronome.SV.Resources.stamSize,
							getFunc = function() return CombatMetronome.SV.Resources.stamSize end,
							setFunc = function(value)
								CombatMetronome.SV.Resources.stamSize = value
								self.Progressbar.UI.Fonts()
								-- self:BuildUI()
							end,
						},
						{
							type = "colorpicker",
							name = "Stamina Label Color",
							tooltip = "Color of your stamina label",
							disabled = function()
								return (not CombatMetronome.SV.Resources.showStamina)
							end,
							getFunc = function() return unpack(CombatMetronome.SV.Resources.stamColor) end,
							setFunc = function(r, g, b, a)
								CombatMetronome.SV.Resources.stamColor = {r, g, b, a}
								self.Progressbar.UI.LabelColors()
								-- self:BuildUI()
							end,
						},
						{
							type = "checkbox",
							name = "Show Magicka",
							tooltip = "Toggle show magicka above cast bar",
							getFunc = function() return CombatMetronome.SV.Resources.showMagicka end,
							setFunc = function(value)
								CombatMetronome.SV.Resources.showMagicka = value
								-- self.sampleBar.Mag:SetHidden(not value)
							end,
						},
						{
							type = "slider",
							name = "Magicka Label Size",
							tooltip = "Set the size of the Magicka label",
							disabled = function()
								return (not CombatMetronome.SV.Resources.showMagicka)
							end,
							min = 0,
							max = CombatMetronome.SV.Resources.height/2,
							step = 1,
							default = CombatMetronome.SV.Resources.magSize,
							getFunc = function() return CombatMetronome.SV.Resources.magSize end,
							setFunc = function(value)
								CombatMetronome.SV.Resources.magSize = value
								self.Progressbar.UI.Fonts()
								-- self:BuildUI()
							end,
						},
						{
							type = "colorpicker",
							name = "Magicka Label Color",
							tooltip = "Color of your magicka label",
							disabled = function()
								return (not CombatMetronome.SV.Resources.showMagicka)
							end,
							getFunc = function() return unpack(CombatMetronome.SV.Resources.magColor) end,
							setFunc = function(r, g, b, a)
								CombatMetronome.SV.Resources.magColor = {r, g, b, a}
								self.Progressbar.UI.LabelColors()
								-- self:BuildUI()
							end,
						},
						{
							type = "checkbox",
							name = "Show Target Health",
							tooltip = "Toggle show target health above cast bar",
							getFunc = function() return CombatMetronome.SV.Resources.showHealth end,
							setFunc = function(value)
								CombatMetronome.SV.Resources.showHealth = value
							end,
						},
						{
							type = "slider",
							name = "Health Label Size",
							tooltip = "Set the size of the Health label",
							disabled = function()
								return (not CombatMetronome.SV.Resources.showHealth)
							end,
							min = 0,
							max = CombatMetronome.SV.Resources.height,
							step = 1,
							default = CombatMetronome.SV.Resources.healthSize,
							getFunc = function() return CombatMetronome.SV.Resources.healthSize end,
							setFunc = function(value)
								CombatMetronome.SV.Resources.healthSize = value
								self.Progressbar.UI.Fonts()
								-- self:BuildUI()
							end,
						},
						{
							type = "colorpicker",
							name = "Health Label Color",
							tooltip = "Color of target health label",
							disabled = function()
								return (not CombatMetronome.SV.Resources.showHealth)
							end,
							getFunc = function() return unpack(CombatMetronome.SV.Resources.healthColor) end,
							setFunc = function(r, g, b, a)
								CombatMetronome.SV.Resources.healthColor = {r, g, b, a}
								self.Progressbar.UI.LabelColors()
								-- self:BuildUI()
								end,
						},
						{
							type = "checkbox",
							name = "Attach Target Health to reticle",
							tooltip = "Attach Target Health to side of reticle",
							disabled = function()
								return (not CombatMetronome.SV.Resources.showHealth)
							end,
							getFunc = function() return CombatMetronome.SV.Resources.reticleHp end,
							setFunc = function(value) 
								CombatMetronome.SV.Resources.reticleHp = value
								self.Progressbar.UI.Anchors()
								-- self:BuildUI()
							end,
						},
						{
							type = "slider",
							name = "Target Health execute highlight threshold",
							tooltip = "Set the threshold for target health highlighting (Set 0% for no highlight)",
							disabled = function()
								return (not CombatMetronome.SV.Resources.showHealth)
							end,
							min = 0,
							max = 100,
							getFunc = function() return CombatMetronome.SV.Resources.hpHighlightThreshold end,
							setFunc = function(value) CombatMetronome.SV.Resources.hpHighlightThreshold = value end,
						},
						{
							type = "colorpicker",
							name = "Health Highlight Color",
							tooltip = "Color of target health label",
							disabled = function()
								return (not (CombatMetronome.SV.Resources.hpHighlightThreshold ~= 0 and CombatMetronome.SV.Resources.showHealth))
							end,
							getFunc = function() return unpack(CombatMetronome.SV.Resources.healthHighligtColor) end,
							setFunc = function(r, g, b, a)
								CombatMetronome.SV.Resources.healthHighligtColor = {r, g, b, a}
								self.Progressbar.UI.LabelColors()
								-- self:BuildUI()
								end,
						},
						{
							type = "checkbox",
							name = "Show resources when targeting guard",
							tooltip = "Show resources when targeting guard",
							getFunc = function() return CombatMetronome.SV.Resources.showResourcesForGuard end,
							setFunc = function(value) CombatMetronome.SV.Resources.showResourcesForGuard = value end,
						},
					},
				},
			},
		},
		{	type = "divider",},
		-----------------------
		---- Stack Tracker ----
		-----------------------
		-- if StackTracker.CLASS_ATTRIBUTES[StackTracker.class] then
		{	type = "submenu",
			name = "Stack Tracker",
			tooltip = "Lets you track your stacks on e.g. crux or bound armaments. This works on Nightblade, Sorcerer, Dragonknight and Arcanist.",
			controls = {
				{
					type = "checkbox",
					name = "Hide tracker in PVP Zones",
					tooltip = "Hides stack tracker in PVPZones to keep UI clean",
					disabled = function ()
						return not StackTracker:TrackerIsActive()											--CM_TRACKER_CLASS_ATTRIBUTES[StackTracker.class]
					end,
					getFunc = function() return CombatMetronome.SV.StackTracker.hideInPVP end,
					setFunc = function(value)
						CombatMetronome.SV.StackTracker.hideInPVP = value
						StackTracker:TrackerPVPSwitch()
					end,
				},
				{
					type = "checkbox",
					name = "How does it look?",
					tooltip = "Shows tracker at the right of the screen to check your settings. This tracker is not movable!",
					warning = "This temporarily disables the Unlock function! Deactivate again to be able to unlock the tracker. This resets, if you leave the menu.",
					default = false,
					disabled = function ()
						return not (StackTracker:TrackerIsActive() and StackTracker:CheckIfSlotted())					--CM_TRACKER_CLASS_ATTRIBUTES[StackTracker.class]
					end,
					getFunc = function() return (StackTracker.showSampleTracker and StackTracker:TrackerIsActive() and StackTracker:CheckIfSlotted()) end,
					setFunc = function(value)
						StackTracker.showSampleTracker = value
						if value then
							StackTracker.UI.Position("Sample")
							StackTracker.UI.FadeScenes("Sample")
						else
							StackTracker.UI.Position("UI")
							StackTracker.UI.FadeScenes("NoSample")
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
						return not StackTracker.CLASS_ATTRIBUTES[StackTracker.class]
					end,
					controls = {
						{	type = "checkbox",
							name = "Unlock Tracker",
							tooltip = "Move stack tracker",
							-- width = "half",
							disabled = function ()
								return not (StackTracker:TrackerIsActive() and StackTracker:CheckIfSlotted()) or StackTracker.showSampleTracker		--CM_TRACKER_CLASS_ATTRIBUTES[StackTracker.class]
							end,
							getFunc = function() return CombatMetronome.SV.StackTracker.isUnlocked end,
							setFunc = function(value)
								CombatMetronome.SV.StackTracker.isUnlocked = value
								StackTracker.UI.stacksWindow:SetMovable(value)
								if not value then
									StackTracker.UI.stacksWindow:SetHidden(true)
								-- if value then
									-- StackTracker.UI.stacksWindow:SetDrawTier(DT_HIGH)
								-- else
									StackTracker.UI.stacksWindow:SetDrawTier(DT_LOW)
								end
							end,
						},
						-- {
							-- type = "checkbox",
							-- name = "Show tracker over settings menu",
							-- tooltip = "Shows tracker over settings menu in unlocked mode",
							-- disabled = function() return not CombatMetronome.SV.StackTracker.isUnlocked end,
							-- width = "half",
							-- getFunc = function() return false end,
							-- setFunc = function(value)
								-- if self:TrackerIsActive() then
									-- StackTracker.UI.stacksWindow:SetHidden(not value)
									-- if value then
										-- StackTracker.UI.stacksWindow:SetDrawTier(DT_HIGH)
									-- else
										-- StackTracker.UI.stacksWindow:SetDrawTier(DT_LOW)
									-- end
								-- end
							-- end,
						-- },
						{	type = "slider",
							name = "Stack indicator size",
							disabled = function()
								if StackTracker.class == "ARC" and CombatMetronome.SV.StackTracker.trackCrux then
									value = false
								elseif StackTracker.class == "SORC" and CombatMetronome.SV.StackTracker.trackBA then
									value = false
								elseif StackTracker.class == "DK" and CombatMetronome.SV.StackTracker.trackMW then
									value = false
								elseif StackTracker.class == "NB" and CombatMetronome.SV.StackTracker.trackGF then
									value = false
								else
									value = true
								end
								return value
							end,
							min = 10,
							max = 60,
							step = 1,
							default = CombatMetronome.SV.StackTracker.indicatorSize,
							getFunc = function() return CombatMetronome.SV.StackTracker.indicatorSize end,
							setFunc = function(value)
								CombatMetronome.SV.StackTracker.indicatorSize = value
								StackTracker.UI.indicator.ApplySize(value)
								StackTracker.UI.indicator.ApplyDistance(value/5, value)
								local attributes = StackTracker.CLASS_ATTRIBUTES[StackTracker.class]
								StackTracker.UI.stacksWindow:SetDimensions((value*attributes.iMax+(value/5)*(attributes.iMax-1)), value)
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
						return not StackTracker.CLASS_ATTRIBUTES[StackTracker.class]
					end,
					controls = {
						{
							type = "checkbox",
							name = "Track Molten Whip Stacks",
							-- warning = "If changed, will automaticly reload the UI.",
							disabled = function()
								return StackTracker.class ~= "DK"
							end,
							getFunc = function() return CombatMetronome.SV.StackTracker.trackMW end,
							setFunc = function(value)
								CombatMetronome.SV.StackTracker.trackMW = value
								-- ReloadUI()
							end
						},
						{
							type = "checkbox",
							name = "Track Bound Armaments Stacks",
							-- warning = "If changed, will automaticly reload the UI.",
							disabled = function()
								return StackTracker.class ~= "SORC"
							end,
							getFunc = function() return CombatMetronome.SV.StackTracker.trackBA end,
							setFunc = function(value)
								CombatMetronome.SV.StackTracker.trackBA = value
								-- ReloadUI()
							end
						},
						{
							type = "checkbox",
							name = "Track Stacks of Grimm Focus and its Morphs",
							-- warning = "If changed, will automaticly reload the UI.",
							disabled = function()
								return StackTracker.class ~= "NB"
							end,
							getFunc = function() return CombatMetronome.SV.StackTracker.trackGF end,
							setFunc = function(value)
								CombatMetronome.SV.StackTracker.trackGF = value
								-- ReloadUI()
							end
						},
						{
							type = "checkbox",
							name = "Track Crux Stacks",
							-- warning = "If changed, will automaticly reload the UI.",
							disabled = function() 
								return StackTracker.class ~= "ARC"
							end,
							getFunc = function() return CombatMetronome.SV.StackTracker.trackCrux end,
							setFunc = function(value)
								CombatMetronome.SV.StackTracker.trackCrux = value
								-- ReloadUI()
							end
						},
						{
							type = "checkbox",
							name = "Track Stacks of flame skull and its Morphs",
							-- warning = "If changed, will automaticly reload the UI.",
							disabled = function()
								return StackTracker.class ~= "CRO"
							end,
							getFunc = function() return CombatMetronome.SV.StackTracker.trackFS end,
							setFunc = function(value)
								CombatMetronome.SV.StackTracker.trackFS = value
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
						return not StackTracker.CLASS_ATTRIBUTES[StackTracker.class]
					end,
					controls = {
						{	type = "checkbox",
							name = "Play sound cue at max stacks",
							tooltip = "Plays a sound when you are at max stacks, so you don't miss to cast your ability",
							disabled = function ()
								return not StackTracker:TrackerIsActive()											--CM_TRACKER_CLASS_ATTRIBUTES[StackTracker.class]
							end,
							getFunc = function() return CombatMetronome.SV.StackTracker.playSound end,
							setFunc = function(value) CombatMetronome.SV.StackTracker.playSound = value end,
						},
						{
							type = "slider",
							name = "Sound cue volume",
							tooltip = "Adjust volume of the sound cue effect",
							warning = "You may have to adjust your general audio settings and general audio volume for this to have a noticable effect. Take care not to overadjust, your ears can only take so much!",
							disabled = function() return not CombatMetronome.SV.StackTracker.playSound end,
							min = 0,
							max = 100,
							setp = 1,
							getFunc = function() return CombatMetronome.SV.StackTracker.volume end,
							setFunc = function(value) CombatMetronome.SV.StackTracker.volume = value end,
						},
						{
							type = "dropdown",
							name = "Select Sound",
							choices = fullStackSounds,
							default = CombatMetronome.SV.StackTracker.sound,
							disabled = function() return not (StackTracker:TrackerIsActive() and CombatMetronome.SV.StackTracker.playSound) end,
							getFunc = function() return CombatMetronome.SV.StackTracker.sound end,
							setFunc = function(value) 
								CombatMetronome.SV.StackTracker.sound = value
								PlaySound(SOUNDS[value])
							end
						},
						{	type = "checkbox",
							name = "Play animation when reaching full stacks",
							tooltip = "Gives you a more intense visual cue",
							-- width = "half",
							disabled = function ()
								return not StackTracker:TrackerIsActive()											--CM_TRACKER_CLASS_ATTRIBUTES[StackTracker.class]
							end,
							getFunc = function() return CombatMetronome.SV.StackTracker.hightlightOnFullStacks end,
							setFunc = function(value)
								CombatMetronome.SV.StackTracker.hightlightOnFullStacks = value
							end,
						},
						-- {
							-- type = "checkbox",
							-- name = "Hide Tracker",
							-- disabled = function ()
								-- return not StackTracker.UI.stacksWindow
							-- end,
							-- getFunc = function() return CombatMetronome.SV.StackTracker.hideTracker end,
							-- setFunc = function(value)
								-- CombatMetronome.SV.StackTracker.hideTracker = value
								-- StackTracker.UI.DefineFragmentScenes(not value)
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
								-- return not StackTracker.UI.stacksWindow
							-- end,
							-- func = function()
								-- StackTracker.UI.stacksWindow:SetAnchor(TOPLEFT, GuiRoot, TOPLEFT, GuiRoot:GetWidth()/2, GuiRoot:GetHeight()/2)
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
						return CombatMetronome.SV.LATracker.choice == "Nothing"
					end,
					getFunc = function() return CombatMetronome.SV.LATracker.hideInPVP end,
					setFunc = function(value)
						CombatMetronome.SV.LATracker.hideInPVP = value
						LATracker:DisplayText()
					end,
				},
				{	type = "checkbox",
					name = "Unlock light attack tracker",
					tooltip = "Enable moving the tracker label",
					default = false,
					getFunc = function() return CombatMetronome.SV.LATracker.isUnlocked end,
					setFunc = function(value)
						CombatMetronome.SV.LATracker.isUnlocked = value
						LATracker.frame:SetUnlocked(value)
						if value then
							LATracker.frame:SetDrawTier(DT_HIGH)
							LATracker.frame:SetHidden(false)
							LATracker:DisplayText()
						else
							LATracker.frame:SetDrawTier(DT_LOW)
							LATracker.frame:SetHidden(true)
							LATracker.label:SetHidden(true)
						end
					end,
				},
				{	type = "dropdown",
					name = "What to track",
					tooltip = "Define whether tracker should be displaying light attacks per second, time between light attacks, or nothing at all",
					choices = LATrackerChoices,
					default = "Nothing",
					getFunc = function() return CombatMetronome.SV.LATracker.choice end,
					setFunc = function(value)
						CombatMetronome.SV.LATracker.choice = value
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
					getFunc = function() return CombatMetronome.SV.LATracker.timeTilHiding end,
					setFunc = function(value)
						CombatMetronome.SV.LATracker.timeTilHiding = value
					end,
				},
				{	type = "checkbox",
					name = "Show LA record after fight",
					tooltip = "Gives you a small record of duration of the fight, la/s and the total amount of light attacks",
					default = false,
					getFunc = function() return CombatMetronome.SV.LATracker.showLALogAfterFight end,
					setFunc = function(value)
						CombatMetronome.SV.LATracker.showLALogAfterFight = value
					end,
				},
			},
		},
		{	type = "divider",},
		-- end
		---------------
		---- DEBUG ----
		---------------
        {	type = "header",
            name = "Debug",
            description = "Debug section"
        },
        {	type = "checkbox",
            name = "Enable debugging",
			disabled = function() if CombatMetronome.debug then return false else return true end end,
            getFunc = function() return CombatMetronome.SV.debug.enabled end,
            setFunc = function(value)
                CombatMetronome.SV.debug.enabled = value
				-- CombatMetronome.debug:SetEnabled(value)
				if not value then
					CombatMetronome:SetAllDebugFalse()
				end
                -- self.log = value
            end
        },
		{	type = "submenu",
			name = "Debug Options",
			disabled = function() return not CombatMetronome.SV.debug.enabled end,
			controls = {
				{	type = "checkbox",
					name = "Debug ability.lua triggers",
					getFunc = function() return CombatMetronome.SV.debug.triggers end,
					setFunc = function(value)
						CombatMetronome.SV.debug.triggers = value
						-- self.log = value
					end,
					width = "half",
				},
				{
					type = "slider",
					name = "Ability trigger timer",
					tooltip = "The goal is to set it as low as possible and still have all the spells triggered",
					min = 50,
					max = 400,
					step = 10,
					width = "half",
					disabled = function() return not CombatMetronome.SV.debug.triggers end,
					getFunc = function() return CombatMetronome.SV.debug.triggerTimer end,
					setFunc = function(value)
						CombatMetronome.SV.debug.triggerTimer = value
					end,
				},
				{	type = "checkbox",
					name = "Debug ability.lua currentEvent",
					getFunc = function() return CombatMetronome.SV.debug.currentEvent end,
					setFunc = function(value)
						CombatMetronome.SV.debug.currentEvent = value
						-- self.log = value
					end,
					width = "half",
				},
				{	type = "checkbox",
					name = "Debug ability.lua queuedEvent",
					getFunc = function() return CombatMetronome.SV.debug.eventCancel end,
					setFunc = function(value)
						CombatMetronome.SV.debug.eventCancel = value
						-- self.log = value
					end,
					width = "half",
				},
				{	type = "checkbox",
					name = "Debug ability.lua AbilityUsed()",
					getFunc = function() return CombatMetronome.SV.debug.abilityUsed end,
					setFunc = function(value)
						CombatMetronome.SV.debug.abilityUsed = value
						-- self.log = value
					end,
					width = "half",
				},
			},
		},
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
				-- if self.SV.debug.enabled then CombatMetronome.debug:Print(ProgressionSkill) end
				-- if self.SV.debug.enabled then CombatMetronome.debug:Print(skillType..","..skillLineIndex..","..skillIndex..","..morphChoice..","..rank) end
				-- if self.SV.debug.enabled then CombatMetronome.debug:Print(skillType2..","..skillLineIndex2..","..skillIndex2..","..morphChoice2..","..rank2) end
				-- if self.SV.debug.enabled then CombatMetronome.debug:Print(skillType3..","..skillLineIndex3..","..skillIndex3..","..morphChoice3..","..rank3) end
				-- if self.SV.debug.enabled then CombatMetronome.debug:Print(ProgressionRank) end
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