-- local Util = DAL:Ext("DariansUtilities")
local Util = DariansUtilities
Util.SavedVars = { }
local SavedVars = Util.SavedVars
local log = Util.log

function SavedVars.ensureDefaults(config, defaults)
	if not type(defaults) == "table" then return end

	for key, value in defaults do
		local existing = config[key]
		if existing then
			SavedVars.ensureDefaults(existing, value)
		else
			config[key] = existing
		end
	end
end