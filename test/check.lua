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

return check
