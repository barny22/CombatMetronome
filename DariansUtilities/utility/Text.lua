-- local Util = DAL:Ext("DariansUtilities")
local Util = DariansUtilities
Util.Text = Util.Text or { }

-- local LMP = LibStub:GetLibrary("LibMediaProvider-1.0")
-- LMP:Register("font", "ZoFontGame", "EsoUI/Common/Fonts/Univers57.otf")

local log = Util.log

function Util.Text.getFontString(family, size, style)
	family = family or "EsoUI/Common/Fonts/Univers57.otf"
	size = size or 10
    style = style or "outline"
    return string.format("%s|%u|%s", family, size, style)
end

function Util.Text.formatNumberCompact(value)
	-- log("Formatting ", value)

	if value > 100000 then
		-- log(" over 100,000 -> ", string.format("%.1fM", value / 1000000))
		return string.format("%.1fM", value / 1000000)
	end

	if value > 100 then
		-- log(" over 100 -> ", string.format("%.1fk", value / 1000))
		return string.format("%.1fk", value / 1000)
	end

	-- log(" under 100 -> ", string.format("%i", value))
	return string.format("%i", value)
end