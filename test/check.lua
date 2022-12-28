require "tostring"

local colors = require "colors"
local utils = require "utils"

local function fail_info(a, b)
    local info = debug.getinfo(4, "Sl")
    local src, line = info.short_src, info.currentline
    return ("Test failed in %s, line %d: "):format(src, line) ..
           colors.red(("got %s, expected %s"):format(tostring(a), tostring(b)))
end

local check = { failed = 0, total = 0 }

function check.equal(a, b)
    check.total = check.total + 1
    if type(a) == "table" and type(b) == "table" then
        if not utils.table_equal(a, b) then
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
        return colors.brightgreen(("All %d tests passed"):format(check.total))
    else
        return colors.brightred(("%d/%d tests failed"):format(check.failed, check.total))
    end
end

return check
