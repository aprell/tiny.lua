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
{ "number", 1 }
( 1 )

TEST
----
[[
    -2
]]
{ "unary", "-",
  { "number", 2 }
}
( -2 )

TEST
----
[[
    3.14
]]
{ "number", 3.14 }
( 3.14 )

TEST
----
[[
    -4.50
]]
{ "unary", "-",
  { "number", 4.50 }
}
( -4.50 )

TEST
----
[[
    "foo"
]]
{ "string", "foo" }
( "foo" )

TEST
----
[[
    "foo bar"
]]
{ "string", "foo bar" }
( "foo bar" )

TEST
----
[[
    "tiny.lua"
]]
{ "string", "tiny.lua" }
( "tiny.lua" )

TEST
----
[[
    true
]]
{ "boolean", true }
( true )

TEST
----
[[
    false
]]
{ "boolean", false }
( false )

TEST
----
[[
    1 + 2
]]
{ "sum",
  { "number", 1 }, "+",
  { "number", 2 }
}
( 3 )

TEST
----
[[
    1 - 2
]]
{ "sum",
  { "number", 1 }, "-",
  { "number", 2 }
}
( -1 )

TEST
----
[[
    1 * 2
]]
{ "product",
  { "number", 1 }, "*",
  { "number", 2 }
}
( 2 )

TEST
----
[[
    1 / 2
]]
{ "product",
  { "number", 1 }, "/",
  { "number", 2 }
}
( 0.5 )

TEST
----
[[
    1 + 2 + 3
]]
{ "sum",
  { "number", 1 }, "+",
  { "number", 2 }, "+",
  { "number", 3 }
}
( 6 )

TEST
----
[[
    1 + 2 - 3
]]
{ "sum",
  { "number", 1 }, "+",
  { "number", 2 }, "-",
  { "number", 3 }
}
( 0 )

TEST
----
[[
    1 + 2 * 3
]]
{ "sum",
  { "number", 1 }, "+",
  { "product",
    { "number", 2 }, "*",
    { "number", 3 }
  }
}
( 7 )

TEST
----
[[
    (1 + 2) * 3
]]
{ "product",
  { "sum",
    { "number", 1 }, "+",
    { "number", 2 }
  }, "*",
  { "number", 3 }
}
( 9 )

TEST
----
[[
    (1 + 2) / 3
]]
{ "product",
  { "sum",
    { "number", 1 }, "+",
    { "number", 2 }
  }, "/",
  { "number", 3 }
}
( 1 )

TEST
----
[[
    1 + 2 * 3 + 4
]]
{ "sum",
  { "number", 1 }, "+",
  { "product",
    { "number", 2 }, "*",
    { "number", 3 }
  }, "+",
  { "number", 4 }
}
( 11 )

TEST
----
[[
    (1 + 2) * (3 + 4)
]]
{ "product",
  { "sum",
    { "number", 1 }, "+",
    { "number", 2 }
  }, "*",
  { "sum",
    { "number", 3 }, "+",
    { "number", 4 }
  }
}
( 21 )

TEST
----
[[
    (1 + 2) * (-3 + 4)
]]
{ "product",
  { "sum",
    { "number", 1 }, "+",
    { "number", 2 }
  }, "*",
  { "sum",
    { "unary", "-",
      { "number", 3 }
    }, "+",
    { "number", 4 }
  }
}
( 3 )

TEST
----
[[
    -(-1)
]]
{ "unary", "-",
  { "unary", "-",
    { "number", 1 }
  }
}
( 1 )

TEST
----
[[
    -(-(-1) + 2)
]]
{ "unary", "-",
  { "sum",
    { "unary", "-",
      { "unary", "-",
        { "number", 1 }
      }
    }, "+",
    { "number", 2 }
  }
}
( -3 )

TEST
----
[[
    -(-(-1) -(-1))
]]
{ "unary", "-",
  { "sum",
    { "unary", "-",
      { "unary", "-",
        { "number", 1 }
      }
    }, "-",
    { "unary", "-",
      { "number", 1 }
    }
  }
}
( -2 )

TEST
----
[[
    -1 * -2 * -3 / -3
]]
{ "product",
  { "unary", "-",
    { "number", 1 }
  }, "*",
  { "unary", "-",
    { "number", 2 }
  }, "*",
  { "unary", "-",
    { "number", 3 }
  }, "/",
  { "unary", "-",
    { "number", 3 }
  }
}
( 2 )

