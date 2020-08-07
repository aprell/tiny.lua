#!/usr/bin/env lua

package.path = "../src/?.lua;" .. package.path

local check = require "check"
local core = require "core"

local parse = core.parse()
local eval = core.eval

local TEST = function (code)
	return function (expected_ast)
		local actual_ast = parse:match(code)
		if expected_ast ~= nil then
			check.equal(actual_ast, expected_ast)
		end
		return function (expected_value)
			check.equal(eval(actual_ast), expected_value)
		end
	end
end

TEST
----
[[
    1
]]
( pass )
( 1 )

TEST
----
[[
    -2
]]
( pass )
( -2 )

TEST
----
[[
    3.14
]]
( pass )
( 3.14 )

TEST
----
[[
    -4.50
]]
( pass )
( -4.50 )

TEST
----
[[
    "foo"
]]
( pass )
( "foo" )

TEST
----
[[
    "foo bar"
]]
( pass )
( "foo bar" )

TEST
----
[[
    "tiny.lua"
]]
( pass )
( "tiny.lua" )

TEST
----
[[
    true
]]
( pass )
( true )

TEST
----
[[
    false
]]
( pass )
( false )

TEST
----
[[
    1 + 2
]]
( pass )
( 3 )

TEST
----
[[
    1 - 2
]]
( pass )
( -1 )

TEST
----
[[
    1 * 2
]]
( pass )
( 2 )

TEST
----
[[
    1 / 2
]]
( pass )
( 0.5 )

TEST
----
[[
    1 + 2 + 3
]]
( pass )
( 6 )

TEST
----
[[
    1 + 2 - 3
]]
( pass )
( 0 )

TEST
----
[[
    1 + 2 * 3
]]
( pass )
( 7 )

TEST
----
[[
    (1 + 2) * 3
]]
( pass )
( 9 )

TEST
----
[[
    (1 + 2) / 3
]]
( pass )
( 1 )

TEST
----
[[
    1 + 2 * 3 + 4
]]
( pass )
( 11 )

TEST
----
[[
    (1 + 2) * (3 + 4)
]]
( pass )
( 21 )

TEST
----
[[
    (1 + 2) * (-3 + 4)
]]
( pass )
( 3 )

TEST
----
[[
    -(-1)
]]
( pass )
( 1 )

TEST
----
[[
    -(-(-1) + 2)
]]
( pass )
( -3 )

TEST
----
[[
    -(-(-1) -(-1))
]]
( pass )
( -2 )

TEST
----
[[
    -1 * -2 * -3 / -3
]]
( pass )
( 2 )

TEST
----
[[
    -1 * -(2 * -3) / -3
]]
( pass )
( 2 )

TEST
----
[[
    1 == 1
]]
( pass )
( true )

TEST
----
[[
    2 != 3
]]
( pass )
( true )

TEST
----
[[
    1 + 2 >= 2 + 3
]]
( pass )
( false )

TEST
----
[[
    2 + 3 <= 1 + 2
]]
( pass )
( false )

TEST
----
[[
    "foo" > "bar"
]]
( pass )
( true )

TEST
----
[[
    "foo" < "bar"
]]
( pass )
( false )

TEST
----
[[
    "true" != "false"
]]
( pass )
( true )

TEST
----
[[
    a
]]
( pass )
( nil )

TEST
----
[[
    a = 1
]]
( pass )
( 1 )

TEST
----
[[
    b = 2
]]
( pass )
( 2 )

TEST
----
[[
    ab = a + b
]]
( pass )
( 3 )

TEST
----
[[
    ab = ab * 2
]]
( pass )
( 6 )

TEST
----
[[
    c = ab > 2 * (b + 1)
]]
( pass )
( false )

TEST
----
[[
    c = "lua" != "tiny"
]]
( pass )
( true )

TEST
----
[[
    d = -(-a * 2) / -b > a
]]
( pass )
( false )

TEST
----
[[
    d = -ab / 2 * -1 * b > 0
]]
( pass )
( true )

TEST
----
[[
    1 and 2
]]
( pass )
( 2 )

TEST
----
[[
    1 and 2 or 3
]]
( pass )
( 2 )

TEST
----
[[
    "foo" or "bar"
]]
( pass )
( "foo" )

TEST
----
[[
    true and false
]]
( pass )
( false )

TEST
----
[[
    true or false
]]
( pass )
( true )

TEST
----
[[
    not true
]]
( pass )
( false )

TEST
----
[[
    not false
]]
( pass )
( true )

TEST
----
[[
    not (not false)
]]
( pass )
( false )

TEST
----
[[
    not (not true)
]]
( pass )
( true )

TEST
----
[[
    not "foo" or not 1
]]
( pass )
( false )

TEST
----
[[
    1+2 > 3-4 and 5 < 6
]]
( pass )
( true )

TEST
----
[[
    1+2 > 3 or (4 and 5)
]]
( pass )
( 5 )

TEST
----
[[
    e = (e or 0) + 1
]]
( pass )
( 1 )

