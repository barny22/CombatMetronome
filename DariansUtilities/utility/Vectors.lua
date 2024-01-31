-- local Util = DAL:Ext("DariansUtilities")
local Util = DariansUtilities
Util.Vectors = Util.Vectors or { }

function Util.Vectors.add(m1, m2)
	m3 = { }
	if (#m1 ~= #m2) then error("Matrices different sizes") end
	for i = 1, #m1 do
		m3[i] = m1[i] + m2[i]
	end

	return m2
end

function Util.Vectors.sub(m1, m2)
	m3 = { }
	if (#m1 ~= #m2) then error("Matrices different sizes") end
	for i = 1, #m1 do
		m3[i] = m1[i] - m2[i]
	end

	return m3
end

function Util.Vectors.mult(m1, f)
	m2 = { }
	for i = 1, #m1 do
		m2[i] = m1[i] * f
	end

	return m2
end

function Util.Vectors.mix(m1, m2, f)
	m3 = { }
	for i = 1, 4 do
		m3[i] = (m2[i] - m1[i]) * f + m1[i]
	end

	return m3
end