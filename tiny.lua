#!/usr/bin/env lua

local builtin = require "tiny_builtin"
local Env = require "tiny_env"
local util = require "util"
local raise, ismain = util.raise, util.ismain
local map, slice = util.map, util.slice

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

	local function desugar(ast)
		if ast[1] == "function" then
			if ast[2][1] == "variable" then
				-- Desugar: function f() ... end
				----------> f = function () ... end
				local var = table.remove(ast, 2)
				return {"assignment", var, ast}
			end
		end
		return ast
	end

	local arith_op = S "+-*/"
	local rel_op = P "==" + P "!=" + S "<>" * P "=" ^ -1
	local bool_op = K "and" + K "or" + K "not"

	local keyword =
		K "and" + K "do" + K "else" + K "elseif" + K "end" + K "false" +
		K "function" + K "if" + K "local" + K "not" + K "or" + K "then" +
		K "true" + K "while"

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

		literal =
			V "single_number" +
			V "single_string" +
			V "single_boolean",

		number = Ct (
			Cc "number" * number
		),

		single_number =
			V "number" * -token(V "operator"),

		string = Ct (
			Cc "string" * string
		),

		single_string =
			V "string" * -token(V "operator"),

		boolean = Ct (
			Cc "boolean" * boolean
		),

		single_boolean =
			V "boolean" * -token(V "operator"),

		variable = Ct (
			Cc "variable" * ident
		),

		single_variable =
			V "variable" * -token(V "operator" + "=" + "("),

		assignment = Ct (
			Cc "assignment" * K "local" ^ -1 * V "variable" * skip "=" *
			(V "literal" + V "single_variable" + V "expression" + V "conditional")
		),

		expression =
			V "disjunction" +
			V "comparison" +
			V "sum" +
			V "fundef" +
			V "funcall",

		disjunction = Ct (
			Cc "disjunction" * V "conjunction" * (K "or" * V "conjunction") ^ 1
		) + V "conjunction",

		conjunction = Ct (
			Cc "conjunction" * V "comparison" * (K "and" * V "comparison") ^ 1
		) + V "comparison",

		comparison = Ct (
			Cc "comparison" * V "sum" * token(rel_op) * V "sum"
		) + V "sum",

		sum = Ct (
			Cc "sum" * V "product" * (token(S "+-") * V "product") ^ 1
		) + V "product",

		product = Ct (
			Cc "product" * V "negation" * (token(S "*/") * V "negation") ^ 1
		) + V "negation",

		negation = Ct (
			Cc "negation" * (token "-" + K "not")  * V "factor"
		) + V "factor",

		factor =
			skip "(" * V "expression" * skip ")" +
			V "number" + V "string" + V "boolean" + V "funcall" + V "variable",

		conditional = Ct (
			K "if" * V "expression" * K "then" * (V "block" + V "expression") *
			(K "elseif" * V "expression" * K "then" * (V "block" + V "expression")) ^ 0 *
			(K "else" * (V "block" + V "expression")) ^ -1 *
			K "end"
		),

		loop = Ct (
			K "while" * V "expression" * K "do" * V "block" * K "end"
		),

		do_block = Ct (
			K "do" * V "block" * K "end"
		),

		fundef = Ct (
			K "function" * V "variable" ^ -1 *
			skip "(" * V "params" ^ -1 * skip ")" *
			V "block" * K "end"
		) / desugar,

		params = Ct (
			Cc "params" * V "variable" * (skip "," * V "variable") ^ 0
		),

		funcall = Ct (
			Cc "funcall" * V "variable" * skip "(" * V "args" ^ -1 * skip ")"
		),

		args = Ct (
			Cc "args" * V "expression" * (skip "," * V "expression") ^ 0
		),

		block = Ct (
			Cc "block" * V "statement" *
			((skip ";" + skip "") * V "statement") ^ 0 *
			((skip ";" + skip "") * V "expression") ^ -1
		),

		statement =
			V "assignment" +
			V "conditional" +
			V "loop" +
			V "do_block" +
			V "fundef" +
			V "funcall",

		operator =
			arith_op + rel_op + bool_op + "..",

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
	elseif ast[1] == "comparison" then
		local a, op, b = eval(ast[2], env), ast[3], eval(ast[4], env)
		return builtin[op](a, b)
	elseif ast[1] == "sum" or ast[1] == "product" then
		local a = eval(ast[2], env)
		for i = 3, #ast, 2 do
			local op, b = ast[i], eval(ast[i+1], env)
			a = builtin[op](a, b)
		end
		return a
	elseif ast[1] == "conjunction" or ast[1] == "disjunction" then
		local a = eval(ast[2], env)
		for i = 3, #ast, 2 do
			local op = ast[i]
			-- Short-circuit evaluation
			if op == "and" and not a or op == "or" and a then
				return a
			end
			a = eval(ast[i+1], env)
		end
		return a
	elseif ast[1] == "negation" then
		local op, a = ast[2], eval(ast[3], env)
		if op == "not" then
			return not a
		end
		return -a
	elseif ast[1] == "if" then
		if eval(ast[2], env) then
			return eval(ast[4], Env.new(env))
		end
		for i = 5, #ast, 4 do
			if ast[i] == "elseif" then
				if eval(ast[i+1], env) then
					return eval(ast[i+3], Env.new(env))
				end
			elseif ast[i] == "else" then
				return eval(ast[i+1], Env.new(env))
			else
				assert(ast[i] == "end")
				return nil
			end
		end
	elseif ast[1] == "while" then
		while eval(ast[2], env) do
			eval(ast[4], Env.new(env))
		end
		return nil
	elseif ast[1] == "do" then
		return eval(ast[2], Env.new(env))
	elseif ast[1] == "block" then
		for i = 2, #ast-1 do
			eval(ast[i], env)
		end
		return eval(ast[#ast], env)
	elseif ast[1] == "function" then
		return function (...)
			local params = #ast == 4 and slice(ast[2], 2) or {}
			local body = ast[#ast-1]
			local args = {...}
			local scope = Env.new(env)
			for i = 1, #params do
				assert(params[i][1] == "variable")
				local var, val = params[i][2], args[i]
				Env.add(scope, var, val or nil)
			end
			return eval(body, scope)
		end
	elseif ast[1] == "funcall" then
		local fun = eval(ast[2], env) or raise "Undefined function"
		local args = ast[3] and slice(ast[3], 2) or {}
		return fun(unpack(map(args, function (ast)
			return eval(ast, env)
		end)))
	else
		raise "eval: not implemented"
	end
end

local function repl(prompt)
	prompt = prompt or "tiny> "
	local parse = parse()
	while true do
		io.write(prompt)
		local inp = io.read()
		if not inp then io.write("\n"); break end
		if #inp > 0 then
			local ok, err = pcall(function ()
				print(eval(parse:match(inp)))
			end)
			if not ok then print(err) end
		end
	end
end

if ismain() then
	if #arg > 0 then
		for i = 1, #arg do
			local file = assert(io.open(arg[i]))
			eval(parse():match(file:read("*all")))
			file:close()
		end
	else
		repl()
	end
else
	return {parse = parse, eval = eval}
end
