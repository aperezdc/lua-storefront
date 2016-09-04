#! /usr/bin/env lua
--
-- storetest.lua
-- Copyright (C) 2016 Adrian Perez <aperez@igalia.com>
--
-- Distributed under terms of the MIT license.
--

local assert = require "luassert"
local P = require "storefront.path"

local function test_store_methods(s, nocall)
   assert.is_function(s.begin_transaction)
   assert.is_function(s.end_transaction)
   assert.is_function(s.transact)
   assert.is_function(s.get)
   assert.is_function(s.set)
   assert.is_function(s.del)
   assert.is_function(s.has)
   if not nocall then
      s:get(P"foo")
      s:set(P"foo", "42")
      s:del(P"foo", "42")
      s:has(P"foo")
      s:query("*")
   end
end

return test_store_methods
