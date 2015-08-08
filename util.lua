local util = {}
local _tostring = tostring

-- Applies a function to every element of an array
-- Shares metatable with original array
function util.map(t, fn)
	local m = {}
	for _, v in ipairs(t) do
		table.insert(m, (fn(v)))
	end
	return setmetatable(m, getmetatable(t))
end

-- Returns a slice (copy) of an array or subarray
-- Shares metatable with original array
function util.slice(t, i, j)
	i = i or 1
	j = j or #t
	if j < 0 then j = j + #t + 1 end
	if i < 1 or j > #t or i > j then
		return setmetatable({}, getmetatable(t))
	end
	local slice = {}
	for k = i, j do
		table.insert(slice, t[k])
	end
	return setmetatable(slice, getmetatable(t))
end

-- Concatenates the elements of a table to form a string
function util.concat(t, sep)
	sep = sep or " "
	local s = ""
	for i = 1, #t do
		s = s .. _tostring(t[i])
		if i < #t then s = s .. sep end
	end
	return s
end

-- Overrides tostring to print table contents
function tostring(n)
	if type(n) == "table"  then
		local mt = getmetatable(n)
		if mt ~= nil and mt.__tostring ~= nil then
			return mt.__tostring(n)
		else
			return "{" .. util.concat(util.map(n, tostring), ", ") .. "}"
		end
	else
		return _tostring(n)
	end
end

-- Raises an error with message err_msg
function util.raise(err_msg)
	local err_mt = {__tostring = function (err) return err.reason end}
	return error(setmetatable({reason = err_msg}, err_mt))
end

function util.ismain()
	return not debug.getinfo(4)
end

local check = { failed = 0, total = 0 }

local function escape(code)
	return string.char(27) .. string.format("[%dm", code)
end

local function red(str)
	return escape(31) .. str .. escape(0)
end

local function green(str)
	return escape(32) .. str .. escape(0)
end

local function brightred(str)
	return escape(1) .. escape(31) .. str .. escape(0)
end

local function brightgreen(str)
	return escape(1) .. escape(32) .. str .. escape(0)
end

-- Returns true if a is a subset of b
local function subset(a, b)
	for k, v in pairs(a) do
		if b[k] ~= v then
			return false
		end
	end
	return true
end

-- Two tables a and b are equal if a is a subset of b and b is a subset of a
local function table_equal(a, b)
	return subset(a, b) and subset(b, a)
end

local function fail_info(a, b)
	local info = debug.getinfo(4, "Sl")
	local src, line = info.short_src, info.currentline
	return ("Check failed in %s, line %d: "):format(src, line) ..
	       red(("got %s, expected %s"):format(tostring(a), tostring(b)))
end

function check.equal(a, b)
	check.total = check.total + 1
	if type(a) == "table" and type(b) == "table" then
		if not table_equal(a, b) then
			print(fail_info(a, b))
			check.failed = check.failed + 1
			return false
		else
			return true
		end
	end
	if a ~= b then
		print(fail_info(a, b))
		check.failed = check.failed + 1
		return false
	else
		return true
	end
end

function check.report()
	if check.failed == 0 then
		print(brightgreen("[SUCCESS] " ..
		      ("%d/%d checks passed."):format(check.total, check.total)))
		return true
	else
		print(brightred("[FAILURE] " ..
		      ("%d/%d checks failed."):format(check.failed, check.total)))
		return false
	end
end

util.check = check

return util
