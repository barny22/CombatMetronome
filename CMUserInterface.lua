local MIN_WIDTH = 50
local MAX_WIDTH = 500
local MIN_HEIGHT = 10
local MAX_HEIGHT = 100

function CombatMetronome:BuildUI()

    -- Create Bar Frame

    if not self.frame then
        self.frame = Util.Controls:NewFrame(self.name.."Frame")
        self.frame:SetDimensionConstraints(MIN_WIDTH, MIN_HEIGHT, MAX_WIDTH, MAX_HEIGHT)
        self.frame:SetHandler("OnMoveStop", function(...)
            self.config.xOffset = self.frame:GetLeft()
            self.config.yOffset = self.frame:GetTop()
            self:BuildUI()
        end)
        self.frame:SetHandler("OnResizeStop", function(...)
            self.config.width = self.frame:GetWidth()
            self.config.height = self.frame:GetHeight()
            self:BuildUI()
        end)
    end
    self.frame:SetDimensions(self.config.width, self.config.height)
    self.frame:ClearAnchors()
    self.frame:SetAnchor(TOPLEFT, GuiRoot, TOPLEFT, self.config.xOffset, self.config.yOffset)

    -- Create Timer Bar

    self.bar = self.bar or Util.Bar:New(self.name.."TimerBar", self.frame)
    self.bar.background:SetCenterColor(unpack(self.config.backgroundColor))
    self.bar.background:SetDimensions(self.config.width, self.config.height)
    self.bar.background:ClearAnchors()
    self.bar.background:SetAnchorFill()
    self.bar.align = ((self.config.barAlign == "Left") and LEFT)
                  or ((self.config.barAlign == "Center") and CENTER)
                  or  RIGHT
    self.bar:UpdateSegment(1, {
        color = self.config.pingColor,
    })
    self.bar:UpdateSegment(2, {
        color = self.config.progressColor,
        clip = true,
    })
    self.bar:SetHidden(not self.config.dontHide)
	
	-- Create Icon space and border (barny)
	
	self.spellIcon = self.spellIcon or WINDOW_MANAGER:CreateControl(self.name.."SpellIcon", self.frame, CT_TEXTURE)
	self.spellIcon:ClearAnchors()
	if self.config.barAlign == "Right" then
		self.spellIcon:SetAnchor(LEFT, self.frame, RIGHT, (self.config.height/10), 0)
	else
		self.spellIcon:SetAnchor(RIGHT, self.frame, LEFT, -(self.config.height/10), 0)
	end
	self.spellIconBorder = self.spellIconBorder or WINDOW_MANAGER:CreateControl(self.name.."SpellIconBorder", self.spellIcon, CT_TEXTURE)
	self.spellIconBorder:ClearAnchors()
	self.spellIconBorder:SetAnchor(CENTER, self.spellIcon, CENTER, 0, 0)
	self.spellIconBorder:SetDimensions(self.config.height, self.config.height)
	self.spellIconBorder:SetTexture("/esoui/art/actionbar/abilityframe64_up.dds")
	self.spellIconBorder:SetHidden(true)
	self.spellIcon:SetDimensions(self.config.height, self.config.height)
	self.spellIcon:SetHidden(true)
	
	-- Make it fancy
	self.bar.backgroundTexture = self.bar.backgroundTexture or WINDOW_MANAGER:CreateControl(self.name.."BackgroundTexture", self.frame, CT_STATUSBAR)
	self.bar.backgroundTexture:SetDimensions(self.config.width, self.config.height)
	self.bar.backgroundTexture:SetTexture("/esoui/art/unitframes/progressbar_mechanic_fill.dds")
	self.bar.backgroundTexture:ClearAnchors()
	if self.config.barAlign == "Right" then
		self.bar.backgroundTexture:SetAnchor(RIGHT, self.frame, RIGHT, 0, 0)
		-- self.bar.backgroundGloss:SetAnchor(RIGHT, self.frame, RIGHT, 0, 0)
	elseif self.config.barAlign == "Left" then
		self.bar.backgroundTexture:SetAnchor(LEFT, self.frame, LEFT, 0, 0)
		-- self.bar.backgroundGloss:SetAnchor(LEFT, self.frame, LEFT, 0, 0)
	else
		self.bar.backgroundTexture:SetAnchor(CENTER, self.frame, CENTER, 0, 0)
		-- self.bar.backgroundGloss:SetAnchor(CENTER, self.frame, CENTER, 0, 0)
	end
	-- self.bar.frame = self.bar.frame or WINDOW_MANAGER:CreateControl(self.name.."BarFrame", self.nameBackgroundTexture, CT_TEXTURE)
	-- self.bar.frame:ClearAnchors()
	-- self.bar.frame:SetAnchor(LEFT, self.spellIcon, RIGHT, 0, 0)
    -- self.bar.frame:SetDimensions(self.config.width*1.2, self.config.height*1.2)
	-- self.bar.frame:SetTexture("/esoui/art/guild/guildranks_iconframe_disabled.dds")
	self.bar.borderL = self.bar.borderL or WINDOW_MANAGER:CreateControl(self.name.."SpellBarBorderL", self.frame, CT_TEXTURE)
	self.bar.borderL:ClearAnchors()
	self.bar.borderL:SetAnchor(TOPLEFT)
	self.bar.borderL:SetDimensions(self.config.width/2, self.config.height)
	self.bar.borderL:SetTexture("/esoui/art/unitframes/playercastbar_inset_left.dds")
	self.bar.borderL:SetDrawLayer(2)
	self.bar.borderL:SetDrawTier(1)
	self.bar.borderR = self.bar.borderR or WINDOW_MANAGER:CreateControl(self.name.."SpellBarBorderR", self.frame, CT_TEXTURE)
	self.bar.borderR:ClearAnchors()
	self.bar.borderR:SetAnchor(TOPRIGHT)
	self.bar.borderR:SetDimensions(self.config.width/2, self.config.height)
	self.bar.borderR:SetTexture("/esoui/art/unitframes/playercastbar_inset_right.dds")
	self.bar.borderR:SetDrawLayer(2)
	self.bar.borderR:SetDrawTier(1)
	self.bar.backgroundTexture:SetHidden(true)
	-- self.bar.frame:SetHidden(false)
	self.bar.borderL:SetHidden(true)
	self.bar.borderR:SetHidden(true)
	-- /esoui/art/progression/abilityframe_filled.dds
	-- /esoui/art/guild/guildranks_iconframe_disabled.dds
	-- /esoui/art/unitframes/unitframe_raid_outline_right.dds 32x64
	-- /esoui/art/unitframes/unitframe_raid_outline_left.dds
	
	-- Create Spell Label (barny)

    self.spellLabel = self.spellLabel or WINDOW_MANAGER:CreateControl(self.name.."SpellLabel", self.frame, CT_LABEL)
    self.spellLabel:ClearAnchors()
    self.spellLabel:SetAnchor(CENTER, self.frame, CENTER, 0, 0)
    self.spellLabel:SetColor(1, 1, 1, 1)

    self.spellLabel:SetFont(Util.Text.getFontString(nil, math.floor(self.config.width/20), "outline"))
    self.spellLabel:SetHidden(false)
    self.spellLabel:SetText("")
	self.spellLabel:SetDrawLayer(4)
	self.spellLabel:SetDrawTier(2)
	
	-- Create time Remaining Label (barny)
	
	self.timeLabel = self.timeLabel or WINDOW_MANAGER:CreateControl(self.name.."TimeLabel", self.frame, CT_LABEL)
	self.timeLabel:ClearAnchors()
	if self.config.barAlign == "Right" then
		self.timeLabel:SetAnchor(LEFT, self.frame, LEFT, (self.config.height/5), 0)
	else
		self.timeLabel:SetAnchor(RIGHT, self.frame, RIGHT, -(self.config.height/5), 0)
	end
	self.timeLabel:SetColor(1, 1, 1, 1)

	self.timeLabel:SetFont(Util.Text.getFontString(nil, math.floor(self.config.width/20), "outline"))
	self.timeLabel:SetHidden(false)
	self.timeLabel:SetText("")
	self.timeLabel:SetDrawLayer(4)
	self.timeLabel:SetDrawTier(2)

    -- Create Label Frame

    self.labelFrame = self.labelFrame or Util.Controls:NewFrame(self.name.."LabelFrame")
    self.labelFrame:SetDimensions(self.config.width, 50)
    self.labelFrame:ClearAnchors()
    self.labelFrame:SetAnchor(BOTTOM, self.frame, TOP, 0, 0)

    -- Create Ultimate Label

    self.ultLabel = self.ultLabel or WINDOW_MANAGER:CreateControl(self.name.."UltLabel", self.labelFrame, CT_LABEL)
    self.ultLabel:ClearAnchors()
    self.ultLabel:SetAnchor(BOTTOM, self.labelFrame, BOTTOM, 0, 0)
    self.ultLabel:SetColor(1, 1, 1, 1)

    self.ultLabel:SetFont(Util.Text.getFontString(nil, 50, "outline"))
    self.ultLabel:SetHidden(false)
    self.ultLabel:SetText("")

    -- Create Stamina Label

    self.stamLabel = self.stamLabel or WINDOW_MANAGER:CreateControl(self.name.."StamLabel", self.labelFrame, CT_LABEL)
    self.stamLabel:ClearAnchors()
    self.stamLabel:SetAnchor(BOTTOMLEFT, self.labelFrame, BOTTOMLEFT, 0, 0)
    self.stamLabel:SetColor(1, 1, 1, 1)
    self.stamLabel:SetFont(Util.Text.getFontString(nil, 30, "outline"))
    self.stamLabel:SetHidden(false)
    self.stamLabel:SetText("")

    -- Create Target Health Label

    self.hpLabel = self.hpLabel or WINDOW_MANAGER:CreateControl(self.name.."HPLabel", self.labelFrame, CT_LABEL)
    self.hpLabel:ClearAnchors()
    if self.config.reticleHp then
        self.hpLabel:SetAnchor(LEFT, GuiRoot, CENTER, 40, 0)
    else
        self.hpLabel:SetAnchor(BOTTOMRIGHT, self.labelFrame, BOTTOMRIGHT, 0, 0)
    end
    self.hpLabel:SetColor(1, 1, 1, 1)
    self.hpLabel:SetFont(Util.Text.getFontString(nil, 30, "outline"))
    self.hpLabel:SetHidden(false)
    self.hpLabel:SetText("")
end