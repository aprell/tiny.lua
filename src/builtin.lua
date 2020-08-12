local Env = require "env"

local builtin = Env()

for sym, val in pairs {

	["+"] = function (a, b) return a + b end,
	["-"] = function (a, b) return a - b end,
	["*"] = function (a, b) return a * b end,
	["/"] = function (a, b) return a / b end,

	["=="] = function (a, b) return a == b end,
	["!="] = function (a, b) return a ~= b end,
	["<="] = function (a, b) return a <= b end,
	[">="] = function (a, b) return a >= b end,
	["<"]  = function (a, b) return a < b end,
	[">"]  = function (a, b) return a > b end,

	[".."] = function (a, b) return a .. b end,

	["print"] = print,

} do builtin:add(sym, val) end

return builtin
