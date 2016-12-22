#!/usr/bin/env lua

local tiny = require "tiny"
local util = require "util"

tiny = tiny.parse() / tiny.eval

local TEST = function (code)
	return function (value)
		util.check.equal(tiny:match(code), value)
	end
end

local TEST_REPORT = util.check.report

TEST
----
[[
    1
]]
    ( 1 )

TEST
----
[[
    -2
]]
    ( -2 )

TEST
----
[[
    3.14
]]
    ( 3.14 )

TEST
----
[[
    -4.50
]]
    ( -4.50 )

TEST
----
[[
    "foo"
]]
    ( "foo" )

TEST
----
[[
    "foo bar"
]]
    ( "foo bar" )

TEST
----
[[
    "tiny.lua"
]]
    ( "tiny.lua" )

TEST
----
[[
    true
]]
    ( true )

TEST
----
[[
    false
]]
    ( false )

TEST
----
[[
    1 + 2
]]
    ( 3 )

TEST
----
[[
    1 - 2
]]
    ( -1 )

TEST
----
[[
    1 * 2
]]
    ( 2 )

TEST
----
[[
    1 / 2
]]
    ( 0.5 )

TEST
----
[[
    1 + 2 + 3
]]
    ( 6 )

TEST
----
[[
    1 + 2 - 3
]]
    ( 0 )

TEST
----
[[
    1 + 2 * 3
]]
    ( 7 )

TEST
----
[[
    (1 + 2) * 3
]]
    ( 9 )

TEST
----
[[
    (1 + 2) / 3
]]
    ( 1 )

TEST
----
[[
    1 + 2 * 3 + 4
]]
    ( 11 )

TEST
----
[[
    (1 + 2) * (3 + 4)
]]
    ( 21 )

TEST
----
[[
    (1 + 2) * (-3 + 4)
]]
    ( 3 )

TEST
----
[[
    -(-1)
]]
    ( 1 )

TEST
----
[[
    -(-(-1) + 2)
]]
    ( -3 )
TEST
----
[[
    -(-(-1) -(-1))
]]
    ( -2 )

TEST
----
[[
    -1 * -2 * -3 / -3
]]
    ( 2 )

TEST
----
[[
    -1 * -(2 * -3) / -3
]]
    ( 2 )

TEST
----
[[
    1 == 1
]]
    ( true )

TEST
----
[[
    2 != 3
]]
    ( true )

TEST
----
[[
    1 + 2 >= 2 + 3
]]
    ( false )

TEST
----
[[
    2 + 3 <= 1 + 2
]]
    ( false )

TEST
----
[[
    "foo" > "bar"
]]
    ( true )

TEST
----
[[
    "foo" < "bar"
]]
    ( false )

TEST
----
[[
    "true" != "false"
]]
    ( true )

TEST
----
[[
    a
]]
    ( nil )

TEST
----
[[
    a = 1
]]
    ( 1 )

TEST
----
[[
    b = 2
]]
    ( 2 )

TEST
----
[[
    ab = a + b
]]
    ( 3 )

TEST
----
[[
    ab = ab * 2
]]
    ( 6 )

TEST
----
[[
    c = ab > 2 * (b + 1)
]]
    ( false )

TEST
----
[[
    c = "lua" != "tiny"
]]
    ( true )

TEST
----
[[
    d = -(-a * 2) / -b > a
]]
    ( false )

TEST
----
[[
    d = -ab / 2 * -1 * b > 0
]]
    ( true )

TEST
----
[[
    1 and 2
]]
    ( 2 )

TEST
----
[[
    1 and 2 or 3
]]
    ( 2 )

TEST
----
[[
    "foo" or "bar"
]]
    ( "foo" )

TEST
----
[[
    true and false
]]
    ( false )

TEST
----
[[
    true or false
]]
    ( true )

TEST
----
[[
    not true
]]
    ( false )

TEST
----
[[
    not false
]]
    ( true )

TEST
----
[[
    not (not false)
]]
    ( false )

TEST
----
[[
    not (not true)
]]
    ( true )

