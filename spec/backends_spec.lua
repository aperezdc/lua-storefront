#! /usr/bin/env lua
--
-- backends_spec.lua
-- Copyright (C) 2016 Adrian Perez <aperez@igalia.com>
--
-- Distributed under terms of the MIT license.
--

local storetest = require "spec.storetest"
local path = require "storefront.path"
local inmem = require "storefront.backend.inmem"

describe("storefront.backend.inmem", function ()
   it("has basic store methods", function ()
      storetest.test_store_methods(inmem, true)
      storetest.test_store_methods(inmem())
   end)

   it("stores and retrieves data", function ()
      storetest.test_set_get(inmem(), path "foo.bar")
   end)

   it("deletes items", function ()
      local s = inmem()
      s:set(path "foo", "foo value")
      storetest.test_del(inmem(), path "foo.bar")
      assert.equal("foo value", s:get(path "foo"))
   end)
end)
