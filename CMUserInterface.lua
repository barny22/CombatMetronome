-- local LAM = LibAddonMenu2
local Util = DariansUtilities
local CM = CombatMetronome
CombatMetronome.SV = CombatMetronome.SV or {}

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
			self.frame = Util.Controls:NewFrame(self.name.."ProgressbarFrame", "Progressbar")
			self.frame:SetDimensionConstraints(MIN_WIDTH, MIN_HEIGHT, MAX_WIDTH, MAX_HEIGHT)
			self.frame:SetHandler("OnMoveStop", function(...)
				CombatMetronome.SV.Progressbar.xOffset = self.frame:GetLeft()
				CombatMetronome.SV.Progressbar.yOffset = self.frame:GetTop()
				self.progressbar.Anchors()
				-- self:BuildProgressBar()
			end)
			self.frame:SetHandler("OnResizeStop", function(...)
				CombatMetronome.SV.Progressbar.width = self.frame:GetWidth()
				CombatMetronome.SV.Progressbar.height = self.frame:GetHeight()
				self.progressbar.Size()
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

		-- self.labelFrame = self.labelFrame or Util.Controls:NewFrame(self.name.."LabelFrame")
		if not self.labelFrame then
			self.labelFrame = Util.Controls:NewFrame(self.name.."LabelFrame", "Resource Labels")
			self.labelFrame:SetDimensionConstraints(MIN_WIDTH, MIN_HEIGHT, MAX_WIDTH, MAX_HEIGHT)
			self.labelFrame:SetHandler("OnMoveStop", function(...)
				CombatMetronome.SV.Resources.xOffset = self.labelFrame:GetLeft()
				CombatMetronome.SV.Resources.yOffset = self.labelFrame:GetTop()
			end)
			self.labelFrame:SetHandler("OnResizeStop", function(...)
				CombatMetronome.SV.Resources.width = self.labelFrame:GetWidth()
				CombatMetronome.SV.Resources.height = self.labelFrame:GetHeight()
			end)
		end

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
			self.frame:SetAnchor(TOPLEFT, GuiRoot, TOPLEFT, CombatMetronome.SV.Progressbar.xOffset, CombatMetronome.SV.Progressbar.yOffset)
		elseif value == "Sample" then
			self.frame:SetAnchor(RIGHT, GuiRoot, RIGHT, -GuiRoot:GetWidth()/8, -GuiRoot:GetHeight()/6)
		end
	end
	
	local function ResourcesPosition(value)
		self.labelFrame:ClearAnchors()
		if value == "UI" and CombatMetronome.SV.Resources.anchorResourcesToProgressbar then
			self.labelFrame:SetAnchor(BOTTOM, self.frame, TOP, 0, 0)
		elseif value == "UI" and not CombatMetronome.SV.Resources.anchorResourcesToProgressbar then
			self.labelFrame:SetAnchor(TOPLEFT, GuiRoot, TOPLEFT, CombatMetronome.SV.Resources.xOffset, CombatMetronome.SV.Resources.yOffset)
		elseif value == "Sample" and not CombatMetronome.SV.Resources.anchorResourcesToProgressbar then
			self.labelFrame:SetAnchor(RIGHT, GuiRoot, RIGHT, -GuiRoot:GetWidth()/8, 0)
		elseif value == "Sample" and CombatMetronome.SV.Resources.anchorResourcesToProgressbar then
			self.labelFrame:SetAnchor(RIGHT, GuiRoot, RIGHT, -GuiRoot:GetWidth()/8, -GuiRoot:GetHeight()/6 - CombatMetronome.SV.Progressbar.height - CombatMetronome.SV.Resources.height/2)
		end
	end
	
	local function Fonts()
		self.hpLabel:SetFont(Util.Text.getFontString(tostring("$("..CombatMetronome.SV.Progressbar.labelFont..")"), CombatMetronome.SV.Resources.healthSize, CombatMetronome.SV.Progressbar.fontStyle))
		self.magLabel:SetFont(Util.Text.getFontString(tostring("$("..CombatMetronome.SV.Progressbar.labelFont..")"), CombatMetronome.SV.Resources.magSize, CombatMetronome.SV.Progressbar.fontStyle))
		self.stamLabel:SetFont(Util.Text.getFontString(tostring("$("..CombatMetronome.SV.Progressbar.labelFont..")"), CombatMetronome.SV.Resources.stamSize, CombatMetronome.SV.Progressbar.fontStyle))
		self.ultLabel:SetFont(Util.Text.getFontString(tostring("$("..CombatMetronome.SV.Progressbar.labelFont..")"), CombatMetronome.SV.Resources.ultSize, CombatMetronome.SV.Progressbar.fontStyle))
		self.timeLabel:SetFont(Util.Text.getFontString(tostring("$("..CombatMetronome.SV.Progressbar.labelFont..")"), CombatMetronome.SV.Progressbar.spellSize, CombatMetronome.SV.Progressbar.fontStyle))
		self.spellLabel:SetFont(Util.Text.getFontString(tostring("$("..CombatMetronome.SV.Progressbar.labelFont..")"), CombatMetronome.SV.Progressbar.spellSize, CombatMetronome.SV.Progressbar.fontStyle))
	end
	
	local function LabelColors()
		self.hpLabel:SetColor(unpack(CombatMetronome.SV.Resources.healthColor))
		self.magLabel:SetColor(unpack(CombatMetronome.SV.Resources.magColor))
		self.stamLabel:SetColor(unpack(CombatMetronome.SV.Resources.stamColor))
		self.ultLabel:SetColor(unpack(CombatMetronome.SV.Resources.ultColor))
	end
	
	local function HiddenStates()
		self.hpLabel:SetHidden(true)
		self.magLabel:SetHidden(true)
		self.stamLabel:SetHidden(true)
		self.ultLabel:SetHidden(true)
		self.timeLabel:SetHidden(true)
		self.spellLabel:SetHidden(true)
		self.bar.backgroundTexture:SetHidden(not CombatMetronome.SV.Progressbar.makeItFancy)
		self.bar.borderL:SetHidden(not CombatMetronome.SV.Progressbar.makeItFancy)
		self.bar.borderR:SetHidden(not CombatMetronome.SV.Progressbar.makeItFancy)
		self.spellIcon:SetHidden(true)
		self.spellIconBorder:SetHidden(true)
		self.bar:SetHidden(not CombatMetronome.SV.Progressbar.dontHide)
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
		if CombatMetronome.SV.Progressbar.barAlign == "Right" then
			self.timeLabel:SetAnchor(LEFT, self.frame, LEFT, (CombatMetronome.SV.Progressbar.height/5), 0)
			self.bar.backgroundTexture:SetAnchor(RIGHT, self.frame, RIGHT, 0, 0)
			self.spellIcon:SetAnchor(LEFT, self.frame, RIGHT, (CombatMetronome.SV.Progressbar.height/10), 0)
			self.bar.align = RIGHT
		elseif CombatMetronome.SV.Progressbar.barAlign == "Left" then
			self.bar.backgroundTexture:SetAnchor(LEFT, self.frame, LEFT, 0, 0)
			self.timeLabel:SetAnchor(RIGHT, self.frame, RIGHT, -(CombatMetronome.SV.Progressbar.height/5), 0) 
			self.spellIcon:SetAnchor(RIGHT, self.frame, LEFT, -(CombatMetronome.SV.Progressbar.height/10), 0)
			self.bar.align = LEFT
		else
			self.bar.backgroundTexture:SetAnchor(CENTER, self.frame, CENTER, 0, 0)
			self.timeLabel:SetAnchor(RIGHT, self.frame, RIGHT, -(CombatMetronome.SV.Progressbar.height/5), 0) 
			self.spellIcon:SetAnchor(RIGHT, self.frame, LEFT, -(CombatMetronome.SV.Progressbar.height/10), 0)
			self.bar.align = CENTER
		end
		
		-----------------------
		---- Label Anchors ----
		-----------------------
		
		self.hpLabel:ClearAnchors()
		if CombatMetronome.SV.Resources.reticleHp then
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
		if CombatMetronome.SV.Resources.anchorResourcesToProgressbar then
			self.labelFrame:SetAnchor(BOTTOM, self.frame, TOP, 0, 0)
		else
			self.labelFrame:SetAnchor(TOPLEFT, GuiRoot, TOPLEFT, CombatMetronome.SV.Resources.xOffset, CombatMetronome.SV.Resources.yOffset)
		end
	end
	
	local function Size()
		self.frame:SetDimensions(CombatMetronome.SV.Progressbar.width, CombatMetronome.SV.Progressbar.height)
		self.bar.background:SetDimensions(CombatMetronome.SV.Progressbar.width, CombatMetronome.SV.Progressbar.height)
		self.bar.borderR:SetDimensions(CombatMetronome.SV.Progressbar.width/2, CombatMetronome.SV.Progressbar.height)
		self.bar.borderL:SetDimensions(CombatMetronome.SV.Progressbar.width/2, CombatMetronome.SV.Progressbar.height)
		self.bar.backgroundTexture:SetDimensions(CombatMetronome.SV.Progressbar.width, CombatMetronome.SV.Progressbar.height)
		self.spellIconBorder:SetDimensions(CombatMetronome.SV.Progressbar.height, CombatMetronome.SV.Progressbar.height)
		self.spellIcon:SetDimensions(CombatMetronome.SV.Progressbar.height, CombatMetronome.SV.Progressbar.height)
		if CombatMetronome.SV.Resources.anchorResourcesToProgressbar then
			CombatMetronome.SV.Resources.width = CombatMetronome.SV.Progressbar.width
			CombatMetronome.SV.Resources.height = 50
		end
		self.labelFrame:SetDimensions(CombatMetronome.SV.Resources.width, CombatMetronome.SV.Resources.height)
		Anchors()
	end
	
	local function BarColors()
		self.bar.background:SetCenterColor(unpack(CombatMetronome.SV.Progressbar.backgroundColor))
		self.bar:UpdateSegment(1, {
			color = CombatMetronome.SV.Progressbar.pingColor,
		})
		self.bar:UpdateSegment(2, {
			color = CombatMetronome.SV.Progressbar.progressColor,
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
	
	SCENE_MANAGER:RegisterCallback("SceneStateChanged", function(scene, newState)
		if scene:GetName() == "gameMenuInGame" and newState == "hiding" and self.showSampleResources then
			self.showSampleResources = false
			ResourcesPosition("UI")
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
	ResourcesPosition("UI")
	
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
		ResourcesPosition = ResourcesPosition,
	}
		
end

	-----------------------------
	---- Build Stack Tracker ----
	-----------------------------

CombatMetronome.StackTracker = CombatMetronome.StackTracker or {}
local StackTracker = CombatMetronome.StackTracker

function StackTracker:BuildUI()
	local attributes = self.CLASS_ATTRIBUTES[self.class]
	local size = CombatMetronome.SV.StackTracker.indicatorSize
	local distance = size/5
	
	------------------------------
	---- Build TopLevelWindow ----
	------------------------------
	
	-- if not stacksWindow then
		-- local stacksWindow = Util.Controls:NewFrame(self.name.."StackTrackerWindow")
		local stacksWindow = WINDOW_MANAGER:CreateTopLevelWindow(self.name.."StackTrackerWindow")
		stacksWindow:SetHandler( "OnMoveStop", function(...)
			CombatMetronome.SV.StackTracker.xOffset = stacksWindow:GetLeft()
			CombatMetronome.SV.StackTracker.yOffset = stacksWindow:GetTop()
		end)
		stacksWindow:SetDimensions((size*attributes.iMax+distance*(attributes.iMax-1)), size)
		stacksWindow:SetMouseEnabled(true)
		stacksWindow:SetMovable(CombatMetronome.SV.StackTracker.isUnlocked)
		stacksWindow:SetClampedToScreen(true)
		stacksWindow:SetHidden(true)
		-- stacksWindow:SetDrawTier(DT_HIGH)
	-- end
	
	local function Position(value)
		stacksWindow:ClearAnchors()
		if value == "UI" then
			stacksWindow:SetAnchor(TOPLEFT, GuiRoot, TOPLEFT, CombatMetronome.SV.StackTracker.xOffset, CombatMetronome.SV.StackTracker.yOffset)
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
			local value = Util.Stacks:CheckForGFMorph()
			attributes.graphic = attributes.icon[value]
		elseif self.class == "CRO" then
			local value = Util.Stacks:CheckForFSMorph()
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

	------------------------------------
	---- Build Light Attack Tracker ----
	------------------------------------
CM.LATracker = CM.LATracker or {}
local LATracker = CombatMetronome.LATracker

function LATracker:BuildUI()
	if not LATracker.frame then
		LATracker.frame = Util.Controls:NewFrame(self.name.."Frame")
		LATracker.frame:SetDimensionConstraints(50, 10, 300, 50)
		LATracker.frame:SetHeight(CombatMetronome.SV.LATracker.height)
		LATracker.frame:SetWidth(CombatMetronome.SV.LATracker.width)
		LATracker.frame:SetAnchor(TOPLEFT, GuiRoot, TOPLEFT, CombatMetronome.SV.LATracker.xOffset, CombatMetronome.SV.LATracker.yOffset)
	end
	
	LATracker.label = LATracker.label or WINDOW_MANAGER:CreateControl(self.name.."Label", LATracker.frame, CT_LABEL)
	LATracker.label:SetText("")
	LATracker.label:ClearAnchors()
	LATracker.label:SetAnchor(CENTER, LATracker.frame, CENTER, 0, 0)
	
	local function LabelSettings()
		LATracker.label:SetFont(Util.Text.getFontString(tostring("$("..CombatMetronome.SV.Progressbar.labelFont..")"), LATracker.frame:GetHeight(), CombatMetronome.SV.Progressbar.fontStyle))
	end
	
	LATracker.frame:SetHandler("OnMoveStop", function(...)
		CombatMetronome.SV.LATracker.xOffset = LATracker.frame:GetLeft()
		CombatMetronome.SV.LATracker.yOffset = LATracker.frame:GetTop()
	end)
	LATracker.frame:SetHandler("OnResizeStop", function(...)
		CombatMetronome.SV.LATracker.width = LATracker.frame:GetWidth()
		CombatMetronome.SV.LATracker.height = LATracker.frame:GetHeight()
		LATracker.label:SetFont(Util.Text.getFontString(tostring("$("..CombatMetronome.SV.Progressbar.labelFont..")"), math.min(LATracker.frame:GetHeight(), LATracker.frane:GetWidth()/5), CombatMetronome.SV.Progressbar.fontStyle))
	end)
	
	LabelSettings()
	
	return {
		LabelSettings = LabelSettings,
	}
end

	--------------------------
	---- Build CC Tracker ----
	--------------------------
CM.CCTracker = CM.CCTracker or {}
local CCTracker = CM.CCTracker

function CCTracker:BuildUI()
	
	local indicator = {}
	
	local function GetIndicator(name, iconPath)
		
		local tlw = Util.Controls:NewFrame(self.name..name.."Frame", name)
		tlw:SetDimensionConstraints(10, 10, 200, 200)
		tlw:SetHeight(CombatMetronome.SV.CCTracker.size)
		tlw:SetWidth(CombatMetronome.SV.CCTracker.size)
		tlw:SetAnchor(TOPLEFT, GuiRoot, TOPLEFT, CombatMetronome.SV.CCTracker.xOffset[name], CombatMetronome.SV.CCTracker.yOffset[name])
		tlw:SetDrawTier(DT_HIGH)
		tlw:SetHandler("OnMoveStop", function(...)
			CombatMetronome.SV.CCTracker.xOffset[name] = tlw:GetLeft()
			CombatMetronome.SV.CCTracker.yOffset[name] = tlw:GetTop()
		end)
		tlw:SetHandler("OnResizeStop", function(...)
			if tlw:GetHeight() == CombatMetronome.SV.CCTracker.size and tlw:GetWidth() ~= CombatMetronome.SV.CCTracker.size then
				CombatMetronome.SV.CCTracker.size = tlw:GetWidth()
				CCTracker.UI.indicator.ApplySize(CombatMetronome.SV.CCTracker.size)
			elseif tlw:GetHeight() ~= CombatMetronome.SV.CCTracker.size and tlw:GetWidth() == CombatMetronome.SV.CCTracker.size then
				CombatMetronome.SV.CCTracker.size = tlw:GetHeight()
				CCTracker.UI.indicator.ApplySize(CombatMetronome.SV.CCTracker.size)
			elseif tlw:GetHeight() ~= CombatMetronome.SV.CCTracker.size and tlw:GetWidth() ~= CombatMetronome.SV.CCTracker.size then
				CombatMetronome.SV.CCTracker.size = tlw:GetHeight()
				CCTracker.UI.indicator.ApplySize(CombatMetronome.SV.CCTracker.size)
			end
		end)
		
		local icon = WINDOW_MANAGER:CreateControl(self.name.."CCIcon"..name, tlw, CT_TEXTURE)
		icon:ClearAnchors()
		icon:SetAnchorFill()
		icon:SetTexture(iconPath)
		icon:SetHidden(true)
		
		local frame = WINDOW_MANAGER:CreateControl(self.name.."CCFrame"..name, tlw, CT_TEXTURE)
		frame:ClearAnchors()
		frame:SetAnchorFill()
		frame:SetTexture("/esoui/art/actionbar/abilityframe64_up.dds")
		frame:SetHidden(true)
		
		local controls = {
		tlw = tlw,
		frame = frame,
		icon = icon,
		}
		return {
		controls = controls,
		}
	end
	
	for _, entry in pairs(self.variables) do
		indicator[entry.name] = GetIndicator(entry.name, entry.icon)
	end
	-- for i=1,10 do
		-- indicator[i] = GetIndicator(i)
	-- end
	
	local function SetUnlocked(value)
		for _, entry in pairs(self.variables) do
			if entry.tracked then
				if value then
					indicator[entry.name].controls.tlw:SetDrawTier(DT_HIGH)
					indicator[entry.name].controls.tlw:SetHidden(false)
					indicator[entry.name].controls.icon:SetHidden(false)
				else
					indicator[entry.name].controls.tlw:SetDrawTier(DT_Low)
					indicator[entry.name].controls.tlw:SetHidden(true)
					indicator[entry.name].controls.icon:SetHidden(true)
				end
				indicator[entry.name].controls.tlw:SetUnlocked(value)
			end
		end
	end
	indicator.SetUnlocked = SetUnlocked
	
	local function ApplySize(size)
		for _, entry in pairs(self.variables) do 
			indicator[entry.name].controls.tlw:SetDimensions(size, size)
			indicator[entry.name].controls.frame:SetDimensions(size, size)
			indicator[entry.name].controls.icon:SetDimensions(size, size)
			indicator[entry.name].controls.tlw.dmui.label:SetFont(Util.Text.getFontString(tostring("$MEDIUM_FONT"), CombatMetronome.SV.CCTracker.size/5, "outline"))
		end
		-- for i=1,10 do 
			-- indicator[i].controls.frame:SetDimensions(size,size)
			-- indicator[i].controls.icon:SetDimensions(size,size)
		-- end
		-- CCTracker.frame:SetHeight(CombatMetronome.SV.CCTrackerSize*2+1)
		-- CCTracker.frame:SetWidth(CombatMetronome.SV.CCTrackerSize*5+4)
		
	end
	indicator.ApplySize = ApplySize
	
	-- local function ApplyDistance(size) 
		-- for i=1,5 do
			-- local xOffset = (i-1)*(size+1)
			-- indicator[i].controls.ccIndicator:ClearAnchors()
			-- indicator[i].controls.ccIndicator:SetAnchor(TOPLEFT, CCTracker.frame, TOPLEFT, xOffset, 0)
		-- end
		-- for i=6,10 do
			-- local xOffset = (i-6)*(size+1)
			-- indicator[i].controls.ccIndicator:ClearAnchors()
			-- indicator[i].controls.ccIndicator:SetAnchor(TOPLEFT, CCTracker.frame, TOPLEFT, xOffset, size+1)
		-- end
	-- end
	-- indicator.ApplyDistance = ApplyDistance
	
	return {
	indicator = indicator,
	}
end