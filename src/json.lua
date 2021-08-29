local utils = require "utils"
local json = {}

local spaces = "  "

function json.array(t, indent)
	indent = indent or ""
	return ("[\n%s\n%s]"):format(
		table.concat(utils.map(t, function (t)
			if type(t) == "table" then
				return indent .. spaces .. json.convert(t, indent .. spaces)
			else
				return indent .. spaces .. ("%q"):format(t)
			end
		end), ",\n"),
		indent
	)
end

function json._object(key, value, indent)
	indent = indent or ""
	return ("{\n%s%q: %s\n%s}"):format(
		indent .. spaces,
		key,
		value,
		indent
	)
end

function json.object(t, indent)
	indent = indent or ""
	return json._object(
		t[1],
		json.array(utils.slice(t, 2), indent .. spaces),
		indent
	)
end

json.convert = {
	["number"] = function (t, indent)
		return json._object(t[1], t[2], indent)
	end,

	["boolean"] = function (t, indent)
		return json._object(t[1], t[2], indent)
	end,

	["string"] = function (t, indent)
		return json._object(t[1], ("%q"):format(t[2]), indent)
	end,
	
	["variable"] = function (t, indent)
		return json._object(t[1], ("%q"):format(t[2]), indent)
	end,
}

setmetatable(json.convert, {
	__call = function (_, t, indent)
		return json.convert[t[1]](t, indent)
	end,

	__index = function ()
		return json.object
	end
})

return json