TEST
----
[[
    -1 * -(2 * -3) / -3
]]
{ "product",
  { "unary", "-",
    { "number", 1 }
  }, "*",
  { "unary", "-",
    { "product",
      { "number", 2 }, "*",
      { "unary", "-",
        { "number", 3 }
      }
    }
  }, "/",
  { "unary", "-",
    { "number", 3 }
  }
}
( 2 )

TEST
----
[[
    1 == 1
]]
{ "comparison",
  { "number", 1 }, "==",
  { "number", 1 }
}
( true )

TEST
----
[[
    2 != 3
]]
{ "comparison",
  { "number", 2 }, "!=",
  { "number", 3 }
}
( true )

TEST
----
[[
    1 + 2 >= 2 + 3
]]
{ "comparison",
  { "sum",
    { "number", 1 }, "+",
    { "number", 2 }
  }, ">=",
  { "sum",
    { "number", 2 }, "+",
    { "number", 3 }
  }
}
( false )

TEST
----
[[
    2 + 3 <= 1 + 2
]]
{ "comparison",
  { "sum",
    { "number", 2 }, "+",
    { "number", 3 }
  }, "<=",
  { "sum",
    { "number", 1 }, "+",
    { "number", 2 }
  }
}
( false )

TEST
----
[[
    "foo" > "bar"
]]
{ "comparison",
  { "string", "foo" }, ">",
  { "string", "bar" }
}
( true )

TEST
----
[[
    "foo" < "bar"
]]
{ "comparison",
  { "string", "foo" }, "<",
  { "string", "bar" }
}
( false )

TEST
----
[[
    "true" != "false"
]]
{ "comparison",
  { "string", "true" }, "!=",
  { "string", "false" }
}
( true )

TEST
----
[[
    a
]]
{ "variable", "a" }
( nil )

TEST
----
[[
    a = 1
]]
{ "block",
  { "assignment",
    { "variable", "a" },
    { "number", 1 }
  }
}
( 1 )

TEST
----
[[
    b = 2
]]
{ "block",
  { "assignment",
    { "variable", "b" },
    { "number", 2 }
  }
}
( 2 )

TEST
----
[[
    ab = a + b
]]
{ "block",
  { "assignment",
    { "variable", "ab" },
	{ "sum",
      { "variable", "a" }, "+",
      { "variable", "b" }
    }
  }
}
( 3 )

TEST
----
[[
    ab = ab * 2
]]
{ "block",
  { "assignment",
    { "variable", "ab" },
	{ "product",
      { "variable", "ab" }, "*",
      { "number", 2 }
    }
  }
}
( 6 )

TEST
----
[[
    c = ab > 2 * (b + 1)
]]
{ "block",
  { "assignment",
    { "variable", "c" },
    { "comparison",
      { "variable", "ab" }, ">",
      { "product",
        { "number", 2 }, "*",
        { "sum",
          { "variable", "b" }, "+",
          { "number", 1 }
        }
      }
    }
  }
}
( false )

TEST
----
[[
    c = "lua" != "tiny"
]]
{ "block",
  { "assignment",
    { "variable", "c" },
    { "comparison",
      { "string", "lua" }, "!=",
      { "string", "tiny" }
    }
  }
}
( true )

TEST
----
[[
    d = -(-a * 2) / -b > a
]]
{ "block",
  { "assignment",
    { "variable", "d" },
    { "comparison",
      { "product",
        { "unary", "-",
          { "product",
            { "unary", "-",
              { "variable", "a" },
            }, "*",
            { "number", 2 }
          }
        }, "/",
        { "unary", "-",
          { "variable", "b" }
        }
      }, ">",
      { "variable", "a" }
    }
  }
}
( false )

TEST
----
[[
    d = -ab / 2 * -1 * b > 0
]]
{ "block",
  { "assignment",
    { "variable", "d" },
    { "comparison",
      { "product",
        { "unary", "-",
          { "variable", "ab" }
        }, "/",
        { "number", 2 }, "*",
        { "unary", "-",
          { "number", 1 }
        }, "*",
        { "variable", "b" }
      }, ">",
      { "number", 0 }
    }
  }
}
( true )

TEST
----
[[
    1 and 2
]]
{ "conjunction",
  { "number", 1 }, "and",
  { "number", 2 }
}
( 2 )

TEST
----
[[
    1 and 2 or 3
]]
{ "disjunction",
  { "conjunction",
    { "number", 1 }, "and",
    { "number", 2 }
  }, "or",
  { "number", 3 }
}
( 2 )

