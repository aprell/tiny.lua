local env = {}

-- Internal value of variables that are in scope but have a value of nil
local NIL = {}

local function env_tostring(env)
	local t = {}
	for n in pairs(env) do t[#t+1] = n end
	table.sort(t)
	local s = "{\n"
	for i = 1, #t do
		s = s .. "  " .. t[i] .. " = " .. tostring(env[t[i]]) .. "\n"
	end
	s = s .. "}"
	return s
end

function env.new(outer)
	-- Top-level environment is empty (no globals)
	outer = outer or {}
	local mt = {
		outer = outer,
		__index = outer,
		__tostring = env_tostring
	}
	return setmetatable({}, mt)
end

function env.add(env, var, val)
	env[var] = val or NIL
end

function env.update(env, var, val)
	while env ~= nil do
		local v = rawget(env, var)
		if v ~= nil then rawset(env, var, val); return val end
		local mt = getmetatable(env)
		if not mt then return nil end
		env = mt.outer
	end
	return nil
end

function env.lookup(env, var)
	local val = env[var]
	if val == NIL then return nil end
	return val
end

return env
