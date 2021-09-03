local utils = {}
local unpack = unpack or table.unpack

-- Applies a function to every element of an array
-- Shares metatable with original array
function utils.map(t, fn)
	local m = {}
	for _, v in ipairs(t) do
		table.insert(m, (fn(v)))
	end
	return setmetatable(m, getmetatable(t))
end

-- Returns a slice (copy) of an array or subarray
-- Shares metatable with original array
function utils.slice(t, i, j)
	return setmetatable({unpack(t, i, j)}, getmetatable(t))
end

-- Raises an error with message err_msg
function utils.raise(err_msg)
	local err_mt = {__tostring = function (err) return err.reason end}
	return error(setmetatable({reason = err_msg}, err_mt))
end

function utils.ismain()
	return not debug.getinfo(4)
end

function utils.ordered_pairs(t, cmp)
	local keys = {}
	for k in pairs(t) do
		keys[#keys+1] = k
	end

	if cmp then
		table.sort(keys, function (a, b) return cmp(t, a, b) end)
	else
		table.sort(keys)
	end

	local i = 0
	return function ()
		i = i + 1
		if keys[i] ~= nil then
			return keys[i], t[keys[i]]
		end
	end
end

return utils