TEST
----
[[
    e = (e or 0) + 1
]]
( pass )
( 2 )

TEST
----
[[
    e = (e or 0) + 1
]]
( pass )
( 3 )

TEST
----
[[
    e = (e >= 3) and 4
]]
( pass )
( 4 )

TEST
----
[[
    e = not 4 or e+1
]]
( pass )
( 5 )

TEST
----
[[
    a = 1
]]
( pass )
( 1 )

TEST
----
[[
    b = 2
]]
( pass )
( 2 )

TEST
----
[[
    if a > 0 then true end
]]
( pass )
( true )

TEST
----
[[
    if a < 0 then true end
]]
( pass )
( nil )

TEST
----
[[
    if a > 0 then true else false end
]]
( pass )
( true )

TEST
----
[[
    if a < 0 then true else false end
]]
( pass )
( false )

TEST
----
[[
    if a > 0 then x = 1 end
]]
( pass )
( 1 )

TEST
----
[[
    if a < 0 then x = 1 else x = 2 end
]]
( pass )
( 2 )

TEST
----
[[
    if not x then a = 3 end
]]
( pass )
( 3 )

TEST
----
[[
    if a == 1 then
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
]]
( pass )
( 6 )

TEST
----
[[
    if a == 3 then a = a + 1
    elseif a == 4 then a = a + 2
    elseif a == 5 then a = a + 3
    else a = 10 end
]]
( pass )
( 10 )

TEST
----
[[
    if false then 1
    elseif false then 2
    elseif false then 3 end
]]
( pass )
( nil )

TEST
----
[[
    while a > 1 do a = a - 1 end
]]
( pass )
( nil )

TEST
----
[[
    while b < 10 do b = b + a end
]]
( pass )
( nil )

TEST
----
[[
    while a != b - 1 do b = b - 1 end
]]
( pass )
( nil )

TEST
----
[[
    while a == b + 1 do b = false end
]]
( pass )
( nil )

TEST
----
[[
    if true then
        a = 1; b = 2
        while a + b < 10 do
            a = a + 2
        end
    end
]]
( pass )
( nil )

TEST
----
[[
    a
]]
( pass )
( 9 )

TEST
----
[[
    b
]]
( pass )
( 2 )

TEST
----
[[
    while a != 1 do
        if a / b == 4 or a / b == 2 then
            a = a / b
        end
        a = a - 1
    end
]]
( pass )
( nil )

TEST
----
[[
    a
]]
( pass )
( 1 )

TEST
----
[[
    b
]]
( pass )
( 2 )

TEST
----
[[
    for i = 1, 1 do a = a + i end
]]
( pass )
( nil )

TEST
----
[[
    for i = 1, 2 do a = a - i end
]]
( pass )
( nil )

TEST
----
[[
    for i = 1, 3 do a = a + i end
]]
( pass )
( nil )

TEST
----
[[
    for i = -1, -4 do a = a - i end
]]
( pass )
( nil )

TEST
----
[[
    for i = -1, +4 do a = a + i end
]]
( pass )
( nil )

TEST
----
[[
    a = a - 13
]]
( pass )
( 1 )

TEST
----
[[
    do
        x = "x"; y = "y"
        if x == y then
            true
        else
            false
        end
    end
]]
( pass )
( false )

TEST
----
[[
    x
]]
( pass )
( nil )

TEST
----
[[
    y
]]
( pass )
( nil )

TEST
----
[[
    f = function ()
        a = a + 1
    end f()
]]
( pass )
( 2 )

TEST
----
[[
    a
]]
( pass )
( 2 )

TEST
----
[[
    b
]]
( pass )
( 2 )

TEST
----
[[
    c
]]
( pass )
( true )

TEST
----
[[
    f = function ()
        local a = 1
        local b = 2
        local c = 3
        a + b + c
    end f()
]]
( pass )
( 6 )

TEST
----
[[
    a
]]
( pass )
( 2 )

TEST
----
[[
    b
]]
( pass )
( 2 )

TEST
----
[[
    c
]]
( pass )
( true )

TEST
----
[[
    f = function (a, b, c)
        c = c or 3
        a + b + c
    end f(1, 2, 3)
]]
( pass )
( 6 )

TEST
----
[[
    a
]]
( pass )
( 2 )

TEST
----
[[
    b
]]
( pass )
( 2 )

TEST
----
[[
    c
]]
( pass )
( true )

TEST
----
[[
    f(1, 2)
]]
( pass )
( 6 )

TEST
----
[[
    a
]]
( pass )
( 2 )

TEST
----
[[
    b
]]
( pass )
( 2 )

TEST
----
[[
    c
]]
( pass )
( true )

TEST
----
[[
    function f()
        local a = 1
        function ()
            while a < 10 do
                a = a + 1
            end
            a + b
        end
    end a = f(); a()
]]
( pass )
( 12 )

TEST
----
[[
    function f()
        local a = 1
        function ()
            while a < 10 do
                a = a + 1
            end
            a + b
        end
    end a = f(); a()
]]
( pass )
( 12 )

--------------
check.report()
--------------
