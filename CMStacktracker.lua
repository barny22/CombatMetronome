function CombatMetronome:BuildStacktracker() 
  local name = idECT.."GraphicTracker"

  local win = WM:CreateTopLevelWindow( name.."Window" )
  win:ClearAnchors() 
  win:SetAnchor(TOPLEFT, GuiRoot, TOPLEFT, SV.graphical.x, SV.graphical.y)
  win:SetMouseEnabled(true) 
  win:SetMovable(true)
  win:SetClampedToScreen(true) 
  win:SetDimensions( 50,50 )
  win:SetHidden(true)
  win:SetHandler( "OnMoveStop", function() 
    SV.graphical.x = win:GetLeft() 
    SV.graphical.y = win:GetTop()
  end)

  local frag = ZO_HUDFadeSceneFragment:New( win ) 
  local function DefineFragmentScenes(enabled)
    if enabled then 
      HUD_UI_SCENE:AddFragment( frag )
      HUD_SCENE:AddFragment( frag )
    else 
      HUD_UI_SCENE:RemoveFragment( frag )
      HUD_SCENE:RemoveFragment( frag )
    end
  end

  local indicator = {}

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
    icon:SetTexture("/art/fx/texture/arcanist_trianglerune_01.dds")

    local highlight  = WM:CreateControl(name.."Highlight"..tostring(i), ind, CT_TEXTURE )
    highlight:ClearAnchors()
    highlight:SetAnchor( CENTER, ind, CENTER, 0, 0)
    highlight:SetDesaturation(0.4)
    highlight:SetTexture( "esoui/art/champion/actionbar/champion_bar_world_selection.dds")
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

  for i =1,3 do 
    indicator[i] = GetIndicator(i)
  end 

  local function ApplySize(size) 
    for i=1,3 do 
      indicator[i].controls.back:SetDimensions(size*0.85,size*0.85)
      indicator[i].controls.frame:SetDimensions(size,size)
      indicator[i].controls.highlight:SetDimensions(size,size)
      indicator[i].controls.icon:SetDimensions(size*0.75,size*0.75)   
    end
  end
  indicator.ApplySize = ApplySize

  local function ApplyDistance(distance, size) 
    for i=1,3 do 
      local xOffset = (i-2)*(size+distance)
      indicator[i].controls.ind:ClearAnchors()
      indicator[i].controls.ind:SetAnchor( CENTER, win, CENTER, xOffset, 0)
    end
  end
  indicator.ApplyDistance = ApplyDistance

  return {win = win, indicator = indicator, DefineFragmentScenes = DefineFragmentScenes}
end