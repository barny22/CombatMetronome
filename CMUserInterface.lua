-- local LAM = LibAddonMenu2
local Util = DariansUtilities

local MIN_WIDTH = 50
local MAX_WIDTH = 500
local MIN_HEIGHT = 10
local MAX_HEIGHT = 100

	---------------------------
	---- Build Progressbar ----
	---------------------------

function CombatMetronome:BuildProgressBar()

	-------------------------
	---- Create Controls ----
	-------------------------
	
	local function CreateControls()
		if not self.frame then
			self.frame = Util.Controls:NewFrame(self.name.."ProgressbarFrame")
			self.frame:SetDimensionConstraints(MIN_WIDTH, MIN_HEIGHT, MAX_WIDTH, MAX_HEIGHT)
			self.frame:SetHandler("OnMoveStop", function(...)
				self.config.xOffset = self.self.frame:GetLeft()
				self.config.yOffset = self.self.frame:GetTop()
				-- self:BuildProgressBar()
			end)
			self.frame:SetHandler("OnResizeStop", function(...)
				self.config.width = self.self.frame:GetWidth()
				self.config.height = self.self.frame:GetHeight()
				-- self:BuildProgressBar()
			end)
		end
		self.bar = self.bar or Util.Bar:New(self.name.."TimerBar", self.frame)
		
		self.spellIcon = self.spellIcon or WINDOW_MANAGER:CreateControl(self.name.."SpellIcon", self.frame, CT_TEXTURE)
		self.spellIconBorder = self.spellIconBorder or WINDOW_MANAGER:CreateControl(self.name.."SpellIconBorder", self.spellIcon, CT_TEXTURE)
		self.spellIconBorder:SetTexture("/esoui/art/actionbar/abilityframe64_up.dds")
	
		self.bar.backgroundTexture = self.bar.backgroundTexture or WINDOW_MANAGER:CreateControl(self.name.."BackgroundTexture", self.frame, CT_STATUSBAR)
		self.bar.backgroundTexture:SetTexture("/esoui/art/unitframes/progressbar_mechanic_fill.dds")
		self.bar.borderL = self.bar.borderL or WINDOW_MANAGER:CreateControl(self.name.."SpellBarBorderL", self.frame, CT_TEXTURE)
		self.bar.borderL:SetTexture("/esoui/art/unitframes/playercastbar_inset_left.dds")
		self.bar.borderL:SetDrawLayer(2)
		self.bar.borderL:SetDrawTier(1)
		self.bar.borderR = self.bar.borderR or WINDOW_MANAGER:CreateControl(self.name.."SpellBarBorderR", self.frame, CT_TEXTURE)
		self.bar.borderR:SetTexture("/esoui/art/unitframes/playercastbar_inset_right.dds")
		self.bar.borderR:SetDrawLayer(2)
		self.bar.borderR:SetDrawTier(1)

		self.spellLabel = self.spellLabel or WINDOW_MANAGER:CreateControl(self.name.."SpellLabel", self.frame, CT_LABEL)
		self.spellLabel:SetColor(1, 1, 1, 1)
		self.spellLabel:SetText("")
		self.spellLabel:SetDrawLayer(4)
		self.spellLabel:SetDrawTier(2)
		
		self.timeLabel = self.timeLabel or WINDOW_MANAGER:CreateControl(self.name.."TimeLabel", self.frame, CT_LABEL)
		self.timeLabel:SetColor(1, 1, 1, 1)
		self.timeLabel:SetText("")
		self.timeLabel:SetDrawLayer(4)
		self.timeLabel:SetDrawTier(2)
			
    -------------------------------
	---- Create label Controls ----
	-------------------------------

		self.labelFrame = self.labelFrame or Util.Controls:NewFrame(self.name.."LabelFrame")

		self.ultLabel = self.ultLabel or WINDOW_MANAGER:CreateControl(self.name.."UltLabel", self.labelFrame, CT_LABEL)
		self.ultLabel:SetText("")

		self.stamLabel = self.stamLabel or WINDOW_MANAGER:CreateControl(self.name.."StamLabel", self.labelFrame, CT_LABEL)
		self.stamLabel:SetText("")

		self.magLabel = self.magLabel or WINDOW_MANAGER:CreateControl(self.name.."MagLabel", self.labelFrame, CT_LABEL)
		self.magLabel:SetText("")

		self.hpLabel = self.hpLabel or WINDOW_MANAGER:CreateControl(self.name.."HPLabel", self.labelFrame, CT_LABEL)
		self.hpLabel:SetText("")
	end
	
	local function Position(value)
		self.frame:ClearAnchors()
		if value == "UI" then
			self.frame:SetAnchor(TOPLEFT, GuiRoot, TOPLEFT, self.config.xOffset, self.config.yOffset)
		elseif value == "Sample" then
			self.frame:SetAnchor(RIGHT, GuiRoot, RIGHT, -GuiRoot:GetWidth()/8, -GuiRoot:GetHeight()/6)
		end
	end
	
	local function Fonts()
		self.hpLabel:SetFont(Util.Text.getFontString(tostring("$("..self.config.labelFont..")"), self.config.healthSize, self.config.fontStyle))
		self.magLabel:SetFont(Util.Text.getFontString(tostring("$("..self.config.labelFont..")"), self.config.magSize, self.config.fontStyle))
		self.stamLabel:SetFont(Util.Text.getFontString(tostring("$("..self.config.labelFont..")"), self.config.stamSize, self.config.fontStyle))
		self.ultLabel:SetFont(Util.Text.getFontString(tostring("$("..self.config.labelFont..")"), self.config.ultSize, self.config.fontStyle))
		self.timeLabel:SetFont(Util.Text.getFontString(tostring("$("..self.config.labelFont..")"), math.floor(self.config.width/20), self.config.fontStyle))
		self.spellLabel:SetFont(Util.Text.getFontString(tostring("$("..self.config.labelFont..")"), math.floor(self.config.width/20), self.config.fontStyle))
	end
	
	local function LabelColors()
		self.hpLabel:SetColor(unpack(self.config.healthColor))
		self.magLabel:SetColor(unpack(self.config.magColor))
		self.stamLabel:SetColor(unpack(self.config.stamColor))
		self.ultLabel:SetColor(unpack(self.config.ultColor))
	end
	
	local function HiddenStates()
		self.hpLabel:SetHidden(true)
		self.magLabel:SetHidden(true)
		self.stamLabel:SetHidden(true)
		self.ultLabel:SetHidden(true)
		self.timeLabel:SetHidden(true)
		self.spellLabel:SetHidden(true)
		self.bar.backgroundTexture:SetHidden(not self.config.makeItFancy)
		self.bar.borderL:SetHidden(not self.config.makeItFancy)
		self.bar.borderR:SetHidden(not self.config.makeItFancy)
		self.spellIcon:SetHidden(true)
		self.spellIconBorder:SetHidden(true)
		self.bar:SetHidden(not self.config.dontHide)
	end
	
	local function Anchors()
		self.timeLabel:ClearAnchors()
		self.bar.backgroundTexture:ClearAnchors()
		self.spellIcon:ClearAnchors()
		self.spellIconBorder:ClearAnchors()
		self.spellIconBorder:SetAnchor(CENTER, self.spellIcon, CENTER, 0, 0)
		self.bar.borderR:ClearAnchors()
		self.bar.borderR:SetAnchor(TOPRIGHT)
		self.bar.borderL:ClearAnchors()
		self.bar.borderL:SetAnchor(TOPLEFT)
		self.spellLabel:ClearAnchors()
		self.spellLabel:SetAnchor(CENTER, self.frame, CENTER, 0, 0)
		self.bar.background:ClearAnchors()
		self.bar.background:SetAnchorFill()
		if self.config.barAlign == "Right" then
			self.timeLabel:SetAnchor(LEFT, self.frame, LEFT, (self.config.height/5), 0)
			self.bar.backgroundTexture:SetAnchor(RIGHT, self.frame, RIGHT, 0, 0)
			self.spellIcon:SetAnchor(LEFT, self.frame, RIGHT, (self.config.height/10), 0)
			self.bar.align = RIGHT
		elseif self.config.barAlign == "Left" then
			self.bar.backgroundTexture:SetAnchor(LEFT, self.frame, LEFT, 0, 0)
			self.timeLabel:SetAnchor(RIGHT, self.frame, RIGHT, -(self.config.height/5), 0) 
			self.spellIcon:SetAnchor(RIGHT, self.frame, LEFT, -(self.config.height/10), 0)
			self.bar.align = LEFT
		else
			self.bar.backgroundTexture:SetAnchor(CENTER, self.frame, CENTER, 0, 0)
			self.timeLabel:SetAnchor(RIGHT, self.frame, RIGHT, -(self.config.height/5), 0) 
			self.spellIcon:SetAnchor(RIGHT, self.frame, LEFT, -(self.config.height/10), 0)
			self.bar.align = CENTER
		end
		
		-----------------------
		---- Label Anchors ----
		-----------------------
		
		self.hpLabel:ClearAnchors()
		if self.config.reticleHp then
			self.hpLabel:SetAnchor(LEFT, GuiRoot, CENTER, 40, 0)
		else
			self.hpLabel:SetAnchor(BOTTOMRIGHT, self.labelFrame, BOTTOMRIGHT, 0, 0)
		end
		self.magLabel:ClearAnchors()
		self.magLabel:SetAnchor(TOPLEFT, self.labelFrame, TOPLEFT, 0, 0)
		self.stamLabel:ClearAnchors()
		self.stamLabel:SetAnchor(BOTTOMLEFT, self.labelFrame, BOTTOMLEFT, 0, 0)
		self.ultLabel:ClearAnchors()
		self.ultLabel:SetAnchor(BOTTOM, self.labelFrame, BOTTOM, 0, 0)
		self.labelFrame:ClearAnchors()
		self.labelFrame:SetAnchor(BOTTOM, self.frame, TOP, 0, 0)
	end
	
	local function Size()
		self.frame:SetDimensions(self.config.width, self.config.height)
		self.labelFrame:SetDimensions(self.config.width, 50)
		self.bar.background:SetDimensions(self.config.width, self.config.height)
		self.bar.borderR:SetDimensions(self.config.width/2, self.config.height)
		self.bar.borderL:SetDimensions(self.config.width/2, self.config.height)
		self.bar.backgroundTexture:SetDimensions(self.config.width, self.config.height)
		self.spellIconBorder:SetDimensions(self.config.height, self.config.height)
		self.spellIcon:SetDimensions(self.config.height, self.config.height)
		Anchors()
	end
	
	local function BarColors()
		self.bar.background:SetCenterColor(unpack(self.config.backgroundColor))
		self.bar:UpdateSegment(1, {
			color = self.config.pingColor,
		})
		self.bar:UpdateSegment(2, {
			color = self.config.progressColor,
			clip = true,
		})
	end
		
	SCENE_MANAGER:RegisterCallback("SceneStateChanged", function(scene, newState)
		if scene:GetName() == "gameMenuInGame" and newState == "hiding" and self.showSampleBar then
			-- d("should've changed visibility on sampleBar")
			self.showSampleBar = false
			Position("UI")
			HiddenStates()
		end
	end)
	
	CreateControls()
	Position()
	Size()
	Anchors()
	BarColors()
	Fonts()
	LabelColors()
	HiddenStates()
	Position("UI")
	
	return {
		Fonts = Fonts,
		LabelColors = LabelColors,
		HiddenStates = HiddenStates,
		Anchors = Anchors,
		Size = Size,
		BarColors = BarColors,
		CreateControls = CreateControls,
		FadeScenes = FadeScenes,
		Position = Position,
	}
		
