local Env = {}

local obj_mt = {
    __index = Env,
    __tostring = function (env)
        local t = {}
        for n in pairs(env) do t[#t+1] = n end
        table.sort(t)
        local s = "{\n"
        for i = 1, #t do
            s = s .. "  " .. t[i] .. " = " .. tostring(env[t[i]]) .. "\n"
        end
        s = s .. "}"
        return s
    end
}

local class_mt = {
    __call = function (_, env)
        -- Top-level environment is empty (no globals)
        env = env or {}
        local mt = {
            outer = env,
            __index = obj_mt.__index,
            __tostring = obj_mt.__tostring
        }
        return setmetatable({}, mt)
    end
}

-- Internal value of variables that are in scope but have a value of nil
local NIL = {}

function Env:add(var, val)
    self[var] = val or NIL
end

function Env:update(var, new_val)
    local env = self
    while env ~= nil do
        local val = rawget(env, var)
        if val ~= nil then
            rawset(env, var, new_val)
            return new_val
        end
        local mt = getmetatable(env)
        if not mt then return nil end
        env = mt.outer
    end
    return nil
end

function Env:lookup(var)
    local env = self
    while env ~= nil do
        local val = rawget(env, var)
        if val == NIL then return nil end
        if val ~= nil then return val end
        local mt = getmetatable(env)
        if not mt then return nil end
        env = mt.outer
    end
    return nil
end

return setmetatable(Env, class_mt)
