-- local Util = DAL:Ext("DariansUtilities")
local Util = DariansUtilities

Util.Gradient = Util.Gradient or { }
local Gradient = Util.Gradient
Gradient.name = "Util.Gradient"

local Tools = Util
local log = Tools.log

function Gradient:New()
	local o = { }
	setmetatable(o, self)
	self.__index = self

	o.duration = 60 * 1000

	o.samples = Tools.LinkedList:New()

	return o
end

function Gradient:Reset()
	self.samples.size = 0
	self.samples.first = nil
	self.samples.last = nil
end

function Gradient:Sample(value, time)
	-- log("Sample ", value, " at time ", time)

	self.samples:PushLast({
		value = value,
		time = time,
	})

	local last = self.samples:PeekLast()
	-- log("Last sample = ", last and last.value, " at time = ", last and last.value)

	local sample = self.samples:PeekFirst()
	while sample do
		if sample.time > time - self.duration then
			-- log("Found value ", sample.value, " in duration range ", (time - sample.time) / 1000, " seconds ago")
			break
		else
			-- log("Removing value ", sample.value, " from samples rom ", (time - sample.time) / 1000, " seconds ago")
			self.samples:PopFirst()
			sample = self.samples:PeekFirst()
		end
	end

	local earliest = self.samples:PeekFirst()
	if not earliest then return 0 end

	local latest = self.samples:PeekLast()
	if latest.time == earliest.time then return 0 end

	-- log("Calculating gradient from (", earliest.value, " @ ", earliest.time, ") to (", latest.value, " @ ", latest.time, ")")

	local gradient = (latest.value - earliest.value) / (latest.time - earliest.time)
	return gradient
end