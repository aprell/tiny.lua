local _type = type

function type(x)
    local t, mt = _type(x), getmetatable(x)
    return mt and mt.__type or t
end
