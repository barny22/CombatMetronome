-- local Util = DAL:Ext("DariansUtilities")
local Util = DariansUtilities
Util.Controls = { }
Controls = Util.Controls

local log = Util.log

function Controls:New(t, name, parent, layer)
	local control = WINDOW_MANAGER:CreateControl(name, parent or GuiRoot, t)
	control:SetDrawLayer(DL_OVERLAY)
    control:SetDrawLevel(layer or 1)

	if (t == CT_BACKDROP) then	
		InitBackdrop(control)
	elseif (t == CT_TOPLEVELCONTROL) then
		InitFrame(control)
	end

	return control
end

--------------
-- Backdrop --
--------------

function InitBackdrop(backdrop)
	backdrop:SetEdgeColor(0, 0, 0, 0)
	backdrop:SetEdgeTexture(nil, 1, 1, 0, 0)
end

--------------------
-- Frame specific --
--------------------

local function SetUnlocked(frame, state)
	frame:SetMouseEnabled(state)
	frame:SetMovable(state)
	frame.dmui.unlocked = state

	if (state or not frame.dmui.hudOnly) then
		SCENE_MANAGER:GetScene("hud"):RemoveFragment(frame.dmui.fragment)
		SCENE_MANAGER:GetScene("hudui"):RemoveFragment(frame.dmui.fragment)
		frame:SetHidden(false)
	else
		SCENE_MANAGER:GetScene("hud"):AddFragment(frame.dmui.fragment)
		SCENE_MANAGER:GetScene("hudui"):AddFragment(frame.dmui.fragment)
	end

	frame.dmui.shadow:SetHidden(not state)
end

local function InitFrame(frame)
	local dmui = { }

	frame.dmui = dmui

	local name = frame:GetName()

	-- Clamp to screen by default
	frame:SetClampedToScreen(true)

	-- Add constraint management
	dmui.constrain = true
	local SetDimensions = frame.SetDimensions
	frame.SetDimensions = function(self, width, height)
	    if dmui.constrain then
	    	self:SetDimensionConstraints(width, height, width, height)
	    end
	    SetDimensions(self, width, height)
	end
	local SetDimensionConstraints = frame.SetDimensionConstraints
	frame.SetDimensionConstraints = function(...)
		dmui.constrain = false
		SetDimensionConstraints(...)
	end

    -- Add resizer
	frame:SetResizeHandleSize(5)
	dmui.shadow = Controls:New(CT_BACKDROP, name.."Resizer", frame)
	dmui.shadow:SetAnchorFill()
	dmui.shadow:SetCenterColor(0.5, 0.5, 0.5, 0.75)
	frame.SetUnlocked = SetUnlocked
	frame.IsUnlocked = function()
		return dmui.unlocked
	end

	-- Add HUD visibility management
	dmui.unlocked = false
	dmui.hudOnly = true
	dmui.fragment = ZO_HUDFadeSceneFragment:New(frame)

	frame:SetUnlocked(false)

	-- return tools
end

function Controls:NewFrame(name)
	local frame = WINDOW_MANAGER:CreateTopLevelWindow(name)

	InitFrame(frame)

	return frame
end