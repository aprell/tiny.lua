#!/usr/bin/env lua

package.path = "src/?.lua;" .. package.path

require "tostring"

local parse = require "parse"
local eval = require "eval"

local function repl(prompt)
	prompt = prompt or "tiny> "
	while true do
		io.write(prompt)
		local inp = io.read()
		if not inp then io.write("\n"); break end
		if #inp > 0 then
			local ok, err = pcall(function ()
				print(eval(parse(inp)))
			end)
			if not ok then print(err) end
		end
	end
end

if #arg > 0 then
	if arg[1]:lower() == "-dump-ast" then
		table.remove(arg, 1)
		eval = print
	end
	for i = 1, #arg do
		local file = assert(io.open(arg[i]))
		eval(parse(file:read("*all")))
		file:close()
	end
else
	repl()
end
