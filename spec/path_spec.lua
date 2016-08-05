#! /usr/bin/env lua
--
-- path_spec.lua
-- Copyright (C) 2016 Adrian Perez <aperez@igalia.com>
--
-- Distributed under terms of the MIT license.
--

local P = require "storefront.path"

describe("storefront.path", function ()
   it("can be instantiated with valid path strings", function ()
      for _, path_string in ipairs {
            "a", "a/b", "a/b/c",
            "a/b.c_d", "a/_b/c", "a/_b_/c", "a/b_/c",
            "a1", "0", "foo/n", "foo/1",
         } do
         assert.message(string.format("input: %q", path_string))
            .not_has_error(function () P(path_string) end)
      end
   end)

   it("can be instantiated using tables", function ()
      for _, path_table in ipairs {
         { "a" }, { "a", "b" }, { "a", "b", "c_d" }
      } do
         assert.message("input: " .. table.concat(path_table, ", "))
            .not_has_error(function () P(path_table) end)
      end
   end)

   it("errors on invalid path strings", function ()
      for _, path_string in ipairs {
         "",       -- empty string
         "a:b",    -- invalid component separator
         "a b c",  -- spaces
         ".n",     -- leading period
         "a/.n",
      } do
         assert.message(string.format("input: %q", path_string))
            .has_error(function () P(path_string) end)
      end
   end)

   it("errors on invalid path tables", function ()
      for _, path_table in ipairs {
         { },           -- no components
         { "" },        -- empty component
         { "a", "" },   -- ditto
         { "", "a" },   -- ditto
         { " foo"  },   -- space in component
         { "a", "." },  -- period in component
      } do
         assert.message("input: [" .. table.concat(path_table, "/") .. "]")
            .has_error(function () P(path_table) end)
      end
   end)

   it("properly converts with tostring()", function ()
      local items = {
         ["a/b/c/d"] = {
            P { "a", "b", "c", "d" },
            P "a/b/c/d",
         },
         ["foobar"] = {
            P { "foobar" },
            P "foobar",
         },
         ["a_b/c_d"] = {
            P { "a_b", "c_d" },
            P "a_b/c_d",
         },
      }
      for expected, paths in pairs(items) do
         for _, path in ipairs(paths) do
            assert.message("path <" .. table.concat(path, "/") .. ">")
               .equal(expected, path.string)
            assert.message("path <" .. table.concat(path, "/") .. ">")
               .equal(expected, tostring(path))
         end
      end
   end)

   it("can be compared", function ()
      assert.equal(P { "a","b" }, P { "a", "b" })
      assert.equal(P "a.b.c.d", P "a.b.c.d")
      assert.equal(P { "a", "b" }, P "a/b")
      assert.equal(P "a/b", P { "a", "b" })
      assert.not_equal(P "a/b", P "c/d")
   end)

   it("can be concatenated to other paths", function ()
      local foo = P "foo"
      local bar = P "bar"
      local foobar = foo .. bar
      assert.equal(P, getmetatable(foobar))
      assert.equal(P "foo/bar", foobar)
      local foobarbaz = foo .. P "bar/baz"
      assert.equal(P "foo/bar/baz", foobarbaz)
   end)

   it("can be concatenated to strings", function ()
      local foo = P "foo"
      local foobar = foo .. "bar"
      assert.equal(P, getmetatable(foobar))
      assert.equal(P "foo/bar", foobar)
      local foobarbaz = foo .. "bar/baz"
      assert.equal(P "foo/bar/baz", foobarbaz)
   end)

   it("can be concatenated to tables", function ()
      local foo = P "foo"
      local foobar = foo .. { "bar" }
      assert.equal(P, getmetatable(foobar))
      assert.equal(P "foo/bar", foobar)
      local foobarbaz = foo .. { "bar", "baz" }
      assert.equal(P "foo/bar/baz", foobarbaz)
   end)

   it("can be concatenated to stringizable values", function ()
      local foo = P "foo"
      local foo1 = foo .. 1
      assert.equal(P, getmetatable(foo1))
      assert.equal(P "foo/1", foo1)
   end)

   it("cannot be mutated", function ()
      assert.has_error(function ()
         local foo = P "foo"
         foo[#foo+1] = "bar"
      end)
      assert.has_error(function ()
         local foo = P "foo"
         foo.random_attribute = true
      end)
   end)

   describe(":child()", function ()
      it("creates new child paths", function ()
         local foo = P "foo"
         local foobar = foo:child "bar"
         assert.not_same(foo, foobar)
         assert.equal(foobar, P "foo/bar")
         assert.equal(foobar, P {"foo", "bar"})
         assert.equal(P, getmetatable(foobar))
      end)

      it("can be chained", function ()
         local foo = P "foo"

         local foobar = foo:child "bar"
         assert.not_same(foo, foobar)
         assert.equal(P, getmetatable(foobar))
         assert.equal(P "foo/bar", foobar)

         local foobarbaz = foobar:child "baz"
         assert.not_same(foobar, foobarbaz)
         assert.equal(P, getmetatable(foobarbaz))

         assert.equal(P "foo/bar/baz", foobarbaz)
      end)
   end)

   describe(":parent()", function ()
      it("creates new parent paths", function ()
         local foobar = P "foo/bar"
         local foo = foobar:parent()
         assert.not_same(foobar, foo)
         assert.equal(foo, P "foo")
      end)

      it("can be chained", function ()
         local foobarbaz = P "foo/bar/baz"
         local foobar = foobarbaz:parent()
         assert.not_same(foobarbaz, foobar)
         assert.equal(P "foo/bar", foobar)
         assert.equal(P, getmetatable(foobar))

         local foo = foobar:parent()
         assert.not_same(foobar, foo)
         assert.equal(P "foo", foo)
         assert.equal(P, getmetatable(foo))
      end)
   end)

   describe(":sibling()", function ()
      it("creates new sibling paths", function ()
         local foobar = P "foo/bar"
         local foobaz = foobar:sibling "baz"
         assert.not_same(foobar, foobaz)
         assert.equal(P "foo/baz", foobaz)
      end)

      it("can be chained", function ()
         local foobar = P "foo/bar"
         local foobaz = foobar:sibling "baz"
         local foofoo = foobar:sibling "foo"
         assert.equal(P "foo/baz", foobaz)
         assert.equal(P "foo/foo", foofoo)
      end)
   end)
end)

