local attributes = CM_TRACKER_CLASS_ATTRIBUTES

function CombatMetronome:CheckIfStackerShouldLoad()
end

function CombatMetronome:BuildStacktracker()
	local iMax = 0
	local classId = GetUnitClassId("player")

	self.stacktracker = self.stacktracker or WINDOW_MANAGER:CreateTopLevelWindow(self.name.."stacktrackerWindow")
	self.stacktracker:SetHandler( "OnMoveStop", function(...)
		self.config.trackerX = self.stacktracker:GetLeft()
		self.config.trackerY = self.stacktracker:GetTop()
		self:BuildStacktracker()
	end)
	self.stacktracker:SetDimensions( 50,50 )
	self.stacktracker:ClearAnchors()
	self.stacktracker:SetAnchor(TOPLEFT, GuiRoot, TOPLEFT, self.config.trackerX, self.config.trackerY)
	self.stacktracker:SetMouseEnabled(true)
	self.stacktracker:SetMovable(true)
	self.stacktracker:SetClampedToScreen(true)
	self.stacktracker:SetHidden(true)

	--local frag = ZO_HUDFadeSceneFragment:New( win ) 
	--local function DefineFragmentScenes(enabled)
	--if enabled then 
		--HUD_UI_SCENE:AddFragment( frag )
		--HUD_SCENE:AddFragment( frag )
	-- else 
		--HUD_UI_SCENE:RemoveFragment( frag )
		--HUD_SCENE:RemoveFragment( frag )
	--end
	--end

	local stackIndicator = {}

	local function GetIndicator(i) 

	local ind = WM:CreateControl(name.."Indicator"..tostring(i), win, CT_CONTROL)

	local back  = WM:CreateControl(name.."Back"..tostring(i), ind, CT_TEXTURE )
	back:ClearAnchors()
	back:SetAnchor( CENTER, ind, CENTER, 0, 0)
	back:SetAlpha(0.8)
	back:SetTexture( "esoui/art/champion/champion_center_bg.dds")

	local frame = WM:CreateControl(name.."Frame"..tostring(i), ind, CT_TEXTURE )
	frame:ClearAnchors()
	frame:SetAnchor( CENTER, ind, CENTER, 0, 0)
	frame:SetTexture( "esoui/art/champion/actionbar/champion_bar_slot_frame_disabled.dds")

	local icon = WM:CreateControl( name.."Icon"..tostring(i), ind, CT_TEXTURE )
	icon:ClearAnchors() 
	icon:SetAnchor( CENTER, ind, CENTER, 0, 0 ) 
	icon:SetDesaturation(0.1)
	icon:SetTexture("/art/fx/texture/arcanist_trianglerune_01.dds")  -- /esoui/art/icons/guildfinderheraldry/crest_weapon_bow.dds /esoui/art/progression/icon_bows.dds  /esoui/art/icons/quest_u32_q6698_instructors_whip.dds

	local highlight  = WM:CreateControl(name.."Highlight"..tostring(i), ind, CT_TEXTURE )
	highlight:ClearAnchors()
	highlight:SetAnchor( CENTER, ind, CENTER, 0, 0)
	highlight:SetDesaturation(0.4)
	highlight:SetTexture( "esoui/art/champion/actionbar/champion_bar_world_selection.dds") --/esoui/art/champion/actionbar/champion_bar_combat_selection.dds blue /esoui/art/champion/actionbar/champion_bar_conditioning_selection.dds red
	highlight:SetColor(0,1,0)

	local function Activate()
		icon:SetColor(0,1,0,1)
		highlight:SetAlpha(0.8)    
	end

	local function Deactivate()
		icon:SetColor(1,1,1,0.2)
		highlight:SetAlpha(0)
	end

	local controls = {ind = ind, back = back, frame = frame, icon = icon, highlight = highlight}
	return {win = win, controls = controls, Activate = Activate, Deactivate = Deactivate}
	end

	for i =1,iMax do 
		indicator[i] = GetIndicator(i)
	end 

	local function ApplySize(size) 
		for i=1,iMax do 
			indicator[i].controls.back:SetDimensions(size*0.85,size*0.85)
			indicator[i].controls.frame:SetDimensions(size,size)
			indicator[i].controls.highlight:SetDimensions(size,size)
			indicator[i].controls.icon:SetDimensions(size*0.75,size*0.75)   
		end
	end
	indicator.ApplySize = ApplySize

	local function ApplyDistance(distance, size) 
		for i=1,iMax do 
			local xOffset = (i-2)*(size+distance)
			indicator[i].controls.ind:ClearAnchors()
			indicator[i].controls.ind:SetAnchor( CENTER, win, CENTER, xOffset, 0)
		end
	end
	indicator.ApplyDistance = ApplyDistance

	return {win = win, indicator = indicator, DefineFragmentScenes = DefineFragmentScenes}
end