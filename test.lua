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
	[[     1 ]], 1,
	[[    -2 ]], -2,
	[[  3.14 ]], 3.14,
	[[ -4.50 ]], -4.50,

	[[ "foo"      ]], "foo",
	[[ "foo bar"  ]], "foo bar",
	[[ "tiny.lua" ]], "tiny.lua",

	[[ true  ]], true,
	[[ false ]], false,

	[[ 1+2           ]], 3,
	[[ 1-2           ]], -1,
	[[ 1*2           ]], 2,
	[[ 1/2           ]], 0.5,
	[[ 1+2+3         ]], 6,
	[[ 1+2-3         ]], 0,
	[[ 1+2*3         ]], 7,
	[[ (1+2)*3       ]], 9,
	[[ (1+2)/3       ]], 1,
	[[ 1+2*3+4       ]], 11,
	[[ (1+2)*(3+4)   ]], 21,
	[[ (1+2)*(-3+4)  ]], 3,

	[[ -(-1)         ]], 1,
	[[ -(-(-1)+2)    ]], -3,
	[[ -(-(-1)-(-1)) ]], -2,
	[[ -1*-2*-3/-3   ]], 2,
	[[ -1*-(2*-3)/-3 ]], 2,

	[[ 1 == 1        ]], true,
	[[ 2 != 3        ]], true,
	[[ 1+2 >= 2+3    ]], false,
	[[ 2+3 <= 1+2    ]], false,
	[[ "foo" > "bar" ]], true,
	[[ "foo" < "bar" ]], false,
	[[ true != false ]], true,

	[[ a                   ]], nil,
	[[ a = 1               ]], 1,
	[[ b = 2               ]], 2,
	[[ ab = a + b          ]], 3,
	[[ ab = ab * 2         ]], 6,
	[[ c = ab > 2 * (b+1)  ]], false,
	[[ c = "lua" != "tiny" ]], true,
	[[ d = -(-a*2)/-b > a  ]], false,
	[[ d = -ab/2*-1*b > 0  ]], true,
}

done()
