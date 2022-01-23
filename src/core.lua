local builtin = require "builtin"
local Env = require "env"
local utils = require "utils"
local raise = utils.raise
local map, slice = utils.map, utils.slice
local unpack = unpack or table.unpack

local lpeg = require "lpeg"
local P, R, S, V = lpeg.P, lpeg.R, lpeg.S, lpeg.V
local C, Cc, Ct = lpeg.C, lpeg.Cc, lpeg.Ct

local function parse()
	local alpha = R ("AZ", "az")
	local num = R "09"
	local alphanum = alpha + num
	local comment = P "--" * (1 - P "\n") ^ 0
	local space = S " \t\n" + comment

	-- Match token
	local function token(tok)
		return space ^ 0 * C (tok) * space ^ 0
	end

	-- Skip token
	local function skip(tok)
		return token(tok) / 0
	end

	-- Match keyword
	local function K(name)
		return token(name * -(alphanum + P "_"))
	end

	local function parse_error()
		raise "parse error"
	end

	local function gen_tmp(base)
		local num = 0
		return function ()
			num = num + 1
			return base .. num
		end
	end

	local function desugar(ast)
		if ast[1] == "function" then
			if ast[2][1] == "variable" then
				-- Desugar: function f() ... end
				----------> f = function () ... end
				local var = table.remove(ast, 2)
				return {"assignment", var, ast}
			end
		elseif ast[1] == "for" then
			-- Desugar: for i = a, b do ... end
			---------->
			-- do
			--     local i = a
			--     while i <= b do
			--         ...
			--         i = i + 1
			--     end
			-- end
			local assign = {"assignment", "local", ast[2], ast[3]}
			local test = {"comparison", ast[2], "<=", ast[4]}
			local inc = {"assignment", ast[2], {"sum", ast[2], "+", {"number", 1}}}
			local body = ast[5]
			table.insert(body, inc)
			return {
				"do", {
					"block", assign, {"while", test, body}
				}
			}
		elseif ast[1] == "computed_call" then
			-- Desugar: (expr)(...)
			---------->
			-- do
			--     local %1 = expr
			--     %1(...)
			-- end
			local tmp = {"variable", gen_tmp"%"()}
			local assign = {"assignment", "local", tmp, ast[2]}
			local call = {"call", tmp, ast[3]}
			return {
				"do", {
					"block", assign, call
				}
			}
		end
		return ast
	end

	local arith_op = S "+-*/"
	local rel_op = P "==" + P "!=" + S "<>" * P "=" ^ -1
	local bool_op = K "and" + K "or" + K "not"

	local keyword =
		K "and" + K "do" + K "else" + K "elseif" + K "end" + K "false" +
		K "for" + K "function" + K "if" + K "local" + K "not" + K "or" +
		K "return" + K "then" + K "true" + K "while"

	local number = C (
		S "+-" ^ -1 * num ^ 1 * (P "." * num ^ 0) ^ -1
	) / tonumber

	local string = C (
		P '"' * (1 - P '"') ^ 0 * P '"'
	) / function (tok) return tok:sub(2, -2) end

	local boolean = (
		K "true" + K "false"
	) / function (tok) return tok == "true" end

	local ident = C (
		(P "_" + alpha) ^ 1 * (P "_" + alphanum) ^ 0
	) - keyword

	return P { "program",

		program = space ^ 0 * Ct (
			V "block" +
			V "expression" +
			parse_error
		),

		number = Ct (
			Cc "number" * number
		),

		string = Ct (
			Cc "string" * string
		),

		boolean = Ct (
			Cc "boolean" * boolean
		),

		literal =
			V "number" +
			V "string" +
			V "boolean",

		variable = Ct (
			Cc "variable" * ident
		),

		expression =
			V "conditional" +
			V "disjunction" +
			V "function_def",

		disjunction = Ct (
			Cc "disjunction" * V "conjunction" * (skip "or" * V "conjunction") ^ 1
		) + V "conjunction",

		conjunction = Ct (
			Cc "conjunction" * V "comparison" * (skip "and" * V "comparison") ^ 1
		) + V "comparison",

		comparison = Ct (
			Cc "comparison" * V "concatenation" * token(rel_op) * V "concatenation"
		) + V "concatenation",

		concatenation = Ct (
			Cc "concatenation" * V "sum" * (skip ".." * V "sum") ^ 1
		) + V "sum",

		sum = Ct (
			Cc "sum" * V "product" * (token(S "+-") * V "product") ^ 1
		) + V "product",

		product = Ct (
			Cc "product" * V "unary" * (token(S "*/") * V "unary") ^ 1
		) + V "unary",

		unary = Ct (
			Cc "unary" * (token "-" + K "not")  * V "atom"
		) + V "atom",

		atom =
			-- "function_call" and "computed_function_call" must come before
			-- "variable", otherwise:
			-- tiny> x + f()
			-- [...]: attempt to perform arithmetic on a function value
			V "literal" + V "function_call" + V "computed_function_call" + V "variable" +
			skip "(" * V "expression" * skip ")",

		statement =
			V "assignment" +
			V "conditional" +
			V "while_loop" +
			V "for_loop" +
			V "do_block" +
			V "function_def" +
			V "function_call" +
			V "computed_function_call" +
			V "return_stmt",

		assignment = Ct (
			Cc "assignment" * K "local" ^ -1 * V "variable" * skip "=" * V "expression"
		),

		conditional = Ct (
			K "if" * V "expression" * skip "then" * (V "block" + V "expression") *
			(K "elseif" * V "expression" * skip "then" * (V "block" + V "expression")) ^ 0 *
			(K "else" * (V "block" + V "expression")) ^ -1 *
			skip "end"
		),

		while_loop = Ct (
			K "while" * V "expression" * skip "do" * V "block" * skip "end"
		),

		for_loop = Ct (
			K "for" * V "variable" * skip "=" *
			V "expression" * skip "," * V "expression" *
			skip "do" * V "block" * skip "end"
		) / desugar,

		do_block = Ct (
			K "do" * V "block" * skip "end"
		),

		function_def = Ct (
			K "function" * V "variable" ^ -1 *
			skip "(" * V "params" ^ -1 * skip ")" *
			(V "block" + V "expression") * skip "end"
		) / desugar,

		params = Ct (
			Cc "params" * V "variable" * (skip "," * V "variable") ^ 0
		),

		function_call = Ct (
			Cc "call" * V "variable" * skip "(" * V "args" ^ -1 * skip ")"
		),

		-- "expression" must be surrounded by parentheses to sidestep the
		-- problem of left recursion
		computed_function_call = Ct (
			Cc "computed_call" *
			skip "(" * V "expression" * skip ")" *
			skip "(" * V "args" ^ -1 * skip ")"
		) / desugar,

		args = Ct (
			Cc "args" * V "expression" * (skip "," * V "expression") ^ 0
		),

		return_stmt = Ct (
			K "return" * V "expression" ^ -1
		),

		block = Ct (
			Cc "block" * V "statement" *
			((skip ";" + skip "") * V "statement") ^ 0 *
			((skip ";" + skip "") * V "expression") ^ -1
		),

	} / unpack
end

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

return {
	parse = parse,
	eval = eval
}
