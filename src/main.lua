#!/usr/bin/env lua

package.path = "src/?.lua;" .. package.path

local core = require "core"
local parse = core.parse()
local eval = core.eval
local repl = core.repl

if #arg > 0 then
	if arg[1]:lower() == "-dump-ast" then
		table.remove(arg, 1)
		eval = print
	end
	for i = 1, #arg do
		local file = assert(io.open(arg[i]))
		eval(parse:match(file:read("*all")))
		file:close()
	end
else
	repl()
end
