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
	local arith_op = S "+-*/"
	local operator = arith_op

	-- Match token
	local function skip(tok)
		return space ^ 0 * tok * space ^ 0
	end

	-- Capture keyword
	local function K(name)
		return C (P (name)) * -(alphanum + P "_")
	end

	local function parse_error()
		raise "parse error"
	end

	local keyword = K "false" + K "true"

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
			V "arith_expr" +
			V "comment" +
			parse_error
		),

		literal =
			V "single_number" +
			V "string" +
			V "boolean",

		number = Ct (
			Cc "number" * number
		),

		single_number =
			V "number" * -(skip (operator)),

		string = Ct (
			Cc "string" * string
		),

		boolean = Ct (
			Cc "boolean" * boolean
		),

		variable = Ct (
			Cc "variable" * ident
		),

		single_variable =
			V "variable" * -(skip (operator + "=")),

		assignment = Ct (
			Cc "assignment" * V "variable" * skip "=" *
			(V "literal" + V "single_variable" + V "arith_expr")
		),

		arith_expr =
			V "sum",

		sum = Ct (
			Cc "sum" * V "product" * (skip (C (S "+-")) * V "product") ^ 1
		) + V "product",

		product = Ct (
			Cc "product" * V "factor" * (skip (C (S "*/")) * V "factor") ^ 1
		) + V "factor",

		factor =
			skip "(" * V "arith_expr" * skip ")" +
			V "number" + V "variable",

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
		Env.add(env, var, val)
		return val
	elseif ast[1] == "sum" or
		   ast[1] == "product" then
		local a = eval(ast[2], env)
		for i = 3, #ast, 2 do
			local op, b = ast[i], eval(ast[i+1], env)
			a = builtin[op](a, b)
		end
		return a
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
