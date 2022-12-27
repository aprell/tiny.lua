local json = require "json"
local _tostring = tostring

function tostring(n)
    if type(n) == "table" then
        local mt = getmetatable(n)
        if mt ~= nil and mt.__tostring ~= nil then
            return mt.__tostring(n)
        else
            return _tostring(json(n))
        end
    else
        return _tostring(n)
    end
end
