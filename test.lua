#!/usr/bin/env lua

local tiny = require "tiny"
local util = require "util"
local check = util.check.equal
local done = util.check.report

tiny = tiny.parse() / tiny.eval

local function eval(test)
	for i = 1, #test, 2 do
		check(tiny:match(test[i]), test[i+1])
	end
end

-- eval { [[ code ]], expected result }

eval {
	[[     1 ]],     1,
	[[    -2 ]],    -2,
	[[  3.14 ]],  3.14,
	[[ -4.50 ]], -4.50,

	[[ 1+2-3          ]],   0,
	[[ -1*2 + 4*-5    ]], -22,
	[[ 3 * (4+6) + 12 ]],  42,
	[[ 100/10/2       ]],   5,

	[[ "tiny"     ]],     "tiny",
	[[ "lua"      ]],      "lua",
	[[ "tiny.lua" ]], "tiny.lua",

	[[ true  ]],  true,
	[[ false ]], false,

	[[ a           ]], nil,
	[[ a = 1       ]],   1,
	[[ b = 2       ]],   2,
	[[ ab = a + b  ]],   3,
	[[ ab = ab * 2 ]],   6,
}

done()