end

	-----------------------------
	---- Build Stack Tracker ----
	-----------------------------

function CombatMetronome:BuildStackTracker()
	local attributes = CM_TRACKER_CLASS_ATTRIBUTES[self.class]
	local size = self.config.indicatorSize
	local distance = size/5
	
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
		stacksWindow:SetMouseEnabled(true)
		stacksWindow:SetMovable(self.config.trackerIsUnlocked)
		stacksWindow:SetClampedToScreen(true)
		stacksWindow:SetHidden(true)
		-- stacksWindow:SetDrawTier(DT_HIGH)
	-- end
	
	local function Position(value)
		stacksWindow:ClearAnchors()
		if value == "UI" then
			stacksWindow:SetAnchor(TOPLEFT, GuiRoot, TOPLEFT, self.config.trackerX, self.config.trackerY)
		elseif value == "Sample" then
			stacksWindow:SetAnchor(RIGHT, GuiRoot, RIGHT, -GuiRoot:GetWidth()/8, GuiRoot:GetHeight()/6)
		end
	end
	
	local tracker = ZO_HUDFadeSceneFragment:New(stacksWindow) 
	local function FadeScenes(value)
		if value == "UI" then
			SCENE_MANAGER:GetScene("hud"):AddFragment(tracker)
			SCENE_MANAGER:GetScene("hudui"):AddFragment(tracker)
		elseif value == "NoUI" then
			SCENE_MANAGER:GetScene("hud"):RemoveFragment(tracker)
			SCENE_MANAGER:GetScene("hudui"):RemoveFragment(tracker)
		elseif value == "Sample" then
			SCENE_MANAGER:GetScene("gameMenuInGame"):AddFragment(tracker)
		elseif value == "NoSample" then
			SCENE_MANAGER:GetScene("gameMenuInGame"):RemoveFragment(tracker)
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
		
		local stackIndicator = WINDOW_MANAGER:CreateControl(self.name.."StackIndicator"..tostring(i), stacksWindow, CT_CONTROL)
	
		local icon = WINDOW_MANAGER:CreateControl(self.name.."StackIcon"..tostring(i), stackIndicator, CT_TEXTURE)
		icon:ClearAnchors() 
		icon:SetAnchor(TOPLEFT, stackIndicator, TOPLEFT, 0, 0) 
		icon:SetDesaturation(0.1)
	
		local frame = WINDOW_MANAGER:CreateControl(self.name.."StackFrame"..tostring(i), stackIndicator, CT_TEXTURE)
		frame:ClearAnchors()
		frame:SetAnchor(TOPLEFT, stackIndicator, TOPLEFT, 0, 0)
		-- frame:SetTexture("esoui/art/champion/actionbar/champion_bar_slot_frame_disabled.dds")
		frame:SetTexture("/esoui/art/actionbar/abilityframe64_up.dds")
	
		local highlight = WINDOW_MANAGER:CreateControl(self.name.."StackHighlight"..tostring(i), stackIndicator, CT_TEXTURE)
		highlight:ClearAnchors()
		highlight:SetAnchor(TOPLEFT, stackIndicator, TOPLEFT, 0, 0)
		highlight:SetDesaturation(0.4)
		highlight:SetTexture("/esoui/art/actionbar/actionslot_toggledon.dds")
		highlight:SetColor(unpack(attributes.highlight))
		
		local highlightAnimation = WINDOW_MANAGER:CreateControl(self.name.."StackHighlightAnimation"..tostring(i), stackIndicator, CT_TEXTURE)
		highlightAnimation:ClearAnchors()
		highlightAnimation:SetTexture("/esoui/art/actionbar/abilityhighlight_mage_med.dds")
		highlightAnimation:SetDrawTier(DT_HIGH)
		highlightAnimation:SetColor(unpack(attributes.highlightAnimation))
		
		local highlightAnimationTimeline = ANIMATION_MANAGER:CreateTimelineFromVirtual("StackReadyLoop", highlightAnimation)
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
	
	local function ApplyIcon()
		if self.class == "NB" then
			local value = self:CheckForGFMorph()
			attributes.graphic = attributes.icon[value]
		elseif self.class == "CRO" then
			local value = self:CheckForFSMorph()
			attributes.graphic = attributes.icon[value]
		end
		for i=1,attributes.iMax do
			indicator[i].controls.icon:SetTexture(attributes.graphic)
		end
	end
	indicator.ApplyIcon = ApplyIcon
	
	Position("UI")
	
	SCENE_MANAGER:RegisterCallback("SceneStateChanged", function(scene, newState)
		if scene:GetName() == "gameMenuInGame" and newState == "hiding" and self.showSampleTracker then
			self.showSampleTracker = false
			Position("UI")
			FadeScenes("NoSample")
		end
	end)

	return {
	stacksWindow = stacksWindow,
	indicator = indicator,
	FadeScenes = FadeScenes,
	Position = Position,
	}
end