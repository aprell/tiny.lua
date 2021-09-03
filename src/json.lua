require "type"

local utils = require "utils"
local map, slice = utils.map, utils.slice
local ordered_pairs = utils.ordered_pairs
local json = {}

local spaces = "  "

local function order_assignment(_, a, b)
	if a == "local" or a < b and b ~= "local"
	then return true else return false end
end

local function order_function(_, a, b)
	if a == "params" or a < b and b ~= "params"
	then return true else return false end
end

function json.object_to_string(obj, indent)
	indent = indent or ""
	local t = {}, f
	if obj["local"] ~= nil then f = order_assignment end
	if obj["params"] ~= nil then f = order_function end
	for k, v in ordered_pairs(obj, f) do
		t[#t+1] = indent .. spaces .. ("%q: %s"):format(k, json.to_string(v, indent .. spaces))
	end
	return ("{\n%s\n%s}"):format(table.concat(t, ",\n"), indent)
end

function json.array_to_string(arr, indent)
	indent = indent or ""
	local t = {}
	for _, v in ipairs(arr) do
		t[#t+1] = indent .. spaces .. json.to_string(v, indent .. spaces)
	end
	return ("[\n%s\n%s]"):format(table.concat(t, ",\n"), indent)
end

function json.to_string(t, indent)
	indent = indent or ""
	if type(t) == "object" then
		return json.object_to_string(t, indent)
	elseif type(t) == "array" then
		return json.array_to_string(t, indent)
	else
		return t
	end
end

local function convert(t)
	if type(t) == "table" then
		return json.convert[t[1]](t)
	else
		return ("%q"):format(t)
	end
end

local object_mt = {__tostring = json.object_to_string, __type = "object"}
local array_mt = {__tostring = json.array_to_string, __type = "array"}

function json.object(t)
	t = t or {}
	return setmetatable(t, object_mt)
end

function json.array(t)
	t = t or {}
	return setmetatable(t, array_mt)
end

json.convert = {}

json.convert["number"] = function (t)
	return json.object {
		["number"] = t[2]
	}
end

json.convert["boolean"] = function (t)
	return json.object {
		["boolean"] = t[2]
	}
end

json.convert["string"] = function (t)
	return json.object {
		["string"] = ("%q"):format(t[2])
	}
end

json.convert["variable"] = function (t)
	return json.object {
		["variable"] = ("%q"):format(t[2])
	}
end

json.convert["unary"] = function (t)
	return json.object {
		["unary"] = json.object {
			[t[2]] = convert(t[3])
		}
	}
end

json.convert["binary"] = function (t)
	return json.object {
		[t[1]] = json.array(map(slice(t, 2), convert))
	}
end

json.convert["block"] = function (t)
	return json.object {
		["block"] = json.array(map(slice(t, 2), convert))
	}
end

json.convert["if"] = function (t)
	return json.object {
		["if"] = json.array(map(slice(t, 2), convert))
	}
end

json.convert["while"] = function (t)
	return json.object {
		["while"] = json.array(map(slice(t, 2), convert))
	}
end

json.convert["do"] = function (t)
	return json.object {
		["do"] = json.object(convert(t[2]))
	}
end

json.convert["assignment"] = function (t)
	local local_, lhs, rhs
	if #t == 3 then
		local_ = false
		lhs = t[2][2]
		rhs = t[3]
	else
		local_ = true
		lhs = t[3][2]
		rhs = t[4]
	end
	return json.object {
		["assignment"] = json.object {
			["local"] = local_,
			[lhs] = json.object(convert(rhs))
		}
	}
end

json.convert["function"] = function (t)
	local body, params
	if #t == 2 then
		params = {}
		body = t[2]
	else
		params = slice(t[2], 2)
		body = t[3]
	end
	return json.object {
		["function"] = json.object {
			["params"] = json.array(map(params, convert)),
			["body"] = json.object(convert(body))
		}
	}
end

json.convert["call"] = function (t)
	local fun, args
	fun = t[2][2]
	if #t == 2 then
		args = {}
	else
		args = slice(t[3], 2)
	end
	return json.object {
		["call"] = json.object {
			[fun] = json.array(map(args, convert))
		}
	}
end

json.convert["return"] = function (t)
	return json.object {
		["return"] = json.object(convert(t[2]))
	}
end

setmetatable(json.convert, {
	__index = function ()
		return json.convert.binary
	end
})

return convert
