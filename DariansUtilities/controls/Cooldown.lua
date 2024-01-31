-- local Util = DAL:Ext("DariansUtilities")
local Util = DariansUtilities
Util.Cooldown = { }

local Cooldown = Util.Cooldown

local DMUICooldownCount = 0

function Cooldown:New(name)
	o = { }
	setmetatable(o, self)
	self.__index = self

	DMUICooldownCount = DMUICooldownCount + 1
	o.index = DMUICooldownCount
	o.id = (name or "Util.Cooldown").."["..o.index.."]"

	o.cooldownColour = { 0, 1, 0, 1 }
	o.backgroundColour = { 0, 0, 0, 0.5 }
	o.iconTexture = nil

	o.frame = GuiRoot
	o.xOffset = 0
	o.yOffset = 0

	o.size = 60
	o.edge = 6

	o.anchor = nil
	o.anchorSelf = TOPLEFT
	o.anchorTarget = TOPLEFT

	o.remaining = 0
	o.duration = 0
	o.start = 0
	o.stacks = nil
	o.hasStacks = false

	o.empty = false
	o.clockwise = true
	o.rotate = 0

	o.hidden = false

	o.name = nil
	o.namePosition = LEFT

	return o
end

-- function Cooldown:SetRotation(offset)
-- 	if offset == 1 then
-- 		self.swap = false
-- 		self.switch = true
-- 	elseif offset == 2 then
-- 		self.swap = true
-- 		self.switch = false
-- 	elseif offset == 2 then
-- 		self.switch = true
-- 		self.swap = true
-- 	end
-- end

function Cooldown:Build()
	local iconSize = self.size - (2 * self.edge)
	-- local iconSize = self.size

	self.background = self.background or WINDOW_MANAGER:CreateControl(self.id.."Background", self.frame, CT_BACKDROP)
	self.background:SetDrawLayer(DL_OVERLAY)
	self.background:SetDrawLevel(0)
	self.background:ClearAnchors()
	self.background:SetAnchor(self.anchorSelf, self.anchor or self.frame, self.anchorTarget, self.xOffset, self.yOffset)
	self.background:SetEdgeColor(0, 0, 0, 0)
	self.background:SetEdgeTexture(nil, 1, 1, 0, 0)
	self.background:SetDimensions(self.size, self.size)
	self.background:SetCenterColor(unpack(self.backgroundColour))

	self.icon = self.icon or WINDOW_MANAGER:CreateControl(self.id.."Icon", self.background, CT_BACKDROP)
	self.icon:SetDrawLayer(DL_OVERLAY)
	self.icon:SetDrawLevel(2)
	self.icon:ClearAnchors()
	self.icon:SetAnchor(CENTER)
	self.icon:SetDimensions(iconSize, iconSize)
	self.icon:SetCenterTexture(self.iconTexture)
	self.icon:SetEdgeColor(0, 0, 0, 0)
	self.icon:SetEdgeTexture(nil, 1, 1, 0, 0)
	self.icon:SetHidden(false)

	-- self.sweep = self.sweep or WINDOW_MANAGER:CreateControl(self.id.."Sweep", self.background, CT_COOLDOWN)
	-- self.sweep:SetDrawLayer(DL_OVERLAY)
	-- self.sweep:SetDrawLevel(2)
	-- self.sweep:ClearAnchors()
	-- self.sweep:SetAnchorFill()
	-- -- self.sweep:SetFillColor(unpack(self.cooldownColour))
	-- self.sweep:SetFillColor(0, 0, 0, 0.8)
	-- self.sweep:SetRadialCooldownClockwise(true)
	-- self.sweep:SetHidden(true)

	-- self.sweep = self.sweep or Util.Bar:New(self.id.."Sweep", self.background)
	-- self.sweep.background:SetCenterColor(0, 0, 0, 0)
	-- self.sweep.background:SetDrawLayer(2)
	-- self.sweep.background:ClearAnchors()
	-- self.sweep.background:SetAnchorFill()
	-- self.sweep.align = LEFT
	-- self.sweep:UpdateSegment(1, {
	-- 	colour = { 1, 0, 0, 1 },
	-- 	progress = 1,
	-- })

	self.segments = self.segments or { }
	for i = 1, 4 do 
		self.segments[i] = self.segments[i] or Util.Controls:New(CT_BACKDROP, self.id.."Sweep"..i, self.background, 1)
		self.segments[i]:ClearAnchors()
		self.segments[i]:SetDimensions(self.size / 2, self.size / 2)
		self.segments[i]:SetCenterColor(0, 1, 0, 0.75)
	end

	local clockwise =     {{ BOTTOMRIGHT, RIGHT }, { BOTTOMLEFT,  BOTTOM }, { TOPLEFT,  LEFT  }, { TOPRIGHT, TOP }}
	local anticlockwise = {{ BOTTOMLEFT,  LEFT  }, { BOTTOMRIGHT, BOTTOM }, { TOPRIGHT, RIGHT }, { TOPLEFT,  TOP }}
	for i = 1, 4 do
		if self.clockwise then self.segments[i]:SetAnchor(    clockwise[i][1], self.background,     clockwise[i][2])
		else                   self.segments[i]:SetAnchor(anticlockwise[i][1], self.background, anticlockwise[i][2]) end
	end

	-- if self.clockwise then
	-- 	self.segments[1]:SetAnchor(BOTTOMRIGHT, self.background, RIGHT)
	-- 	self.segments[2]:SetAnchor(BOTTOMLEFT, self.background, BOTTOM)
	-- 	self.segments[3]:SetAnchor(TOPLEFT, self.background, LEFT)
	-- 	self.segments[4]:SetAnchor(TOPRIGHT, self.background, TOP)
	-- else
	-- 	self.segments[4]:SetAnchor(TOPLEFT, self.background, TOP)
	-- 	self.segments[3]:SetAnchor(TOPRIGHT, self.background, RIGHT)
	-- 	self.segments[2]:SetAnchor(BOTTOMRIGHT, self.background, BOTTOM)
	-- 	self.segments[1]:SetAnchor(BOTTOMLEFT, self.background, LEFT)
	-- end

	self.cdLabel = self.cdLabel or WINDOW_MANAGER:CreateControl(self.id.."CDLabel", self.background, CT_LABEL)
	self.cdLabel:SetDrawLayer(DL_OVERLAY)
	self.cdLabel:SetDrawLevel(3)
    self.cdLabel:ClearAnchors()
    self.cdLabel:SetAnchor(BOTTOM, self.background, BOTTOM, 0, 0)
    self.cdLabel:SetColor(1, 1, 1, 1)
    self.cdLabel:SetFont(Util.Text.getFontString(nil, iconSize / 3, "thick-outline"))
    self.cdLabel:SetHidden(false)
    self.cdLabel:SetText("")

    self.stackLabel = self.stackLabel or WINDOW_MANAGER:CreateControl(self.id.."StackLabel", self.background, CT_LABEL)
	self.stackLabel:SetDrawLayer(DL_OVERLAY)
	self.stackLabel:SetDrawLevel(3)
    self.stackLabel:ClearAnchors()
    self.stackLabel:SetAnchor(TOP, self.background, TOP, 0, 0)
    self.stackLabel:SetColor(1, 1, 1, 1)
    self.stackLabel:SetFont(Util.Text.getFontString(nil, iconSize / 2, "thick-outline"))
    self.stackLabel:SetHidden(false)
    self.stackLabel:SetText("")

    self.background:SetHidden(true)

	EVENT_MANAGER:RegisterForUpdate(self.id.."UpdateText", 1000 / 30, function(...) self:Update() end)
