local utils = {}
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

-- Raises an error with message err_msg
function utils.raise(err_msg)
    local err_mt = {__tostring = function (err) return err.reason end}
    return error(setmetatable({reason = err_msg}, err_mt))
end

function utils.ismain()
    return not debug.getinfo(4)
end

function utils.keys(t)
    local ks = {}
    for k in pairs(t) do
        ks[#ks+1] = k
    end
    return ks
end

function utils.ordered_pairs(t, cmp)
    local keys = utils.keys(t)

    table.sort(keys, cmp and function (a, b) return cmp(t, a, b) end or nil)

    local i = 0
    return function ()
        i = i + 1
        if keys[i] ~= nil then
            return keys[i], t[keys[i]]
        end
    end
end

-- Returns true if a is a subset of b
local function subset(a, b)
    for k, v in pairs(a) do
        if type(v) == "table" then
            if type(b[k]) ~= "table" then
                return false
            elseif not subset(v, b[k]) then
                return false
            end
        else
            if b[k] ~= v then
                return false
            end
        end
    end
    return true
end

-- Two tables a and b are equal if a is a subset of b and b is a subset of a
function utils.table_equal(a, b)
    return subset(a, b) and subset(b, a)
end

return utils
