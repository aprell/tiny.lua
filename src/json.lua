require "type"

local utils = require "utils"
local map, slice = utils.map, utils.slice
local keys = utils.keys
local json = {}

local spaces = "  "

function json.object_to_string(obj, indent)
	indent = indent or ""
	local t = {}
	for _, k in ipairs(obj.__keys or keys(obj)) do
		t[#t+1] = indent .. spaces .. ("%q: %s"):format(k, json.to_string(obj[k], indent .. spaces))
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

local function convert(t)
	if type(t) == "table" then
		return json.convert(t)
	elseif type(t) == "string" then
		return ("%q"):format(t)
	else
		return tostring(t)
	end
end

local function json_object(t)
	return json.object {
		[t[1]] = convert(t[2])
	}
end

local function json_array(t)
	return json.array(map(t, convert))
end

json.convert = {}

json.convert["number"] = json_object

json.convert["boolean"] = json_object

json.convert["string"] = json_object

json.convert["variable"] = json_object

json.convert["do"] = json_object

json.convert["return"] = json_object

json.convert["unary"] = function (t)
	return json.object {
		["unary"] = json_object(slice(t, 2))
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
			["lhs"] = convert(lhs),
			["rhs"] = json.object(convert(rhs)),
			__keys = {"local", "lhs", "rhs"}
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
			["params"] = json_array(params),
			["body"] = json.object(convert(body)),
			__keys = {"params", "body"}
		}
	}
end

json.convert["call"] = function (t)
	local func, args
	func = t[2][2]
	if #t == 2 then
		args = {}
	else
		args = slice(t[3], 2)
	end
	return json.object {
		["call"] = json.object {
			["func"] = convert(func),
			["args"] = json_array(args),
			__keys = {"func", "args"}
		}
	}
end

local function default(t)
	return json.object {
		[t[1]] = json_array(slice(t, 2))
	}
end

setmetatable(json.convert, {
	__call = function (_, t)
		return json.convert[t[1]](t)
	end,

	__index = function ()
		return default
	end
})

return convert
