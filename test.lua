#!/usr/bin/env lua

local tiny = require "tiny"
local util = require "util"
local check = util.check.equal
local done = util.check.report

tiny = tiny.parse() / tiny.eval

local function eval(test)
	for i = 1, #test do
		check(tiny:match(test[i][1]), test[i][2])
	end
end

-- eval { { [[ code ]], expected result } }

eval {
	{ [[     1 ]], 1 },
	{ [[    -2 ]], -2 },
	{ [[  3.14 ]], 3.14 },
	{ [[ -4.50 ]], -4.50 },

	{ [[ "foo"      ]], "foo" },
	{ [[ "foo bar"  ]], "foo bar" },
	{ [[ "tiny.lua" ]], "tiny.lua" },

	{ [[ true  ]], true },
	{ [[ false ]], false },

	{ [[ 1+2           ]], 3 },
	{ [[ 1-2           ]], -1 },
	{ [[ 1*2           ]], 2 },
	{ [[ 1/2           ]], 0.5 },
	{ [[ 1+2+3         ]], 6 },
	{ [[ 1+2-3         ]], 0 },
	{ [[ 1+2*3         ]], 7 },
	{ [[ (1+2)*3       ]], 9 },
	{ [[ (1+2)/3       ]], 1 },
	{ [[ 1+2*3+4       ]], 11 },
	{ [[ (1+2)*(3+4)   ]], 21 },
	{ [[ (1+2)*(-3+4)  ]], 3 },

	{ [[ -(-1)         ]], 1 },
	{ [[ -(-(-1)+2)    ]], -3 },
	{ [[ -(-(-1)-(-1)) ]], -2 },
	{ [[ -1*-2*-3/-3   ]], 2 },
	{ [[ -1*-(2*-3)/-3 ]], 2 },

	{ [[ 1 == 1        ]], true },
	{ [[ 2 != 3        ]], true },
	{ [[ 1+2 >= 2+3    ]], false },
	{ [[ 2+3 <= 1+2    ]], false },
	{ [[ "foo" > "bar" ]], true },
	{ [[ "foo" < "bar" ]], false },
	{ [[ true != false ]], true },

	{ [[ a                   ]], nil },
	{ [[ a = 1               ]], 1 },
	{ [[ b = 2               ]], 2 },
	{ [[ ab = a + b          ]], 3 },
	{ [[ ab = ab * 2         ]], 6 },
	{ [[ c = ab > 2 * (b+1)  ]], false },
	{ [[ c = "lua" != "tiny" ]], true },
	{ [[ d = -(-a*2)/-b > a  ]], false },
	{ [[ d = -ab/2*-1*b > 0  ]], true },

	{ [[ 1 and 2              ]], 2 },
	{ [[ 1 and 2 or 3         ]], 2 },
	{ [[ "foo" or "bar"       ]], "foo" },
	{ [[ true and false       ]], false },
	{ [[ true or false        ]], true },
	{ [[ not true             ]], false },
	{ [[ not false            ]], true },
	{ [[ not (not false)      ]], false },
	{ [[ not (not true)       ]], true },
	{ [[ not (not true)       ]], true },
	{ [[ not "foo" or not 1   ]], false },
	{ [[ 1+2 > 3-4 and 5 < 6  ]], true },
	{ [[ 1+2 > 3 or (4 and 5) ]], 5 },
	{ [[ e = (e or 0) + 1     ]], 1 },
	{ [[ e = (e or 0) + 1     ]], 2 },
	{ [[ e = (e or 0) + 1     ]], 3 },
	{ [[ e = (e >= 3) and 4   ]], 4 },
	{ [[ e = not 4 or e+1     ]], 5 },

	{ [[ a = 1 ]], 1 },
	{ [[ b = 2 ]], 2 },
	{ [[ if a > 0 then true end             ]], true },
	{ [[ if a < 0 then true end             ]], nil },
	{ [[ if a > 0 then true else false end  ]], true },
	{ [[ if a < 0 then true else false end  ]], false },
	{ [[ if a > 0 then x = 1 end            ]], 1 },
	{ [[ if a < 0 then x = 1 else x = 2 end ]], 2 },
	{ [[ if not x then a = 3 end            ]], 3 },

	{ [[ if a == 1 then
	         a = a + 1
	     else
	         if a == 2 then
	             a = a + 2
	         else
	             if a == 3 then
	                 a = a + 3
	             else
	                 a = 10
	             end
	         end
	     end
	  ]], 6
    },

	{ [[ if a == 3 then a = a + 1
	     elseif a == 4 then a = a + 2
	     elseif a == 5 then a = a + 3
	     else a = 10 end
	  ]], 10
    },

	{ [[ if false then 1
	     elseif false then 2
	     elseif false then 3 end
	  ]], nil
    },

	{ [[ while a > 1 do a = a - 1 end    ]], nil },
	{ [[ while b < 10 do b = b + a end   ]], nil },
	{ [[ while a != b-1 do b = b - 1 end ]], nil },
	{ [[ while a == b+1 do nothing end   ]], nil },
	{ [[ a ]], 1 },
	{ [[ b ]], 2 },

	{ [[ if true then
             while a+b < 10 do
                 a = a + 2
             end
         end
      ]], nil
    },

	{ [[ a ]], 9 },
	{ [[ b ]], 2 },

	{ [[ while a != 1 do
             if a/b == 4 or a/b == 2 then
                 a = a/b - 1
             else
                 a = a - 1
             end
         end
      ]], nil
    },

	{ [[ a ]], 1 },
	{ [[ b ]], 2 },
}

done()