TEST
----
[[
    "foo" or "bar"
]]
{ "disjunction",
  { "string", "foo" }, "or",
  { "string", "bar" }
}
( "foo" )

TEST
----
[[
    true and false
]]
{ "conjunction",
  { "boolean", true }, "and",
  { "boolean", false }
}
( false )

TEST
----
[[
    true or false
]]
{ "disjunction",
  { "boolean", true }, "or",
  { "boolean", false }
}
( true )

TEST
----
[[
    not true
]]
{ "unary", "not",
  { "boolean", true }
}
( false )

TEST
----
[[
    not false
]]
{ "unary", "not",
  { "boolean", false }
}
( true )

TEST
----
[[
    not (not false)
]]
{ "unary", "not",
  { "unary", "not",
    { "boolean", false }
  }
}
( false )

TEST
----
[[
    not (not true)
]]
{ "unary", "not",
  { "unary", "not",
    { "boolean", true }
  }
}
( true )

TEST
----
[[
    not "foo" or not 1
]]
{ "disjunction",
  { "unary", "not",
    { "string", "foo" }
  }, "or",
  { "unary", "not",
    { "number", 1 }
  }
}
( false )

TEST
----
[[
    1+2 > 3-4 and 5 < 6
]]
{ "conjunction",
  { "comparison",
    { "sum",
      { "number", 1 }, "+",
      { "number", 2 }
    }, ">",
    { "sum",
      { "number", 3 }, "-",
      { "number", 4 }
    }
  }, "and",
  { "comparison",
    { "number", 5 }, "<",
    { "number", 6 }
  }
}
( true )

TEST
----
[[
    1+2 > 3 or (4 and 5)
]]
{ "disjunction",
  { "comparison",
    { "sum",
      { "number", 1 }, "+",
      { "number", 2 }
    }, ">",
    { "number", 3 }
  }, "or",
  { "conjunction",
    { "number", 4 }, "and",
    { "number", 5 }
  }
}
( 5 )

TEST
----
[[
    e = (e or 0) + 1
]]
{ "block",
  { "assignment",
    { "variable", "e" },
    { "sum",
      { "disjunction",
        { "variable", "e" }, "or",
        { "number", 0 }
      }, "+",
      { "number", 1 }
    }
  }
}
( 1 )

TEST
----
[[
    e = (e or 0) + 1
]]
{ "block",
  { "assignment",
    { "variable", "e" },
    { "sum",
      { "disjunction",
        { "variable", "e" }, "or",
        { "number", 0 }
      }, "+",
      { "number", 1 }
    }
  }
}
( 2 )

TEST
----
[[
    e = (e or 0) + 1
]]
{ "block",
  { "assignment",
    { "variable", "e" },
    { "sum",
      { "disjunction",
        { "variable", "e" }, "or",
        { "number", 0 }
      }, "+",
      { "number", 1 }
    }
  }
}
( 3 )

TEST
----
[[
    e = (e >= 3) and 4
]]
{ "block",
  { "assignment",
    { "variable", "e" },
    { "conjunction",
      { "comparison",
        { "variable", "e" }, ">=",
        { "number", 3 }
      }, "and",
      { "number", 4 }
    }
  }
}
( 4 )

TEST
----
[[
    e = not 4 or e+1
]]
{ "block",
  { "assignment",
    { "variable", "e" },
    { "disjunction",
      { "unary", "not",
        { "number", 4 }
      }, "or",
      { "sum",
        { "variable", "e" }, "+",
        { "number", 1 }
      }
    }
  }
}
( 5 )

TEST
----
[[
    a = 1
    b = 2
]]
{ "block",
  { "assignment",
    { "variable", "a" },
    { "number", 1 }
  },
  { "assignment",
    { "variable", "b" },
    { "number", 2 }
  }
}
( 2 )

TEST
----
[[
    if a > 0 then true end
]]
{ "block",
  { "if",
    { "comparison",
      { "variable", "a" }, ">",
      { "number", 0 }
    }, "then",
    { "boolean", true },
    "end"
  }
}
( true )

TEST
----
[[
    if a < 0 then true end
]]
{ "block",
  { "if",
    { "comparison",
      { "variable", "a" }, "<",
      { "number", 0 }
    }, "then",
    { "boolean", true },
    "end"
  }
}
( nil )

TEST
----
[[
    if a > 0 then true else false end
]]
{ "block",
  { "if",
    { "comparison",
      { "variable", "a" }, ">",
      { "number", 0 }
    }, "then",
    { "boolean", true },
    "else",
    { "boolean", false },
    "end"
  }
}
( true )

