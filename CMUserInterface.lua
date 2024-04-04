-- local LAM = LibAddonMenu2
local Util = DariansUtilities

local MIN_WIDTH = 50
local MAX_WIDTH = 500
local MIN_HEIGHT = 10
local MAX_HEIGHT = 100

	---------------------------
	---- Build Progressbar ----
	---------------------------

function CombatMetronome:BuildUI()

	--------------------------
	---- Create bar frame ----
	--------------------------
	
		if not self.frame then
			self.frame = Util.Controls:NewFrame(self.name.."Frame")
			self.frame:SetDimensionConstraints(MIN_WIDTH, MIN_HEIGHT, MAX_WIDTH, MAX_HEIGHT)
			self.frame:SetHandler("OnMoveStop", function(...)
				self.config.xOffset = self.frame:GetLeft()
				self.config.yOffset = self.frame:GetTop()
				-- self:BuildUI()
			end)
			self.frame:SetHandler("OnResizeStop", function(...)
				self.config.width = self.frame:GetWidth()
				self.config.height = self.frame:GetHeight()
				-- self:BuildUI()
			end)
		end
		self.frame:SetDimensions(self.config.width, self.config.height)
		self.frame:ClearAnchors()
		self.frame:SetAnchor(TOPLEFT, GuiRoot, TOPLEFT, self.config.xOffset, self.config.yOffset)

	--------------------------
	---- Create Timer bar ----
	--------------------------

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
		
	--------------------------------------
	---- Create spell icon and border ----
	--------------------------------------
		
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
		
	-----------------------
	---- Make it fancy ----
	-----------------------
	
		self.bar.backgroundTexture = self.bar.backgroundTexture or WINDOW_MANAGER:CreateControl(self.name.."BackgroundTexture", self.frame, CT_STATUSBAR)
		self.bar.backgroundTexture:SetDimensions(self.config.width, self.config.height)
		self.bar.backgroundTexture:SetTexture("/esoui/art/unitframes/progressbar_mechanic_fill.dds")
		self.bar.backgroundTexture:ClearAnchors()
		if self.config.barAlign == "Right" then
			self.bar.backgroundTexture:SetAnchor(RIGHT, self.frame, RIGHT, 0, 0)
		elseif self.config.barAlign == "Left" then
			self.bar.backgroundTexture:SetAnchor(LEFT, self.frame, LEFT, 0, 0)
		else
			self.bar.backgroundTexture:SetAnchor(CENTER, self.frame, CENTER, 0, 0)
		end
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
		self.bar.borderL:SetHidden(true)
		self.bar.borderR:SetHidden(true)
		
	----------------------------
	---- Create spell label ----
	----------------------------

		self.spellLabel = self.spellLabel or WINDOW_MANAGER:CreateControl(self.name.."SpellLabel", self.frame, CT_LABEL)
		self.spellLabel:ClearAnchors()
		self.spellLabel:SetAnchor(CENTER, self.frame, CENTER, 0, 0)
		self.spellLabel:SetColor(1, 1, 1, 1)

		self.spellLabel:SetFont(Util.Text.getFontString(self.config.labelFont, math.floor(self.config.width/20), "outline"))
		self.spellLabel:SetHidden(false)
		self.spellLabel:SetText("")
		self.spellLabel:SetDrawLayer(4)
		self.spellLabel:SetDrawTier(2)
		
	-------------------------------------
	---- Create time remaining label ----
	-------------------------------------
		
		self.timeLabel = self.timeLabel or WINDOW_MANAGER:CreateControl(self.name.."TimeLabel", self.frame, CT_LABEL)
		self.timeLabel:ClearAnchors()
		if self.config.barAlign == "Right" then
			self.timeLabel:SetAnchor(LEFT, self.frame, LEFT, (self.config.height/5), 0)
		else
			self.timeLabel:SetAnchor(RIGHT, self.frame, RIGHT, -(self.config.height/5), 0)
		end
		self.timeLabel:SetColor(1, 1, 1, 1)

		self.timeLabel:SetFont(Util.Text.getFontString(self.config.labelFont, math.floor(self.config.width/20), "outline"))
		self.timeLabel:SetHidden(false)
		self.timeLabel:SetText("")
		self.timeLabel:SetDrawLayer(4)
		self.timeLabel:SetDrawTier(2)
			
    ----------------------------
	---- Create label frame ----
	----------------------------

    self.labelFrame = self.labelFrame or Util.Controls:NewFrame(self.name.."LabelFrame")
    self.labelFrame:SetDimensions(self.config.width, 50)
    self.labelFrame:ClearAnchors()
    self.labelFrame:SetAnchor(BOTTOM, self.frame, TOP, 0, 0)

    -------------------------------
	---- Create ultimate label ----
	-------------------------------

    self.ultLabel = self.ultLabel or WINDOW_MANAGER:CreateControl(self.name.."UltLabel", self.labelFrame, CT_LABEL)
    self.ultLabel:ClearAnchors()
    self.ultLabel:SetAnchor(BOTTOM, self.labelFrame, BOTTOM, 0, 0)
    self.ultLabel:SetColor(1, 1, 1, 1)

    self.ultLabel:SetFont(Util.Text.getFontString(self.config.labelFont, self.config.ultSize, "outline"))
    self.ultLabel:SetHidden(false)
    self.ultLabel:SetText("")

    ------------------------------
	---- Create stamina label ----
	------------------------------

    self.stamLabel = self.stamLabel or WINDOW_MANAGER:CreateControl(self.name.."StamLabel", self.labelFrame, CT_LABEL)
    self.stamLabel:ClearAnchors()
    self.stamLabel:SetAnchor(BOTTOMLEFT, self.labelFrame, BOTTOMLEFT, 0, 0)
    self.stamLabel:SetColor(unpack(self.config.stamColor))
    self.stamLabel:SetFont(Util.Text.getFontString(self.config.labelFont, self.config.stamSize, "outline"))
    self.stamLabel:SetHidden(false)
    self.stamLabel:SetText("")

	------------------------------
	---- Create magicka label ----
	------------------------------

    self.magLabel = self.magLabel or WINDOW_MANAGER:CreateControl(self.name.."MagLabel", self.labelFrame, CT_LABEL)
    self.magLabel:ClearAnchors()
    self.magLabel:SetAnchor(TOPLEFT, self.labelFrame, TOPLEFT, 0, 0)
    self.magLabel:SetColor(unpack(self.config.magColor))
    self.magLabel:SetFont(Util.Text.getFontString(self.config.labelFont, self.config.magSize, "outline"))
    self.magLabel:SetHidden(false)
    self.magLabel:SetText("")

    ------------------------------------
	---- Create target health label ----
	------------------------------------

    self.hpLabel = self.hpLabel or WINDOW_MANAGER:CreateControl(self.name.."HPLabel", self.labelFrame, CT_LABEL)
    self.hpLabel:ClearAnchors()
    if self.config.reticleHp then
        self.hpLabel:SetAnchor(LEFT, GuiRoot, CENTER, 40, 0)
    else
        self.hpLabel:SetAnchor(BOTTOMRIGHT, self.labelFrame, BOTTOMRIGHT, 0, 0)
    end
    self.hpLabel:SetColor(unpack(self.config.healthColor))
    self.hpLabel:SetFont(Util.Text.getFontString(self.config.labelFont, self.config.healthSize, "outline"))
    self.hpLabel:SetHidden(false)
    self.hpLabel:SetText("")
