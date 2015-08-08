local Env = require "tiny_env"

local builtin = Env.new()

for sym, val in pairs {

	["+"] = function (a, b) return a + b end,
	["-"] = function (a, b) return a - b end,
	["*"] = function (a, b) return a * b end,
	["/"] = function (a, b) return a / b end,

} do Env.add(builtin, sym, val) end

return builtin
