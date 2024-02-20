	------------------------
	---- Check for load ----
	------------------------

function CombatMetronome:CheckIfStackTrackerShouldLoad()
	-- if CM_TRACKER_CLASS_ATTRIBUTES[self.class] then
		if self.class == "ARC" and self.config.trackCrux then
			CombatMetronome:InitializeTracker()
		elseif self.class == "DK" and self.config.trackMW then
			CombatMetronome:InitializeTracker()
		elseif self.class == "SOR" and self.config.trackBA then
			CombatMetronome:InitializeTracker()
		elseif self.class == "NB" and self.config.trackGF then
			CombatMetronome:InitializeTracker()
		end
	-- end
end

	---------------------
	---- Initializer ----
	---------------------
	
function CombatMetronome:InitializeTracker()

	self.stackTracker = CombatMetronome:BuildStackTracker()
	self.stackTracker.indicator.ApplySize(self.config.indicatorSize)
	self.stackTracker.indicator.ApplyDistance(self.config.indicatorSize/5, self.config.indicatorSize)
	
	EVENT_MANAGER:RegisterForUpdate(
		self.name.."UpdateStacks",
		1000 / 60,
		function(...) CombatMetronome:TrackerUpdate() end
	)
	
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
		stacksWindow:SetHidden(false)
		stacksWindow:SetDrawTier(DT_LOW)
		stacksWindow:SetDrawLayer(DL_CONTROLS)
	-- end
	
	-- local fragment = ZO_HUDFadeSceneFragment:New(stacksWindow) 
	-- local function DefineFragmentScenes(enabled)
		-- if enabled then 
			-- HUD_UI_SCENE:AddFragment( fragment )
			-- HUD_SCENE:AddFragment( fragment )
		-- else 
			-- HUD_UI_SCENE:RemoveFragment( fragment )
			-- HUD_SCENE:RemoveFragment( fragment )
		-- end
	-- end
	
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
			icon:SetAnchor(CENTER, stackIndicator, CENTER, 0, 0) 
			icon:SetDesaturation(0.1)
			icon:SetTexture(attributes.graphic)
			-- d(tostring("stackIcon "..i.." created"))
		-- end
		
		-- if not frame then
			local frame = WINDOW_MANAGER:CreateControl(self.name.."StackFrame"..tostring(i), stackIndicator, CT_TEXTURE)
			frame:ClearAnchors()
			frame:SetAnchor(CENTER, stackIndicator, CENTER, 0, 0)
			-- frame:SetTexture("esoui/art/champion/actionbar/champion_bar_slot_frame_disabled.dds")
			frame:SetTexture("/esoui/art/actionbar/abilityframe64_up.dds")
			-- d(tostring("stackFrame "..i.." created"))
		-- end
		
		-- if not highlight then
			local highlight = WINDOW_MANAGER:CreateControl(self.name.."StackHighlight"..tostring(i), stackIndicator, CT_TEXTURE)
			highlight:ClearAnchors()
			highlight:SetAnchor(CENTER, stackIndicator, CENTER, 0, 0)
			highlight:SetDesaturation(0.4)
			highlight:SetTexture("/esoui/art/actionbar/actionslot_toggledon.dds")
			highlight:SetColor(unpack(attributes.highlight))
		-- end
		
		-- local highlightAnimation = WINDOW_MANAGER:CreateControl(self.name.."StackHighlightAnimation"..tostring(i), stackIndicator, CT_TEXTURE)
		-- highlightAnimation:ClearAnchors()
		-- highlightAnimation:SetAnchor(CENTER, stackIndicator, CENTER, 0, 0)
		-- highlightAnimation:SetDesaturation(0.4)
		-- highlightAnimation:SetTexture("/esoui/art/actionbar/abilityhighlight_03.dds")
		-- highlightAnimation:SetTexture("/esoui/art/actionbar/abilityhighlightanimation_mage.dds")
		-- highlightAnimation:SetColor(unpack(attributes.highlight))
		-- highlightAnimationTimeline = ANIMATION_MANAGER:CreateTimelineFromVirtual(self.name.."StackHighlightAnimationTimeline", highlightAnimation)
		-- highlightAnimationTimeline:PlayFromStart()
		
	------------------------------
	---- Highlighting Handler ----
	------------------------------
		
		local function Activate()
			icon:SetColor(1,1,1,0.7)
			highlight:SetAlpha(0.8)    
		end

		local function Deactivate()
			icon:SetColor(0.1,0.1,0.1,0.7)
			highlight:SetAlpha(0)
		end

		local controls = {
		stackIndicator = stackIndicator,
		frame = frame,
		icon = icon,
		highlight = highlight,
		}
		return {
		stacksWindow = stacksWindow,
		controls = controls,
		Activate = Activate,
		Deactivate = Deactivate,
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
		end
	end
	indicator.ApplySize = ApplySize
	
	local function ApplyDistance(distance, size) 
		for i=1,attributes.iMax do
			local xOffset = (i-(attributes.iMax+1)/2)*(size+distance)
			indicator[i].controls.stackIndicator:ClearAnchors()
			indicator[i].controls.stackIndicator:SetAnchor( CENTER, stacksWindow, CENTER, xOffset, 0)
		end
	end
	indicator.ApplyDistance = ApplyDistance

	return {
	stacksWindow = stacksWindow,
	indicator = indicator,
	-- DefineFragmentScenes = DefineFragmentScenes,
	}
end

	-----------------
	---- Updater ----
	-----------------

function CombatMetronome:TrackerUpdate()
	local attributes = CM_TRACKER_CLASS_ATTRIBUTES[self.class]
	if self.class == "ARC" then
		stacks = self:GetCurrentNumCruxOnPlayer()
	elseif self.class == "DK" then
		stacks = self:GetCurrentNumMWOnPlayer()
	elseif self.class == "SOR" then
		stacks = self:GetCurrentNumBAOnPlayer()
	elseif self.class == "NB" then
		nbAttributes = self:GetCurrentNumGFOnPlayer()
		stacks = nbAttributes.maxStacks
		icon = nbAttributes.icon
		attributes.graphic = attributes.icon[icon]
	end
	for i=1,attributes.iMax do 
		self.stackTracker.indicator[i].Deactivate()
	end
	if stacks == 0 then return end
	for i=1,stacks do
		self.stackTracker.indicator[i].Activate()
	end
	previousStack = stacks
	if previousStack == (attributes.iMax-1) then
	end
end

