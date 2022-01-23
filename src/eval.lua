local builtin = require "builtin"
local Env = require "env"
local utils = require "utils"

local raise = utils.raise
local map, slice = utils.map, utils.slice
local unpack = unpack or table.unpack

local function eval(ast, env)
	env = env or builtin
	if ast[1] == "number" or
	   ast[1] == "string" or
	   ast[1] == "boolean" then
		return ast[2]
	elseif ast[1] == "variable" then
		local var = ast[2]
		return Env.lookup(env, var)
	elseif ast[1] == "assignment" then
		local var, val
		if ast[2] == "local" then
			var, val = ast[3][2], eval(ast[4], env)
			Env.add(env, var, val)
		else
			var, val = ast[2][2], eval(ast[3], env)
			if Env.update(env, var, val) == nil then
				Env.add(env, var, val)
			end
		end
		return val
	elseif ast[1] == "unary" then
		local op, a = ast[2], eval(ast[3], env)
		if op == "not" then
			return not a
		else
			return -a
		end
	elseif ast[1] == "sum" or ast[1] == "product" then
		local a = eval(ast[2], env)
		for i = 3, #ast, 2 do
			local op, b = ast[i], eval(ast[i+1], env)
			a = builtin[op](a, b)
		end
		return a
	elseif ast[1] == "concatenation" then
		-- String concatenation is right-associative
		local a = eval(ast[#ast], env)
		for i = #ast-1, 2, -1 do
			local b = eval(ast[i], env)
			a = builtin[".."](b, a)
		end
		return a
	elseif ast[1] == "comparison" then
		local a, op, b = eval(ast[2], env), ast[3], eval(ast[4], env)
		return builtin[op](a, b)
	elseif ast[1] == "conjunction" then
		local a = eval(ast[2], env)
		for i = 3, #ast do
			-- Short-circuit evaluation
			if not a then return a end
			a = eval(ast[i], env)
		end
		return a
	elseif ast[1] == "disjunction" then
		local a = eval(ast[2], env)
		for i = 3, #ast do
			-- Short-circuit evaluation
			if a then return a end
			a = eval(ast[i], env)
		end
		return a
	elseif ast[1] == "if" then
		if eval(ast[2], env) then
			return eval(ast[3], Env(env))
		end
		for i = 4, #ast, 3 do
			if ast[i] == "elseif" then
				if eval(ast[i+1], env) then
					return eval(ast[i+2], Env(env))
				end
			elseif ast[i] == "else" then
				return eval(ast[i+1], Env(env))
			else
				return nil
			end
		end
	elseif ast[1] == "while" then
		while eval(ast[2], env) do
			eval(ast[3], Env(env))
		end
		return nil
	elseif ast[1] == "do" then
		return eval(ast[2], Env(env))
	elseif ast[1] == "block" then
		for i = 2, #ast-1 do
			local val = eval(ast[i], env)
			if ast[i][1] == "return" then
				return error(val)
			end
		end
		return eval(ast[#ast], env)
	elseif ast[1] == "return" then
		if ast[2] ~= nil then
			return error(eval(ast[2], env))
		else
			return error(nil)
		end
	elseif ast[1] == "function" then
		return function (...)
			local params = #ast == 3 and slice(ast[2], 2) or {}
			local body = ast[#ast]
			local args = {...}
			local scope = Env(env)
			for i = 1, #params do
				assert(params[i][1] == "variable")
				local var, val = params[i][2], args[i]
				Env.add(scope, var, val or nil)
			end
			local _, ret = pcall(function ()
				return eval(body, scope)
			end)
			return ret
		end
	elseif ast[1] == "call" then
		local fun = eval(ast[2], env) or raise "Undefined function"
		local args = ast[3] and slice(ast[3], 2) or {}
		return fun(unpack(map(args, function (ast)
			return eval(ast, env)
		end)))
	else
		raise "eval: not implemented"
	end
end

return eval