TEST
----
[[
    not "foo" or not 1
]]
    ( false )

TEST
----
[[
    1+2 > 3-4 and 5 < 6
]]
    ( true )

TEST
----
[[
    1+2 > 3 or (4 and 5)
]]
    ( 5 )

TEST
----
[[
    e = (e or 0) + 1
]]
    ( 1 )

TEST
----
[[
    e = (e or 0) + 1
]]
    ( 2 )

TEST
----
[[
    e = (e or 0) + 1
]]
    ( 3 )

TEST
----
[[
    e = (e >= 3) and 4
]]
    ( 4 )

TEST
----
[[
    e = not 4 or e+1
]]
    ( 5 )

TEST
----
[[
    a = 1
]]
    ( 1 )

TEST
----
[[
    b = 2
]]
    ( 2 )

TEST
----
[[
    if a > 0 then true end
]]
    ( true )

TEST
----
[[
    if a < 0 then true end
]]
    ( nil )

TEST
----
[[
    if a > 0 then true else false end
]]
    ( true )

TEST
----
[[
    if a < 0 then true else false end
]]
    ( false )

TEST
----
[[
    if a > 0 then x = 1 end
]]
    ( 1 )

TEST
----
[[
    if a < 0 then x = 1 else x = 2 end
]]
    ( 2 )

TEST
----
[[
    if not x then a = 3 end
]]
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
    ( 6 )

TEST
----
[[
    if a == 3 then a = a + 1
    elseif a == 4 then a = a + 2
    elseif a == 5 then a = a + 3
    else a = 10 end
]]
    ( 10 )

TEST
----
[[
    if false then 1
    elseif false then 2
    elseif false then 3 end
]]
    ( nil )

TEST
----
[[
    while a > 1 do a = a - 1 end
]]
    ( nil )

TEST
----
[[
    while b < 10 do b = b + a end
]]
    ( nil )

TEST
----
[[
    while a != b - 1 do b = b - 1 end
]]
    ( nil )

TEST
----
[[
    while a == b + 1 do b = false end
]]
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
    ( nil )

TEST
----
[[
    a
]]
    ( 9 )

TEST
----
[[
    b
]]
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
    ( nil )

TEST
----
[[
    a
]]
    ( 1 )

TEST
----
[[
    b
]]
    ( 2 )

TEST
----
[[
    for i = 1, 1 do a = a + i end
]]
    ( nil )

TEST
----
[[
    for i = 1, 2 do a = a - i end
]]
    ( nil )

TEST
----
[[
    for i = 1, 3 do a = a + i end
]]
    ( nil )

TEST
----
[[
    for i = -1, -4 do a = a - i end
]]
    ( nil )

TEST
----
[[
    for i = -1, +4 do a = a + i end
]]
    ( nil )

TEST
----
[[
    a = a - 13
]]
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
    ( false )

TEST
----
[[
    x
]]
    ( nil )

TEST
----
[[
    y
]]
    ( nil )

TEST
----
[[
    f = function ()
        a = a + 1
    end f()
]]
    ( 2 )

TEST
----
[[
    a
]]
    ( 2 )

TEST
----
[[
    b
]]
    ( 2 )

TEST
----
[[
    c
]]
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
    ( 6 )

TEST
----
[[
    a
]]
    ( 2 )

TEST
----
[[
    b
]]
    ( 2 )

TEST
----
[[
    c
]]
    ( true )

TEST
----
[[
    f = function (a, b, c)
        c = c or 3
        a + b + c
    end f(1, 2, 3)
]]
    ( 6 )

TEST
----
[[
    a
]]
    ( 2 )

TEST
----
[[
    b
]]
    ( 2 )

TEST
----
[[
    c
]]
    ( true )

TEST
----
[[
    f(1, 2)
]]
    ( 6 )

TEST
----
[[
    a
]]
    ( 2 )

TEST
----
[[
    b
]]
    ( 2 )

TEST
----
[[
    c
]]
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
    ( 12 )

--=============--
  TEST_REPORT()
--=============--
