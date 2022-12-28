local colors = {}

local function escape(code)
    return string.char(27) .. string.format("[%dm", code)
end

function colors.red(str)
    return escape(31) .. str .. escape(0)
end

function colors.green(str)
    return escape(32) .. str .. escape(0)
end

function colors.brightred(str)
    return escape(1) .. escape(31) .. str .. escape(0)
end

function colors.brightgreen(str)
    return escape(1) .. escape(32) .. str .. escape(0)
end

return colors