end

function Cooldown:Update()
	if self.remaining <= 0 then return end

	self.remaining = (self.duration - GetFrameTimeMilliseconds() + self.start)

	if self.remaining <= 0 then 
		self.remaining = 0
		self.background:SetHidden(true)
		return
	end

	local w = self.size / 2
	local r = self.remaining / self.duration

	local function bound(x, l, u, l2, u2)
		if x <= l then return l2 end
		if x >= u then return u2 end
		return l2 + ((u2 - l2) * (x - l) / (u - l))
	end

	local e = self.edge
	local edge = e / w
	local s2 = 0.25 / (2 - edge)

	for i = 0, 3 do
		local s = ((i + self.rotate) % 4) + 1
		local m = 0.25 * (3 - i)
		local inner = bound(r, m + s2, m + 0.25, e, w)
		local outer = bound(r, m,      m + s2,   0, w)
		local seg = self.segments[s]
		if s % 2 == 0 then seg:SetDimensions(outer, inner)
		else               seg:SetDimensions(inner, outer) end
	end

	local remSeconds = self.remaining / 1000

	if (remSeconds > 0) then
		local text = string.format(remSeconds < 5 and "%.1f" or "%i", remSeconds)
		self.cdLabel:SetText(text)
	end

	self.stackLabel:SetText((not self.stacks or self.stacks == 0) and "" or self.stacks)
end

function Cooldown:SetHidden(state)
	self.hidden = state
	self.background:SetHidden(state)
end

function Cooldown:UpdateCooldown(duration, remaining)
	self.remaining = remaining or duration
	self.duration = duration
	self.start = GetFrameTimeMilliseconds() - self.duration + self.remaining

	self.background:SetHidden(self.remaining <= 0 or self.hidden)
end