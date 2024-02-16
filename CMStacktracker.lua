function CombatMetronome:CheckIfStackTrackerShouldLoad()
	if CM_TRACKER_CLASS_ATTRIBUTES[self.class] then
		if self.class == "ARC" and self.config.trackCrux then
			self:BuildStackTracker()
		elseif self.class == "DK" and self.config.trackMW then
			self:BuildStackTracker()
		elseif self.class == "SORC" and self.config.trackBA then
			self:BuildStackTracker()
		elseif self.class == "NB" and self.config.trackGF then
			self:BuildStackTracker()
		end
	end
end

function CombatMetronome:BuildStackTracker()
	local attributes = CM_TRACKER_CLASS_ATTRIBUTES[self.class]
	
	stackTracker = stackTracker or WINDOW_MANAGER:CreateTopLevelWindow(self.name.."StackTrackerWindow")
	stackTracker:SetHandler( "OnMoveStop", function(...)
		self.config.trackerX = stackTracker:GetLeft()
		self.config.trackerY = stackTracker:GetTop()
		self:BuildStackTracker()
	end)
	stackTracker:SetDimensions( 50, 50)
	stackTracker:ClearAnchors()
	stackTracker:SetAnchor(TOPLEFT, GuiRoot, TOPLEFT, self.config.trackerX, self.config.trackerY)
	stackTracker:SetMouseEnabled(true)
	stackTracker:SetMovable(true)
	stackTracker:SetClampedToScreen(true)
	stackTracker:SetHidden(true)

	-- local frag = ZO_HUDFadeSceneFragment:New(self.stackTracker) 
	-- local function DefineFragmentScenes(enabled)
		-- if enabled then 
			-- HUD_UI_SCENE:AddFragment( frag )
			-- HUD_SCENE:AddFragment( frag )
		-- else 
			-- HUD_UI_SCENE:RemoveFragment( frag )
			-- HUD_SCENE:RemoveFragment( frag )
		-- end
	-- end

	local indicator = {}

	local function GetIndicator(i) 

		local stackIndicator = WINDOW_MANAGER:CreateControl(self.name.."StackIndicator"..tostring(i), stackTracker, CT_CONTROL)

		local background  = WINDOW_MANAGER:CreateControl(self.name.."StackBackground"..tostring(i), stackIndicator, CT_TEXTURE)
		background:ClearAnchors()
		background:SetAnchor(CENTER, stackIndicator, CENTER, 0, 0)
		background:SetAlpha(0.8)
		background:SetTexture("esoui/art/champion/champion_center_bg.dds")

		local frame = WINDOW_MANAGER:CreateControl(self.name.."StackFrame"..tostring(i), stackIndicator, CT_TEXTURE)
		frame:ClearAnchors()
		frame:SetAnchor(CENTER, stackIndicator, CENTER, 0, 0)
		frame:SetTexture("esoui/art/champion/actionbar/champion_bar_slot_frame_disabled.dds")

		local icon = WINDOW_MANAGER:CreateControl(self.name.."StackIcon"..tostring(i), stackIndicator, CT_TEXTURE)
		icon:ClearAnchors() 
		icon:SetAnchor(CENTER, stackIndicator, CENTER, 0, 0) 
		icon:SetDesaturation(0.1)
		icon:SetTexture(attributes.graphic)

		local highlight = WINDOW_MANAGER:CreateControl(self.name.."StackHighlight"..tostring(i), stackIndicator, CT_TEXTURE)
		highlight:ClearAnchors()
		highlight:SetAnchor(CENTER, stackIndicator, CENTER, 0, 0)
		highlight:SetDesaturation(0.4)
		highlight:SetTexture(attributes.highlight)
		highlight:SetColor(unpack(attributes.color))

		local function Activate()
			icon:SetColor(unpack(attributes.color))
			highlight:SetAlpha(0.8)    
		end

		local function Deactivate()
			icon:SetColor(1,1,1,0.2)
			highlight:SetAlpha(0)
		end

		local controls = {
		stackIndicator = stackIndicator,
		background = background,
		frame = frame,
		icon = icon,
		highlight = highlight,
		}
		return {
		stackTracker = stackTracker,
		controls = controls,
		Activate = Activate,
		Deactivate = Deactivate,
		}
	end

	for i =1,attributes.iMax do 
		indicator[i] = GetIndicator(i)
	end 

	local size = self.config.trackerSize
	local function ApplySize(size) 
		for i=1,attributes.iMax do 
			indicator[i].controls.background:SetDimensions(size*0.85,size*0.85)
			indicator[i].controls.frame:SetDimensions(size,size)
			indicator[i].controls.highlight:SetDimensions(size,size)
			indicator[i].controls.icon:SetDimensions(size*0.75,size*0.75)   
		end
	end
	indicator.ApplySize = ApplySize
	
	local distance = size/5
	local function ApplyDistance(distance, size) 
		for i=1,attributes.iMax do
			local xOffset = (i-2)*(size+distance)
			indicator[i].controls.stackIndicator:ClearAnchors()
			indicator[i].controls.stackIndicator:SetAnchor( CENTER, self.stackTracker, CENTER, xOffset, 0)
		end
	end
	indicator.ApplyDistance = ApplyDistance

	return {
	stackTracker = stackTracker,
	indicator = indicator,
	-- DefineFragmentScenes = DefineFragmentScenes,
	}
end
	
self.stacktracker = CombatMetronome:BuildStackTracker()

function CombatMetronome:TrackerUpdate()
	local attributes = CM_TRACKER_CLASS_ATTRIBUTES[self.class]
	if self.class == "ARC" then
		stacks = self:GetCurrentNumCruxOnPlayer()
	elseif self.class == "DK" then
		stacks = self:GetCurrentNumMWOnPlayer()
	elseif self.class == "SOR" then
		stacks = self:GetCurrentNumBAOnPlayer()
	elseif self.class == "ARC" then
		stacks = self:GetCurrentNumGFOnPlayer()
	end
	for i=1,attributes.iMax do 
		self.stacktracker.indicator[i].Deactivate()
	end
	if stacks == 0 then return end
	for i=1,stacks do
		self.stacktracker.indicator[i].Activate()
	end
end