TEST
----
[[
    if a < 0 then true else false end
]]
{ "block",
  { "if",
    { "comparison",
      { "variable", "a" }, "<",
      { "number", 0 }
    }, "then",
    { "boolean", true },
    "else",
    { "boolean", false },
    "end"
  }
}
( false )

TEST
----
[[
    if a > 0 then x = 1 end
]]
{ "block",
  { "if",
    { "comparison",
      { "variable", "a" }, ">",
      { "number", 0 }
    }, "then",
    { "block",
      { "assignment",
        { "variable", "x" },
        { "number", 1 }
      }
    }, "end"
  }
}
( 1 )

TEST
----
[[
    if a < 0 then x = 1 else x = 2 end
]]
{ "block",
  { "if",
    { "comparison",
      { "variable", "a" }, "<",
      { "number", 0 }
    }, "then",
    { "block",
      { "assignment",
        { "variable", "x" },
        { "number", 1 }
      }
    }, "else",
    { "block",
      { "assignment",
        { "variable", "x" },
        { "number", 2 }
      }
    }, "end"
  }
}
( 2 )

TEST
----
[[
    if not x then a = 3 end
]]
{ "block",
  { "if",
    { "unary", "not",
      { "variable", "x" }
    }, "then",
    { "block",
      { "assignment",
        { "variable", "a" },
        { "number", 3 }
      }
    }, "end"
  }
}
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
{ "block",
  { "if",
    { "comparison",
      { "variable", "a" }, "==",
      { "number", 1 }
    }, "then",
    { "block",
      { "assignment",
        { "variable", "a" },
        { "sum",
          { "variable", "a" }, "+",
          { "number", 1 }
        }
      }
    }, "else",
    { "block",
      { "if",
        { "comparison",
          { "variable", "a" }, "==",
          { "number", 2 }
        }, "then",
        { "block",
          { "assignment",
            { "variable", "a" },
            { "sum",
              { "variable", "a" }, "+",
              { "number", 2 }
            }
          }
        }, "else",
        { "block",
          { "if",
            { "comparison",
              { "variable", "a" }, "==",
              { "number", 3 }
            }, "then",
            { "block",
              { "assignment",
                { "variable", "a" },
                { "sum",
                  { "variable", "a" }, "+",
                  { "number", 3 }
                }
              }
            }, "else",
            { "block",
              { "assignment",
                { "variable", "a" },
                { "number", 10 }
              }
            }, "end"
          }
        }, "end"
      }
    }, "end"
  }
}
( 6 )

TEST
----
[[
    if a == 3 then a = a + 1
    elseif a == 4 then a = a + 2
    elseif a == 5 then a = a + 3
    else a = 10 end
]]
{ "block",
  { "if",
    { "comparison",
      { "variable", "a" }, "==",
      { "number", 3 }
    }, "then",
    { "block",
      { "assignment",
        { "variable", "a" },
        { "sum",
          { "variable", "a" }, "+",
          { "number", 1 }
        }
      }
    }, "elseif",
    { "comparison",
      { "variable", "a" }, "==",
      { "number", 4 }
    }, "then",
    { "block",
      { "assignment",
        { "variable", "a" },
        { "sum",
          { "variable", "a" }, "+",
          { "number", 2 }
        }
      }
    }, "elseif",
    { "comparison",
      { "variable", "a" }, "==",
      { "number", 5 }
    }, "then",
    { "block",
      { "assignment",
        { "variable", "a" },
        { "sum",
          { "variable", "a" }, "+",
          { "number", 3 }
        }
      }
    }, "else",
    { "block",
      { "assignment",
        { "variable", "a" },
        { "number", 10 }
      }
    }, "end"
  }
}
( 10 )

TEST
----
[[
    if false then 1
    elseif false then 2
    elseif false then 3 end
]]
{ "block",
  { "if",
    { "boolean", false },
    "then",
    { "number", 1 },
    "elseif",
    { "boolean", false },
    "then",
    { "number", 2 },
    "elseif",
    { "boolean", false },
    "then",
    { "number", 3 },
    "end"
  }
}
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
        return a + b + c
    end
    f()
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
        return a + b + c
    end
    f(1, 2, 3)
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
            return a + b
        end
    end
    a = f(); a()
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
            return a + b
        end
    end
    a = f(); a()
]]
( pass )
( 12 )

--------------
check.report()
--------------
