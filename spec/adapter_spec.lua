#! /usr/bin/env lua
--
-- adapter_spec.lua
-- Copyright (C) 2016 Adrian Perez <aperez@igalia.com>
--
-- Distributed under terms of the MIT license.
--

local storetest = require "spec.storetest"
local inmem = require "storefront.backend.inmem"
local lrucache = require "storefront.adapter.lrucache"
local P = require "storefront.path"

describe("storefront.adapter.lrucache", function ()
   it("has basic store methods", function ()
      storetest.test_store_methods(lrucache, true)
      storetest.test_store_methods(lrucache(inmem(), 10))
   end)

   it("stores and retrieves data", function ()
      storetest.test_set_get(lrucache(inmem(), 10), P"foo/bar")
   end)

   it("deletes items", function ()
      local s = lrucache(inmem(), 10)
      s:set(P"foo", "foo value")
      storetest.test_del(s, P"foo/bar")
      assert.equal("foo value", s:get(P"foo"))
   end)
end)

