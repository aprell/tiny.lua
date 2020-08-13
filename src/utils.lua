local utils = {}
local _tostring = tostring
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

-- Overrides tostring to print table contents
function tostring(n, indent)
	indent = indent or ""
	if type(n) == "table" then
		local mt = getmetatable(n)
		if mt ~= nil and mt.__tostring ~= nil then
			return indent .. mt.__tostring(n)
		else
			return ("%s{\n%s\n%s}"):format(
				indent,
				table.concat(utils.map(n, function (m)
					return tostring(m, indent .. string.rep(" ", 4))
				end), ",\n"),
				indent
			)
		end
	else
		return indent .. _tostring(n)
	end
end

-- Raises an error with message err_msg
function utils.raise(err_msg)
	local err_mt = {__tostring = function (err) return err.reason end}
	return error(setmetatable({reason = err_msg}, err_mt))
end

function utils.ismain()
	return not debug.getinfo(4)
end

return utils