end

	-----------------------------
	---- Build Stack Tracker ----
	-----------------------------

function CombatMetronome:BuildStackTracker()
	local attributes = CM_TRACKER_CLASS_ATTRIBUTES[self.class]
	local size = self.config.indicatorSize
	local distance = size/5
	
	if self.class == "NB" then
		local value = self:CheckForGFMorph()
		attributes.graphic = attributes.icon[value]
	end
	
	------------------------------
	---- Build TopLevelWindow ----
	------------------------------
	
	-- if not stacksWindow then
		-- local stacksWindow = Util.Controls:NewFrame(self.name.."StackTrackerWindow")
		local stacksWindow = WINDOW_MANAGER:CreateTopLevelWindow(self.name.."StackTrackerWindow")
		stacksWindow:SetHandler( "OnMoveStop", function(...)
			self.config.trackerX = stacksWindow:GetLeft()
			self.config.trackerY = stacksWindow:GetTop()
		end)
		stacksWindow:SetDimensions((size*attributes.iMax+distance*(attributes.iMax-1)), size)
		stacksWindow:ClearAnchors()
		stacksWindow:SetAnchor(TOPLEFT, GuiRoot, TOPLEFT, self.config.trackerX, self.config.trackerY)
		stacksWindow:SetMouseEnabled(true)
		stacksWindow:SetMovable(self.config.trackerIsUnlocked)
		stacksWindow:SetClampedToScreen(true)
		stacksWindow:SetHidden(true)
	-- end
	
	local fragment = ZO_HUDFadeSceneFragment:New(stacksWindow) 
	local function showTracker(enabled)
		if enabled then
			SCENE_MANAGER:GetScene("hud"):AddFragment(fragment)
			SCENE_MANAGER:GetScene("hudui"):AddFragment(fragment)
		else
			SCENE_MANAGER:GetScene("hud"):RemoveFragment(fragment)
			SCENE_MANAGER:GetScene("hudui"):RemoveFragment(fragment)
		end
	end
	
	-----------------------------
	---- Generate Indicators ----
	-----------------------------
	
	local indicator = {}

	local function GetIndicator(i)
	
	-----------------------------
	---- Build new indicator ----
	-----------------------------
		
		-- if not stackIndicator then
			local stackIndicator = WINDOW_MANAGER:CreateControl(self.name.."StackIndicator"..tostring(i), stacksWindow, CT_CONTROL)
			-- d("stackIndicator "..tostring(i).." created")
		-- end
		
		-- if not icon then
			local icon = WINDOW_MANAGER:CreateControl(self.name.."StackIcon"..tostring(i), stackIndicator, CT_TEXTURE)
			icon:ClearAnchors() 
			icon:SetAnchor(TOPLEFT, stackIndicator, TOPLEFT, 0, 0) 
			icon:SetDesaturation(0.1)
			icon:SetTexture(attributes.graphic)
			-- d(tostring("stackIcon "..i.." created"))
		-- end
		
		-- if not frame then
			local frame = WINDOW_MANAGER:CreateControl(self.name.."StackFrame"..tostring(i), stackIndicator, CT_TEXTURE)
			frame:ClearAnchors()
			frame:SetAnchor(TOPLEFT, stackIndicator, TOPLEFT, 0, 0)
			-- frame:SetTexture("esoui/art/champion/actionbar/champion_bar_slot_frame_disabled.dds")
			frame:SetTexture("/esoui/art/actionbar/abilityframe64_up.dds")
			-- d(tostring("stackFrame "..i.." created"))
		-- end
		
		-- if not highlight then
			local highlight = WINDOW_MANAGER:CreateControl(self.name.."StackHighlight"..tostring(i), stackIndicator, CT_TEXTURE)
			highlight:ClearAnchors()
			highlight:SetAnchor(TOPLEFT, stackIndicator, TOPLEFT, 0, 0)
			highlight:SetDesaturation(0.4)
			highlight:SetTexture("/esoui/art/actionbar/actionslot_toggledon.dds")
			highlight:SetColor(unpack(attributes.highlight))
		-- end
		
		local highlightAnimation = WINDOW_MANAGER:CreateControl(self.name.."StackHighlightAnimation"..tostring(i), stackIndicator, CT_TEXTURE)
		highlightAnimation:ClearAnchors()
		-- highlightAnimation:SetAnchor(TOPLEFT, stackIndicator, TOPLEFT, 0, 0)
		-- highlightAnimation:SetAnchor(BOTTOMRIGHT, stackIndicator, BOTTOMRIGHT, 0, 0)
		-- highlightAnimation:SetTexture("/esoui/art/actionbar/abilityhighlight_03.dds")
		highlightAnimation:SetTexture("/esoui/art/actionbar/abilityhighlight_mage_med.dds")
		highlightAnimation:SetDrawTier(DT_HIGH)
		highlightAnimation:SetColor(unpack(attributes.highlightAnimation))
		-- highlightAnimation:SetDuration(2000)
		
		local highlightAnimationTimeline = ANIMATION_MANAGER:CreateTimelineFromVirtual("StackReadyLoop", highlightAnimation)
		-- highlightAnimationTimeline:PlayFromStart()
		highlightAnimation:SetHidden(true)
		
	------------------------------
	---- Highlighting Handler ----
	------------------------------
		
		local function Activate()
			icon:SetColor(1,1,1,0.8)
			highlight:SetAlpha(0.8)
		end

		local function Deactivate()
			icon:SetColor(0.1,0.1,0.1,0.7)
			highlight:SetAlpha(0)
		end
		
		local function Animate()
			-- d(tostring(highlightAnimationTimeline:GetDuration()))
			highlightAnimation:SetHidden(false)
			highlightAnimationTimeline:PlayFromStart()
			-- d("Animation should've started")
		end
		
		local function StopAnimation()
			highlightAnimationTimeline:Stop()
			highlightAnimation:SetHidden(true)
			-- d("Animation should've stopped")
		end

		local controls = {
		stackIndicator = stackIndicator,
		frame = frame,
		icon = icon,
		highlight = highlight,
		highlightAnimation = highlightAnimation,
		highlightAnimationTimeline = highlightAnimationTimeline,
		}
		return {
		stacksWindow = stacksWindow,
		controls = controls,
		Activate = Activate,
		Deactivate = Deactivate,
		Animate = Animate,
		StopAnimation = StopAnimation,
		}
	end

	for i =1,attributes.iMax do 
		indicator[i] = GetIndicator(i)
	end 
	
	-----------------------
	---- Changing Size ----
	-----------------------
	
	local function ApplySize(size) 
		for i=1,attributes.iMax do 
			indicator[i].controls.frame:SetDimensions(size,size)
			indicator[i].controls.highlight:SetDimensions(size,size)
			indicator[i].controls.icon:SetDimensions(size,size)
			indicator[i].controls.highlightAnimation:SetAnchor(TOPLEFT, stackIdicator, TOPLEFT, math.floor(size/20), math.floor(size/20))
			indicator[i].controls.highlightAnimation:SetAnchor(BOTTOMRIGHT, stackIndicator, BOTTOMRIGHT, size-math.floor(size/20), size-math.floor(size/20))
		end
	end
	indicator.ApplySize = ApplySize
	
	local function ApplyDistance(distance, size) 
		for i=1,attributes.iMax do
			-- local xOffset = (i-(attributes.iMax+1)/2)*(size+distance)
			local xOffset = (i-1)*(size+distance)
			indicator[i].controls.stackIndicator:ClearAnchors()
			indicator[i].controls.stackIndicator:SetAnchor(TOPLEFT, stacksWindow, TOPLEFT, xOffset, 0)
		end
	end
	indicator.ApplyDistance = ApplyDistance

	return {
	stacksWindow = stacksWindow,
	indicator = indicator,
	showTracker = showTracker,
	}
end