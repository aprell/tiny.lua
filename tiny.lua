#!/usr/bin/env lua

local builtin = require "tiny_builtin"
local Env = require "tiny_env"
local util = require "util"
local raise, ismain = util.raise, util.ismain

local lpeg = require "lpeg"
local P, R, S, V = lpeg.P, lpeg.R, lpeg.S, lpeg.V
local C, Cc, Ct = lpeg.C, lpeg.Cc, lpeg.Ct

local function parse()
	local alpha = R ("AZ", "az")
	local num = R "09"
	local alphanum = alpha + num
	local space = S " \t\n"

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

	local arith_op = S "+-*/"
	local rel_op = P "==" + P "!=" + S "<>" * P "=" ^ -1
	local bool_op = K "and" + K "or" + K "not"

	local keyword =
		K "and" + K "else" + K "elseif" + K "end" + K "false" + K "if" +
		K "not" + K "or" + K "then" + K "true"

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
			V "literal" +
			V "single_variable" +
			V "assignment" +
			V "expression" +
			V "conditional" +
			V "comment" +
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
			V "variable" * -token(V "operator" + "="),

		assignment = Ct (
			Cc "assignment" * V "variable" * skip "=" *
			(V "literal" + V "single_variable" + V "expression")
		),

		expression =
			V "disjunction",
			V "comparison",
			V "sum",

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
			V "number" + V "string" + V "boolean" + V "variable",

		conditional = Ct (
			K "if" * V "expression" * K "then" * V "block" *
			(K "elseif" * V "expression" * K "then" * V "block") ^ 0 *
			(K "else" * V "block") ^ -1 *
			K "end"
		),

		block =
			V "assignment" + V "expression" + V "conditional",

		operator =
			arith_op + rel_op + bool_op + "..",

		comment =
			skip "--" * (1 - P "\n") ^ 0,

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
		local var, val = ast[2][2], eval(ast[3], env)
		if Env.update(env, var, val) == nil then
			Env.add(env, var, val)
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
	repl()
else
	return {parse = parse, eval = eval}
end
