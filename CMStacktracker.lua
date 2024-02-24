local Util = DariansUtilities
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
		-- highlightAnimation:ClearAnchors()
		highlightAnimation:SetAnchor(TOPLEFT, stackIndicator, TOPLEFT, 0, 0)
		highlightAnimation:SetAnchor(BOTTOMRIGHT, stackIndicator, BOTTOMRIGHT, 0, 0)
		-- highlightAnimation:SetBlendMode(TEX_BLEND_MODE_ADD)
		-- highlightAnimation:SetDesaturation(0.4)
		-- highlightAnimation:SetTexture("/esoui/art/actionbar/abilityhighlight_03.dds")
		highlightAnimation:SetTexture("/esoui/art/actionbar/abilityhighlight_mage_med.dds")
		highlightAnimation:SetDrawTier(DT_HIGH)
		-- highlightAnimation:SetColor(unpack(attributes.highlight))
		-- highlightAnimation:SetDuration(1000)
		
		local highlightAnimationTimeline = ANIMATION_MANAGER:CreateTimelineFromVirtual("UltimateReadyLoop", highlightAnimation)
		-- highlightAnimation:SetImageData(64, 64)
		-- highlightAnimation:SetFramerate(32)
		-- highlightAnimationTimeline:SetPlaybackType(ANIMATION_PLAYBACK_LOOP, LOOP_INDEFINITELY)
		highlightAnimationTimeline:PlayFromStart()
		highlightAnimation:SetHidden(false)
		-- d(highlightAnimation:GetNamedChild('FlipCard'))
		
		
		 -- anim = CreateSimpleAnimation(ANIMATION_TEXTURE, self.activationHighlight)
                -- anim:SetImageData(64, 1)
                -- anim:SetFramerate(30)
                -- anim:GetTimeline():SetPlaybackType(ANIMATION_PLAYBACK_LOOP, LOOP_INDEFINITELY)

	------------------------------
	---- Highlighting Handler ----
	------------------------------
		
		local function Activate()
			icon:SetColor(1,1,1,0.8)
			highlight:SetAlpha(0.8)
			-- highlightAnimation:SetAlpha(0.8)
			-- highlightAnimation:SetHidden(false)
			-- highlightAnimationTimeline:PlayFromStart()
			-- local highlightAnimationStarted = true
		end

		local function Deactivate()
			icon:SetColor(0.1,0.1,0.1,0.7)
			highlight:SetAlpha(0)
			-- highlightAnimation:SetAlpha(0)
			-- highlightAnimation:SetHidden(true)
			-- if highlightAnimationStarted then highlightAnimationTimeline:Stop() highlightAnimationStarted = false end
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
			-- indicator[i].controls.highlightAnimation:SetDimensions(size,size)			
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