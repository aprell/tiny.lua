local lpeg = require "lpeg"

local P, R, S, V = lpeg.P, lpeg.R, lpeg.S, lpeg.V
local C, Cc, Ct = lpeg.C, lpeg.Cc, lpeg.Ct
local unpack = unpack or table.unpack

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

-- Match list of ps
local function list(p)
	return V (p) * (skip "," * V (p)) ^ 0
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
    elseif ast[1] == "local" and ast[2] == "function" then
        assert(ast[3][1] == "variable")
        -- Desugar: local function f() ... end
        ----------> local f = function () ... end
        table.remove(ast, 1)
        local var = table.remove(ast, 2)
        return {"assignment", "local", var, ast}
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

local identifier = C (
	(P "_" + alpha) ^ 1 * (P "_" + alphanum) ^ 0
) - keyword

-- +----------------+
-- | tiny's grammar |
-- +----------------+

local tiny = P {
	"program",

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
		Cc "variable" * identifier
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
		V "local_function_def" +
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
		K "function" * V "variable" ^ -1 * V "params" *
		(V "block" + V "expression") * skip "end"
	) / desugar,

	local_function_def = Ct (
		K "local" * K "function" * V "variable" * V "params" *
		(V "block" + V "expression") * skip "end"
	) / desugar,

	params =
		skip "(" * Ct (Cc "params" * list "variable") ^ -1 * skip ")",

	function_call = Ct (
		Cc "call" * V "variable" * V "args"
	),

	-- "expression" must be enclosed in parentheses to sidestep the problem of
	-- left recursion
	computed_function_call = Ct (
		Cc "computed_call" * skip "(" * V "expression" * skip ")" * V "args"
	) / desugar,

	args =
		skip "(" * Ct (Cc "args" * list "expression") ^ -1 * skip ")",

	return_stmt = Ct (
		K "return" * V "expression" ^ -1
	),

	block = Ct (
		Cc "block" * V "statement" *
		((skip ";" + skip "") * V "statement") ^ 0 *
		((skip ";" + skip "") * V "expression") ^ -1
	),
} / unpack

local function parse(input)
	return tiny:match(input)
end

return parse
